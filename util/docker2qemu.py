#!/usr/bin/env python

import argparse
import datetime
import os
import platform
import re
import subprocess
import sys
import tarfile
import time
import urllib.request

boot_tar = "https://storage.googleapis.com/go-builder-data/boot-linux-3.16-0.bpo.3-amd64.tar.gz"
boot_uuid = "906181f7-4e10-4a4e-8fd8-43b20ec980ff"
nbd_device = "/dev/nbd0"

script_name = sys.argv[0]


def main():
    arg_parser = argparse.ArgumentParser(description="Convert Docker image to qcow")
    arg_parser.add_argument(
        "--image", "-i",
        help="Docker image ")
    arg_parser.add_argument(
        "--rawfile", "-f",
        help="RAW file")
    arg_parser.add_argument(
        "--size", "-s",
        help="RAW file size in gigabytes")
    arg_parser.add_argument(
        "--device", "-d",
        nargs='?',
        type=str,
        default=nbd_device,
        help="Device driver")
    arg_parser.add_argument(
        "--kernel", "-k",
        nargs="?",
        type=str,
        default=boot_tar,
        help="Linker template file")

    args = arg_parser.parse_args()
    image = args.image
    kernel = args.kernel
    device = args.device
    disk = args.rawfile
    size = args.size

    print(datetime.datetime.now())
    print(f"{script_name}", sys.argv[1:])


    ###############
    ###############


def check_platform():
    if not platform.system() == "Linux":
        fail(f"{script_name} works only on Linux")


def check_root():
    if not os.geteuid() == 0:
        fail(f"{script_name} requires root privilege")


def check_deps(*args):
    missing_deps = []
    for dep in args:
        if subprocess.call(["which", dep], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL):
            missing_deps.append(dep)

    if missing_deps:
        print("Missing dependencies:", ", ".join(missing_deps))
        sys.exit(1)


def cmd(action, cmd_arg, *args, **kwargs):
    if isinstance(cmd_arg, str) and not kwargs.get("shell", False):
        cmd_arg = cmd_arg.split()
    allow_failure = kwargs.pop("allow_failure", False)
    retries = kwargs.pop("retries", 0)

    print("\n", "[::::: " + action.upper() + " :::::]\n", cmd_arg, "\n")

    try:
        output = subprocess.check_output(cmd_arg, *args, stderr=subprocess.STDOUT, **kwargs)
        print_output(output)
    except subprocess.CalledProcessError as e:
        print_output(e.output)

        if retries > 0:
            kwargs["retries"] = retries - 1
            kwargs["allow_failure"] = allow_failure
            retries = retries - 1
            print(f"Retrying... {retries} remaining retries")
            time.sleep(4. / (retries + 1))
            return cmd(action, cmd_arg, *args, **kwargs)

        if allow_failure:
            return

        fail("")


def cmd_out(cmd_run, *args, **kwargs):
    if isinstance(cmd, str):
        cmd_run = cmd.split()
    return subprocess.check_output(cmd_run, *args, stderr=subprocess.STDOUT, **kwargs)


def print_output(output):
    if output is None or len(output) == 0:
        return
    print(output.decode())


def fail(msg):
    print(msg)
    sys.exit(1)


def mkdir(path, create_parents=True):
    if create_parents:
        os.makedirs(path)
    else:
        os.mkdir(path)
    return path


def regex_replace(path, pattern, replacement):
    updated = []
    with open(path, "r") as f:
        for line in f:
            updated.append(re.sub(pattern, replacement, line))

    with open(path, "w") as f:
        for line in updated:
            f.write(line)


def extract_boot_tar(url, out_dir):
    full_filename = os.path.join(".", "boot.gz")
    urllib.request.urlretrieve(url, full_filename)
    tar = tarfile.open(full_filename)
    tar.extractall(out_dir)
    os.remove(full_filename)


def export_image_contents(container, image, out_dir):
    tar_file = os.path.join(".", image)
    cmd("Export docker container contents",
        ["docker", "export", container, "--output=" + tar_file])
    tar = tarfile.open(tar_file)
    tar.extractall(out_dir)
    os.remove(tar_file)


