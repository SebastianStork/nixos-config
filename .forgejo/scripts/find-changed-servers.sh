#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC2016 # Nix interpolation is intentionally single-quoted.
targets=$(nix eval .#nixosConfigurations --apply 'configs:
  configs
  |> builtins.attrNames
  |> builtins.filter (hostName: configs.${hostName}.config.custom.services.deploy-webhook.enable)
  |> builtins.map (hostName: {
    host = hostName;
    system = configs.${hostName}.config.system.build.toplevel.outPath;
    url = "https://${configs.${hostName}.config.custom.networking.overlay.fqdn}/hooks/current-system";
  })
' --json)

changed_dir=$(mktemp --directory)
trap 'rm -rf "$changed_dir"' EXIT

jq --compact-output '.[]' <<< "$targets" > "$changed_dir/targets.jsonl"

check_host() {
  local target=$1
  local host expected_system url current_system

  host=$(jq --raw-output .host <<< "$target")
  expected_system=$(jq --raw-output .system <<< "$target")
  url=$(jq --raw-output .url <<< "$target")

  if current_system=$(curl --fail --silent --show-error --connect-timeout 5 --max-time 10 "$url"); then
    if [[ $current_system == "$expected_system" ]]; then
      echo "$host is already running $expected_system" >&2
      return
    fi
    echo "$host changed: currently running $current_system, expected $expected_system" >&2
  else
    echo "$host changed: failed to query $url" >&2
  fi

  printf '%s\n' "$target" > "$changed_dir/$host.json"
}

pids=()
while IFS= read -r target; do
  check_host "$target" &
  pids+=("$!")
done < "$changed_dir/targets.jsonl"

failed=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    failed=1
  fi
done

if ((failed)); then
  echo "Failed to check one or more servers" >&2
  exit 1
fi

find "$changed_dir" -type f -name '*.json' -exec cat {} + |
  jq --compact-output --slurp 'map(.host) | sort'
