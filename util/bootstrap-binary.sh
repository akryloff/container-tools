#!/usr/bin/env bash

url="$1"
output_file="$2"
output_dir="$3"
sum="$4"

tmpfile=$(mktemp "$output_dir/.download_XXXX")
trap "rm --force -- ${tmpfile}" EXIT

if curl --silent --location --retry 3 --retry-delay 1 --fail --show-error --output "$tmpfile" "$url"; then
	mv "$tmpfile" $output_dir/"$output_file"
	sha256sum --check - <<EOF
${sum} ${output_dir}/${output_file}
EOF
else
	rm --force "$tmpfile"
	return 1
fi