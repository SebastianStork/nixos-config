#!/usr/bin/env bash
set -euo pipefail

selected_dir=$(mktemp --directory)
trap 'rm -rf "$selected_dir"' EXIT

jq --compact-output '.[]' > "$selected_dir/targets.jsonl"

check_host() {
  local target=$1
  local name expected_system url current_system

  name=$(jq --raw-output .name <<< "$target")
  expected_system=$(jq --raw-output .path <<< "$target")
  url=$(jq --raw-output .url <<< "$target")

  if current_system=$(curl --fail --silent --show-error --connect-timeout 5 --max-time 10 "$url"); then
    if [[ $current_system == "$expected_system" ]]; then
      echo "$name is already running $expected_system" >&2
      return
    fi
    echo "$name requires deployment: currently running $current_system, expected $expected_system" >&2
  else
    echo "$name requires deployment: failed to query $url" >&2
  fi

  jq --null-input --arg name "$name" '$name'
}

pids=()
while IFS= read -r target; do
  check_host "$target" > "$selected_dir/${#pids[@]}.json" &
  pids+=("$!")
done < "$selected_dir/targets.jsonl"

failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=1
  fi
done

if ((failed)); then
  echo "Failed to check one or more hosts" >&2
  exit 1
fi

find "$selected_dir" -type f -name '*.json' -exec cat {} + |
  jq --compact-output --slurp 'sort'
