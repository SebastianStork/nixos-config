#!/usr/bin/env bash
set -euo pipefail

work_dir=$(mktemp --directory)
trap 'rm -rf "$work_dir"' EXIT
jq --compact-output '.[]' > "$work_dir/hosts.jsonl"

collect_host() {
  local host=$1
  local name current_closure_url current_closure expected_closure
  name=$(jq --raw-output .name <<< "$host")
  current_closure_url=$(jq --raw-output .current_closure_url <<< "$host")
  expected_closure=$(jq --raw-output .expected_closure <<< "$host")
  current_closure=$(curl --fail --silent --show-error --connect-timeout 5 --max-time 10 "$current_closure_url")

  jq --null-input --compact-output \
    --arg host "$name" \
    --arg current_closure "$current_closure" \
    --arg expected_closure "$expected_closure" \
    '{ $host, $current_closure, $expected_closure }'
}

pids=()
while IFS= read -r host; do
  collect_host "$host" > "$work_dir/${#pids[@]}.json" &
  pids+=("$!")
done < "$work_dir/hosts.jsonl"

failed=0
for pid in "${pids[@]}"; do
  wait "$pid" || failed=1
done

if ((failed)); then
  echo "Failed to collect one or more current closure paths" >&2
  exit 1
fi

find "$work_dir" -type f -name '*.json' -exec cat {} + |
  jq --compact-output --slurp 'sort_by(.host)'
