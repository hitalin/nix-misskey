#!/usr/bin/env bash
# Regenerate pkgs/nodejs.json for a given Node.js version.
# Usage: pkgs/update-nodejs.sh 26.4.0   (or: pkgs/update-nodejs.sh "$(cat ../.node-version)")
set -euo pipefail

version="${1:?usage: $0 <node version, e.g. 26.4.0>}"
version="${version#v}"
sums="$(curl -fsSL "https://nodejs.org/dist/v${version}/SHASUMS256.txt")"

sum() { awk -v f="node-v${version}-$1.tar.xz" '$2 == f { print $1 }' <<<"$sums"; }

cat > "$(dirname "$0")/nodejs.json" <<JSON
{
  "version": "${version}",
  "sha256": {
    "x86_64-linux": "$(sum linux-x64)",
    "aarch64-linux": "$(sum linux-arm64)",
    "x86_64-darwin": "$(sum darwin-x64)",
    "aarch64-darwin": "$(sum darwin-arm64)"
  }
}
JSON
echo "pkgs/nodejs.json -> ${version}"
