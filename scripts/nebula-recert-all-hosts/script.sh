if [[ $# -ne 0 ]]; then
  echo "Usage: $0" >&2
  exit 1
fi

hosts_json="$(mktemp)"
ca_key="$(mktemp)"
chmod 600 "$ca_key"
trap 'rm -f "$hosts_json" "$ca_key"' EXIT

nix eval --json --impure --expr 'builtins.getFlake ("git+file://" + toString ./.)' --apply "import $inventory_nix" > "$hosts_json"

if ! declare -px BW_SESSION >/dev/null 2>&1; then
  BW_SESSION="$(bw unlock --raw || bw login --raw)"
  export BW_SESSION
fi

bw get notes 'nebula ca-key' > "$ca_key"

nebula-recert "$hosts_json" "$ca_key"

echo "Done!"
