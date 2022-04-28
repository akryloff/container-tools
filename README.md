# Prerequisites:

- Must be run as root on rpm-based Linux distro with either podman or docker installed

```
help:
    @echo
    @echo "Usage: make <target>"
    @echo
    @echo " * 'shellcheck' - Execute the shellcheck linter"
    @echo " * 'typos' - Check typos"
    @echo " * 'fix-typos' - Fix typos"
    @echo " * 'install-docker' - Install docker-ce"
    @echo " * 'install-podman' - Install podman"
    @echo
    @echo " ** Oracle Linux targets ** "
    @echo "OL-ALL, OL8, OL7, OL8-full, OL8-slim"
    @echo "OL-ALL-AARCH, OL8-aarch64, OL7-aarch64, OL8-full-aarch64, OL8-slim-aarch64"
```

Build script by default will use Podman
If Podman is not available it will use Docker instead

# Custom images

oraclelinux/oracle_packages.mk - list of packages which will be installed in chroot/image

# Using internal repositories

Define $INTERNAL to use internal repositories - oraclelinux/repos/internal

```
INTERNAL=1 make OL8-slim
```
Set up proxy to build images from public repositories with VPN enabled 

```
 alias proxyon="export http_proxy='http://${PROXY:PORT}';export https_proxy='${PROXY:PORT}'"; alias proxyoff="export http_proxy='';export https_proxy=''"

 proxyon
 proxyoff
```

# Debugging

Set $TRACE to output both the raw value and function calls

```
TRACE=1 make OL8-slim
```

# Make targets & variables

$ORACLE_COMPRESSION - Compression value, used by xz command, default value is "1"

```
ORACLE_COMPRESSION=1 make OL8-slim
```

make install-docker: - Warning! Will uninstall podman if it's present in the system
make install-podman: - Warning! Will uninstall docker-ce if it's present in the system

# Vagrant (optional)

Vagrant config will use "bento/oracle-8" box
Upon startup it will update VM and install dependencies

```
vagrant up
vagrant ssh
cd /opt/base_images
sudo su
make OL-ALL
```