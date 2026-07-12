if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <hostname>" >&2
  exit 1
fi

hostname="$1"

if [ -z "${NEBULA_CA_KEY:-}" ]; then
  echo "Missing NEBULA_CA_KEY; enter the nebula dev shell first: nix develop .#nebula" >&2
  exit 1
fi

hosts_json="$(mktemp)"
trap 'rm -f "$hosts_json"' EXIT

nix eval --json --impure --expr 'builtins.getFlake ("git+file://" + toString ./.)' --apply "import $inventory_nix \"$hostname\"" > "$hosts_json"

nebula-recert "$hosts_json" <(printf '%s\n' "$NEBULA_CA_KEY")
