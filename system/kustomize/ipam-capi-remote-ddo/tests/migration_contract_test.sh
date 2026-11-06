#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/ipam-migration.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT
kustomize build "$DIR/../shoot" > "$WORK/shoot.yaml"
kustomize build "$DIR/../seed" > "$WORK/seed.yaml"
PYTHONDONTWRITEBYTECODE=1 python3 "$DIR/migration_contract.py" "$WORK/shoot.yaml" "$WORK/seed.yaml"
