#!/usr/bin/env bash
set -uo pipefail

report_file=${REPORT_FILE:-closure-diff-report/report.json}
commit_title=${COMMIT_TITLE-}
commit_title=${commit_title%%$'\n'*}
work_dir=$(mktemp --directory)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$(dirname "$report_file")"
: > "$work_dir/hosts.jsonl"
failed=0

while IFS= read -r closure; do
  host=$(jq -r .host <<< "$closure")
  old_closure=$(jq -r .current_closure <<< "$closure")
  new_closure=$(jq -r .expected_closure <<< "$closure")
  deployment_required=false
  status=success
  error=null
  diff_file="$work_dir/$host.diff"
  : > "$diff_file"

  if [[ $old_closure != "$new_closure" ]]; then
    deployment_required=true
    if ! nix build --no-link "$old_closure" "$new_closure" > /dev/null; then
      status=error
      error='{"stage":"realize-closures","exit_code":1}'
    else
      dix --color never "$old_closure" "$new_closure" > "$diff_file" 2>&1
      exit_code=$?
      cat "$diff_file"
      if ((exit_code)); then
        status=error
        error=$(jq -cn --argjson exit_code "$exit_code" '{stage:"diff-closures",$exit_code}')
      fi
    fi
  fi

  jq -cn \
    --argjson closure "$closure" --arg status "$status" \
    --argjson deployment_required "$deployment_required" --rawfile diff "$diff_file" \
    --argjson error "$error" \
    '{
      host: $closure.host,
      old_closure: $closure.current_closure,
      new_closure: $closure.expected_closure,
      $status, $deployment_required, $diff
    } + if $error == null then {} else {$error} end' >> "$work_dir/hosts.jsonl"
  [[ $status == success ]] || failed=1
done < <(jq -c '.[]' <<< "$CLOSURE_PATHS")

hosts=$(jq -s 'sort_by(.host)' "$work_dir/hosts.jsonl")
jq -n \
  --arg repository "$REPOSITORY" --arg sha "$COMMIT_SHA" --arg title "$commit_title" \
  --argjson id "$RUN_ID" --argjson index "$RUN_NUMBER" --arg event "$EVENT_NAME" \
  --argjson hosts "$hosts" --argjson failed "$failed" \
  '{
    result: (if $failed == 0 then "complete" else "incomplete" end),
    $repository,
    commit: {$sha,$title},
    run: {$id,index_in_repo:$index,workflow:"ci.yml",$event},
    summary: {
      expected: ($hosts|length),
      deployment_required: ($hosts|map(select(.status=="success" and .deployment_required))|length),
      unchanged: ($hosts|map(select(.status=="success" and (.deployment_required|not)))|length),
      failed: ($hosts|map(select(.status=="error"))|length)
    },
    $hosts
  }' > "$report_file"

jq . "$report_file"
exit "$failed"
