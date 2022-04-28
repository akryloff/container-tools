#!/bin/bash

if [[ -n "$TRACE" ]]; then
    export PS4='[\D{%FT%TZ}] ${BASH_SOURCE}:${LINENO}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    set -o xtrace
fi

set -o errexit
set -o pipefail


if [[ $# -ne 5 ]]; then
    echo "Ошибка: Недостаточное количество аргументов"
    echo "Пример использования:"
    echo "${BASH_SOURCE[0]} --username=multiarch --project=qemu-user-static --version=latest --arch=x86_64_qemu-aarch64-static --output=/usr/bin"
    exit 1
fi

OPTIND=1
while getopts ":-:" optchar; do
  [[ "${optchar}" == "-" ]] || continue
  case "${OPTARG}" in
  username=*)
    username=${OPTARG#*=}
    ;;
  project=*)
    project=${OPTARG#*=}
    ;;
  version=*)
    version=${OPTARG#*=}
    ;;
  arch=*)
    arch=${OPTARG#*=}
    ;;
  output=*)
    output=${OPTARG#*=}
    ;;
  *)
    echo "Неправильный аргумент: '$OPTARG'"
    ;;
  esac
done
shift $((OPTIND - 1))

base_url='https://github.com'
regex="(.*)${arch}(.*).tar.gz"
curl_args=(--silent --location --show-error --fail)

# Из-за ограничений API GitHub, будем парсить HTML
# Если была указана другая версия пакета, кроме "latest", то к $url добавлен соответствующий сегмент
if [[ ${version} == latest ]]; then 
  url="${base_url}/${username}/${project}/releases/${version}"
  links=( `curl ${curl_args[@]} ${url} \
    | egrep '<a .*href=.*>' \
    | sed -e 's/<a /\n<a /g' -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' \
    | egrep ${regex}` )
else
  url="${base_url}/${username}/${project}/releases"
  links=( `curl ${curl_args[@]} ${url} \
    | egrep '<a .*href=.*>' \
    | sed -e 's/<a /\n<a /g' -e 's/<a .*href=['"'"'"]//' -e 's/["'"'"'].*$//' -e '/^$/ d' \
    | egrep ${regex} \
    | egrep ${version}` )
fi

direct_links=( `printf '%s\n' "${@}" ${links[@]} | awk -v base_url=$base_url '{print base_url $0}'` )

curl_args+=( --remote-name )

cd ${output}
for link in ${direct_links[@]}; do
    echo "Найден пакет: $link"
    curl ${curl_args[@]} $link
    out_file=$(tar -xvzf `basename $link`)
    unlink ${output}/`basename $link`
done
cd ~-

echo "Пакет установлен:" $(readlink --canonicalize ${output}/${out_file})