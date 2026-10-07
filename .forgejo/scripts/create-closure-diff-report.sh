#!/usr/bin/env bash
set -euo pipefail

report_file=${REPORT_FILE:-closure-diff-report/report.json}
work_dir=$(mktemp --directory)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$(dirname "$report_file")"
rm -f "$report_file"
: > "$work_dir/hosts.jsonl"

: "${BASE_SHA:?BASE_SHA is required}"
: "${HEAD_SHA:?HEAD_SHA is required}"
: "${FLAKE_URL:?FLAKE_URL is required}"

get_closures() {
  local revision=$1
  nix eval "$FLAKE_URL?rev=$revision#nixosConfigurations" --apply 'configs:
    configs
    |> builtins.attrNames
    |> builtins.map (name: {
      inherit name;
      path = configs.${name}.config.system.build.toplevel.outPath;
    })
  ' --json
}

base_closures=$(get_closures "$BASE_SHA")
head_closures=$(get_closures "$HEAD_SHA")

if ! jq --exit-status --null-input \
  --argjson base "$base_closures" --argjson head "$head_closures" \
  '($base | map(.name) | sort) == ($head | map(.name) | sort)' > /dev/null; then
  echo "The set of NixOS configurations differs between the base and head revisions" >&2
  exit 1
fi

closures=$(jq --compact-output --null-input \
  --argjson base "$base_closures" --argjson head "$head_closures" '
    $head | map(. as $new | ($base[] | select(.name == $new.name)) as $old | {
      name: $new.name,
      old_closure: $old.path,
      new_closure: $new.path
    })
  ')

while IFS= read -r closure; do
  name=$(jq --raw-output .name <<< "$closure")
  old_closure=$(jq --raw-output .old_closure <<< "$closure")
  new_closure=$(jq --raw-output .new_closure <<< "$closure")

  nix build --no-link "$old_closure" "$new_closure"

  diff_file="$work_dir/$name.json"
  dix --force-correctness --output json "$old_closure" "$new_closure" > "$diff_file"
  jq . "$diff_file"
  jq --compact-output --null-input \
    --arg name "$name" --slurpfile diff "$diff_file" \
    '{name: $name} + $diff[0]' >> "$work_dir/hosts.jsonl"
done < <(jq --compact-output '.[]' <<< "$closures")

jq --null-input \
  --arg base_sha "$BASE_SHA" --arg head_sha "$HEAD_SHA" \
  --slurpfile hosts "$work_dir/hosts.jsonl" \
  '{$base_sha, $head_sha, hosts: ($hosts | sort_by(.name))}' > "$report_file"

jq . "$report_file"
