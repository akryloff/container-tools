#!/usr/bin/env bash

if [ -n "$TRACE" ]; then
  export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCname[0]:+${FUNCname[0]}(): }'
  set -o xtrace
fi

set -o errexit
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

scriptdir=$(dirname "${BASH_SOURCE[0]}") && source "$scriptdir"/../util/common.sh

OPTIND=1
while getopts ":-:" optchar; do
  [[ "${optchar}" == "-" ]] || continue
  case "${OPTARG}" in
  name=*)
    name=${OPTARG#*=}
    ;;
  release=*)
    release=${OPTARG#*=}
    ;;
  keyrign=*)
    keyrign=${OPTARG#*=}
    ;;
  variant=*)
  variant=${OPTARG#*=}
    ;;
  repo_config=*)
    repo_config=${OPTARG#*=}
    ;;
  debootstrap_packages=*)
    debootstrap_packages=${OPTARG#*=}
    ;;
  packages=*)
    packages=${OPTARG#*=}
    # Меняем запятую на пробел в массиве
    packages=("${packages//,/ }")
    ;;
  recipes=*)
    recipes=${OPTARG#*=}
    recipes=("${recipes//,/ }")
    ;;
  scripts=*)
    scripts=${OPTARG#*=}
    scripts=("${scripts//,/ }")
    ;;
  help*)
    usage
  ;;
  *)
    echo "Неизвестный аргумент: '$OPTARG'"
    echo "Прочитать руководство по использованию можно с помощью ${0} —help"
    usage
    ;;
  esac
done
shift $((OPTIND - 1))

############################## ПЕРЕМЕННЫЕ И ПРОВЕРКИ ##############################

if [[ "$(uname -s)" != "Linux" ]]; then
  die "Этот скрипт будет работать только на GNU/Linux"
fi

if [[ "$EUID" != "0" ]]; then
  die "${BASH_SOURCE[0]} требуются права доступа root"
fi

if command -v getenforce; then
  if [[ ! "$(getenforce | grep --extended-regexp "Permissive|Disabled")" ]]; then
    die "Необходимо либо отключить SElinux, либо создать политику безопасности для контейнеров"
  fi
fi

if ! command -v podman; then
  warn "Podman не найден в системе — будет использовался Docker"
  podman=docker
else
  podman=podman
fi

target="$(mktemp --directory)"
tmpdir="$(mktemp --directory --tmpdir tmp-XXXXX)"
debootstrap_dir="$tmpdir"
logfile="$(date +%F_%H_%M_%S)"
dist="$scriptdir"/dist/$name && mkdir --parents "$dist"

repo_url="http://deb.debian.org/debian"
sec_repo_url="http://security.debian.org/"

usage() {
    echo "Usage: ${0} MACOS_CODESIGN_IDENTITY FILE-OR-DIRECTORY
    name=
    release=
    keyrign=
    variant=
    repo_config=
    debootstrap_packages=
    packages=
    recipes=
    scripts=
    help="
    exit 0
}

############################## MAIN ##############################

header "Аргументы скрипта"
printf '%s\n' "${BASH_ARGV[@]}" "${BASH_SOURCE[0]}" | tac | tr '\n' ' ' && echo

header "Переменные окружения"
run printenv