def get_fs_uuid(mount_point):
    """
    get_fs_uuid parses s
    :param mount_point:
    :return: fs_uuid
    """
    fs_uuid = cmd_out(["/sbin/blkid", mount_point])
    fs_uuid = fs_uuid.split(b"=")[1]
    fs_uuid = fs_uuid.decode()
    fs_uuid = re.findall(r'"(.*?)"', fs_uuid)
    fs_uuid = ''.join(fs_uuid)
    print(f"Parsed FS UUID from {mount_point}: {fs_uuid}")
    return fs_uuid


def format_disk(device):
    cmd(f"Create partition table on the {device}",
        ["/sbin/sgdisk",
         "--new", "1:0:+2MiB",
         "--typecode=" + "1:ef02",
         "--change-name=" + "1:boot",
         "--new", "2:0:+4MiB",
         "--typecode=" + "2:8300",
         "--change-name=" + "2:linux-boot",
         "--new", "3:0:+128MiB",
         "--typecode=" + "3:8300",
         "--change-name=" + "3:swap",
         "--new", "4:0:+0",
         "--typecode=" + "4:8300",
         "--change-name=" + "4:root",
         "--print", device, "--mbrtogpt"])

    cmd("Inform the operating system about partition table changes",
        ["partprobe", "--summary", device])

    ###############
    ###############


    check_platform()

    check_root()

    check_deps("docker", "/bin/fallocate", "/bin/qemu-nbd", "/sbin/sgdisk", "/sbin/mkfs.ext4")

    if cmd("Install kernel network block device driver",
           ["modprobe", "--verbose", "nbd", "max_part=63"]):
        fail("Ensure the kernels network block device driver is installed")

    with open("/proc/partitions") as f:
        if "nbd0" in f.read():
            fail(f"Looks like {device} is already in use. "
                 f"Try sudo qemu-nbd -d {device}")

    if os.path.exists(disk):
        fail(f"File {disk} already exists. "
             "Delete it and try again, or use a different --disk flag value")

    cmd("Allocate empty file",
        ["/bin/fallocate", "--length", size + "G", disk])

    cmd("Start a NBD server",
        ["/bin/qemu-nbd", "--connect=" + device, "--format=raw", disk])

    format_disk(device)

    mount_point = device + "p4"

    cmd("Make filesystem on partition",
        ["/sbin/mkfs.ext4", mount_point])

    mnt_dir = mkdir("docker2oci", create_parents=True)

    cmd("Mount partition",
        ["mount", mount_point, mnt_dir])

    try:
        container = cmd_out(["docker", "run", "--detach", image, "/bin/true"]).strip()
    except OperationFailedError:
        fail(f"Failed to start container, image: {image}")
    else:
        print(f"Downloading boot tar {kernel}")
        extract_boot_tar(kernel, mnt_dir)
        print(f"Exporting docker container: {container} contents to {mnt_dir}")
        export_image_contents(container.decode(), image, mnt_dir)

    grub_cfg = os.path.join(mnt_dir, "boot/grub/grub.cfg")

    fs_uuid = get_fs_uuid(mount_point)

    regex_replace(grub_cfg, boot_uuid, fs_uuid)

    cmd("Remove device.map file",
        ["rm", "--recursive", "--force", os.path.join(mnt_dir, "boot/grub/device.map")])

    cmd("Install grub",
        ["grub2-install",
         "--efi-directory=/boot/efi",
         "--target=x86_64-efi",
         "--boot-directory=" + os.path.join(mnt_dir, "boot"), device])

    print(f"Writing UUID: {fs_uuid} to fstab")
    fstab_file = os.path.join(mnt_dir, "etc/fstab")
    with open(fstab_file, "a") as f:
        print("UUID=%s / ext4 errors=remount-ro 0 1", fs_uuid, file=f)

    cmd("Set root password",
        ["chroot", mnt_dir, "/bin/bash", "-c", "echo root:r | chpasswd"])

    cmd(f"Unmount {mnt_dir}",
        ["umount", mnt_dir])

    cmd(f"Disconnect {device}",
        ["qemu-nbd", "--disconnect", device])

    cmd("Archive",
        ["tar", "--sparse", "--gzip", "--create", "--file=" + "test.tar", disk])

    os.remove(disk)


class OperationFailedError(Exception):
    def __init__(self, reason):
        self.msg = reason


if __name__ == '__main__':
    main()