#!/usr/bin/env bash
set -euo pipefail

selected_dir=$(mktemp --directory)
trap 'rm -rf "$selected_dir"' EXIT

jq --compact-output '.[]' > "$selected_dir/targets.jsonl"

check_output() {
  local target=$1
  local name store_path store_name store_hash narinfo_url http_code

  name=$(jq --raw-output .name <<< "$target")
  store_path=$(jq --raw-output .path <<< "$target")
  store_name=${store_path#/nix/store/}
  store_hash=${store_name%%-*}
  narinfo_url="https://cache.splitleaf.de/$store_hash.narinfo"

  if http_code=$(curl --silent --show-error --head --output /dev/null --write-out '%{http_code}' --connect-timeout 5 --max-time 10 "$narinfo_url"); then
    if [[ $http_code == 200 ]]; then
      echo "$name is already cached as $store_path" >&2
      return
    fi
    echo "$name is not cached: $narinfo_url returned HTTP $http_code" >&2
  else
    echo "$name is not cached: failed to query $narinfo_url" >&2
  fi

  jq --null-input --arg name "$name" '$name'
}

pids=()
while IFS= read -r target; do
  check_output "$target" > "$selected_dir/${#pids[@]}.json" &
  pids+=("$!")
done < "$selected_dir/targets.jsonl"

failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=1
  fi
done

if ((failed)); then
  echo "Failed to check one or more cache outputs" >&2
  exit 1
fi

find "$selected_dir" -type f -name '*.json' -exec cat {} + |
  jq --compact-output --slurp 'sort'