main() {
  timer-on
  
  header "Импортируем gpg ключ"
  run gpg --no-default-keyring --keyring "$keyrign" --import "$scriptdir"/keys/buster.gpg
  run gpg --no-default-keyring --keyring "$keyrign" --import "$scriptdir"/keys/unstable.gpg

  header "Подготавливаем скрипты debootstrap"
  run cp --archive /usr/share/debootstrap/* "$debootstrap_dir"
  run cp --archive "$scriptdir"/debootstrap/* "$debootstrap_dir/scripts"

  header "Создаем rootfs с помощью debootstrap"
  info "Сборка будет произведена в chroot: $target"
  DEBOOTSTRAP_DIR="$debootstrap_dir" run debootstrap --no-check-gpg --keyring "$keyrign" --variant "$variant" "${debootstrap_packages[@]}" --foreign "$release" "$target"
  LANG=C run chroot "$target" bash debootstrap/debootstrap --verbose --second-stage

  header "Настраиваем репозитории apt"
  echo "deb "$repo_url" "$release"-updates main" >> "$target"/etc/apt/sources.list
  echo "deb "$sec_repo_url" "$release"-security main" >> "$target"/etc/apt/sources.list
  run chroot "$target" apt-get update && apt-get install --yes --option Dpkg::Options::="--force-confdef"

  if [[ -v packages[@] ]]; then
    header "Устанавливаем пакеты"
    info "Следующие пакеты будут установлены в chroot:"
    print-array ${packages[@]}
    echo
    run chroot "$target" apt-get update && retry 3 chroot "$target" apt-get install --yes --no-install-recommends "${packages[@]}"
    info "Установленные пакеты:"
    chroot "$target" dpkg-query --show --showformat='${Package} ${Installed-Size}\n'
  fi

  if [[ -v recipes[@] ]]; then
    header "Запускаем установочные скрипты"
    while read -r line; do
      info "Запускаем ${line}"
      run source "${line}" && `basename ${line} .sh`
    done < <(print-array ${recipes[@]})
  fi

  header "Применяем специфичные для Docker настройки apt"
  run chroot "$target" apt-get --option Acquire::Check-Valid-Until=false update
  run chroot "$target" apt-get --yes --quiet upgrade
  echo '#!/bin/sh' > "$target"/usr/sbin/policy-rc.d
  echo 'exit 101' >> "$target"/usr/sbin/policy-rc.d
  run chmod +x "$target"/usr/sbin/policy-rc.d
  run dpkg-divert --local --rename --add "$target"/sbin/initctl
  run cp --archive "$target"/usr/sbin/policy-rc.d "$target"/sbin/initctl
  run sed --in-place 's/^exit.*/exit 0/' "$target"/sbin/initctl
  echo 'force-unsafe-io' > "$target"/etc/dpkg/dpkg.cfg.d/docker-apt-speedup
  echo 'DPkg::Post-Invoke { "rm --force /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > "$target"/etc/apt/apt.conf.d/docker-clean
  echo 'APT::Update::Post-Invoke { "rm --force /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> "$target"/etc/apt/apt.conf.d/docker-clean
  echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> "$target"/etc/apt/apt.conf.d/docker-clean
  echo 'Acquire::Languages "none";' > "$target"/etc/apt/apt.conf.d/docker-no-languages
  echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > "$target"/etc/apt/apt.conf.d/docker-gzip-indexes
  echo 'Apt::AutoRemove::SuggestsImportant "false";' > "$target"/etc/apt/apt.conf.d/docker-autoremove-suggests

  header "Чтобы уменьшить размер образа, удаляем опциональные файлы и директории"
  run chroot "$target" apt-get clean
  run chroot "$target" apt-get --yes autoremove
  run rm --recursive --force "$target"/dev "$target"/proc
  run mkdir --parents "$target"/dev "$target"/proc
  run rm --recursive --force "$target"/usr/bin/pinky
  run rm --recursive --force "$target"/etc/apt/apt.conf.d/01autoremove-kernels
  run rm --recursive --force "$target"/etc/machine-id
  run rm --recursive --force "$target"/etc/boot
  run rm --recursive --force "$target"/etc/hostname
  run rm --recursive --force "$target"/tmp/* "$target"/var/tmp/*
  run rm --recursive --force "$target"/etc/systemd/* "$target"/lib/systemd/*
  run rm --recursive --force "$target"/var/lib/apt/lists/*
  run rm --recursive --force "$target"/usr/share/info/*
  run rm --recursive --force "$target"/usr/lib/x86_64-linux-gnu/gconv/IBM* "$target"/usr/lib/x86_64-linux-gnu/gconv/EBC*
  run rm --recursive --force "$target"/usr/share/groff
  run rm --recursive --force "$target"/usr/share/lintian
  run rm --recursive --force "$target"/usr/share/linda
  run rm --recursive --force "$target"/var/lib/apt/lists/*
  run rm --recursive --force "$target"/usr/share/doc/*
  run rm --recursive --force "$target"/usr/share/pixmaps/*
  run rm --recursive --force "$target"/usr/share/locale/*
  run find "$target"/var/cache -type f -exec rm --recursive --force {} \;
  run find "$target"/var/log -type f -exec truncate --size 0 {} \;
  run rm --recursive --force "$target"/etc/ld.so.cache && run chroot "$target" ldconfig

  if [[ -v scripts[@] ]]; then
    header "Запускаем тестовые сценарии"
    source "${scripts}"
  fi

  header "Архивируем образ"
  GZIP="--no-name" run tar --numeric-owner -czf "$dist"/"$name".tar --directory "$target" . --transform='s,^./,,' --mtime='1970-01-01'
  md5sum "$dist"/"$name".tar > "$dist"/"$name".SUM

  header "Удаляем временные файлы и директории"
  run rm --recursive --force "$target"
  run rm --recursive --force "$debootstrap_dir"

  header "Сборка образа была завершена успешно"
  echo
  echo "Расположение артефакта: "$dist"/"$name".tar"
  echo
  echo "Размер артефакта: `du --summarize --human-readable "$dist"/"$name".tar | cut --fields 1`"
  echo

  timer-off
}

main "${@}" 2>&1 | tee "$dist"/"$logfile".log