#!/bin/bash

packages=${@}

case $(grep --only-matching --perl-regexp '(?<=^ID=).+' /etc/os-release | tr --delete '"') in
  fedora)
    pkg_manager=(yum install --assumeyes)
    ;;
  debian | ubuntu)
	pkg_manager=(apt-get install --yes --no-install-recommends)
    ;;
  *)
    echo "Скрипт не смог установить дистрибутив Linux"
    ;;
esac

n=0
max=2
until [ $n -gt $max ]; do
    set +e
    (
		"${pkg_manager[@]}" ${packages[@]}
    )
    CODE=$?
    set -e
    if [ $CODE -eq 0 ]; then
        break
    fi
    if [ $n -eq $max ]; then
        exit $CODE
    fi
    echo "${pkg_manager} закончил работу ошибкой, пробуем снова"
    n=$(($n + 1))
done