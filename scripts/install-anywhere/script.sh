if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <host> <destination>"
	exit 1
fi

host="$1"
destination="$2"

if [ -z "${SOPS_AGE_KEY:-}" ]; then
	echo "Missing SOPS_AGE_KEY; enter the sops dev shell first: nix develop .#sops" >&2
	exit 1
fi

root="$(mktemp --directory)"
trap 'rm -rf "$root"' EXIT

echo "==> Generating a PQ age identity..."
age_key="$root$(nix eval --raw ".#nixosConfigurations.$host.config.sops.age.keyFile")"
install --directory --mode=0700 "$(dirname "$age_key")"
age-keygen -pq --output "$age_key"
age-keygen -y "$age_key" > "hosts/nixos/$host/keys/age.pub"

echo "==> Updating SOPS secrets..."
SOPS_CONFIG="$(nix build .#sops-config --no-link --print-out-paths)"
export SOPS_CONFIG
sops updatekeys --yes "hosts/nixos/$host/secrets.json"

echo "==> Installing system..."
nix run github:nix-community/nixos-anywhere -- \
	--extra-files "$root" \
	--flake ".#$host" \
	--target-host "$destination"
