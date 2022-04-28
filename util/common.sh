run() {
  echo >&2 "$(timestamp) RUN $* "
  "${@}"
  e=$?

  if ((e != 0)); then
    echo >&2 "Код ошибки: $e, программа была прервана"
    exit
  fi
}

header() {
  echo
  msg="${1:-}"
  echo
  printf ["$msg"] >/dev/stderr
  echo
  printf ':%.0s' $(seq 1 80)
  echo
}

timestamp() {
  date +"[%Y-%m-%d %T] -"
}

die() {
  echo "ERROR $*" >&2
  exit 1
}

warn() {
  echo >&2 "$(timestamp) WARN $*"
}

info() {
  echo >&2 "$(timestamp) INFO $*"
}

source-files-in() {
  local dir="$1"

  if [[ -d "$dir" && -r "$dir" && -x "$dir" ]]; then
    for file in "$dir"/*; do
      [[ -f "$file" && -r "$file" ]] && run source "$file"
    done
  fi
}

print-array() {
  printf '%s\n' "${@}"
}

printlog() {
  printf '\n'
  printf '%s\n' "${*}"
  printf '\n'
}

check-commands() {
  local commands=("${@}")

  for cmd in $(print-array "${commands[@]}"); do
    echo "Проверяем наличие в системе команды $cmd"
    if ! command -v "$cmd" &>/dev/null; then
      die "$cmd команда не найдена"
    fi
  done
}

timer-on() {
  start=$(date +%s)
}

timer-off() {
  end=$(date +%s)
  elapsed=$((end - start))
  echo "Прошло времени: $elapsed"
  echo
}

frealpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

retry() {
  local tries=$1
  shift

  local i=0
  while [ "$i" -lt "$tries" ]; do
    "$@" && return 0
    sleep $((2**((i++))))
  done

  return 1
}

check_sum() {
  local sum=$1
  local file=$2

  info "Файл: $file"
  info "Контрольная сумма: $sum"

  sha256sum --check - <<EOF
${sum} ${file}
EOF
}

download() {
  local url="$1"
  local output_file="$2"
  local output_dir="$3"
  local tmpfile

  tmpfile=$(mktemp "$output_dir/.download_XXXX")
  trap "rm --force -- ${tmpfile}" EXIT

  if run curl --silent --location --retry 3 --retry-delay 1 --fail --show-error --output "$tmpfile" "$url"; then
    run mv "$tmpfile" $output_dir/"$output_file"
  else
    run rm --force "$tmpfile"
    return 1
  fi
}