#!/usr/bin/env bash
# Compare the shoot CRDs to the optional, untracked live-cluster capture.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(cd "$OVERLAY_DIR/../.." && pwd)"
LIVE_DIR="$REPO_ROOT/.superpowers/sdd/2026-10-30-ipam-capi-remote-ddo/live-crds"

command -v kustomize >/dev/null || { echo "FAIL: kustomize not found in PATH"; exit 1; }
python3 -c 'import yaml' || { echo "FAIL: python3 with PyYAML is required"; exit 1; }
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ipam-crd-diff.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
kustomize build "$OVERLAY_DIR/shoot" > "$WORK_DIR/shoot.yaml"

python3 - "$WORK_DIR/shoot.yaml" "$LIVE_DIR" "$OVERLAY_DIR/shoot/crds" <<'PY'
import copy
import difflib
from pathlib import Path
import sys

import yaml


def normalize(document):
    document = copy.deepcopy(document)
    document.pop("status", None)
    metadata = document["metadata"]
    for key in ("resourceVersion", "uid", "generation", "creationTimestamp",
                "managedFields", "ownerReferences"):
        metadata.pop(key, None)
    for field in ("labels", "annotations"):
        entries = metadata.get(field, {})
        for key, value in list(entries.items()):
            if (key.startswith(("meta.helm.sh/", "resources.gardener.cloud/",
                                "reference.resources.gardener.cloud/"))
                    or (key == "app.kubernetes.io/managed-by"
                        and value in ("Helm", "gardener"))):
                del entries[key]
        # Kustomize omits empty metadata maps; no identity fields are removed.
        if not entries:
            metadata.pop(field, None)
    return document


pool_names = (
    "globalinclusterippools", "globalinclusterprefixpools",
    "inclusterippools", "inclusterprefixpools",
)
short_names = (*pool_names, "ipaddresses", "ipaddressclaims", "clusters")
render_path, live_dir, crd_dir = map(Path, sys.argv[1:])
documents = [doc for doc in yaml.safe_load_all(render_path.read_text())
             if doc and doc.get("kind") == "CustomResourceDefinition"]
live_available = live_dir.is_dir()
if not live_available:
    print("SKIP: live-crds/ not present; live bundle unavailable, skipping field-diff")

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)
        print(f"FAIL: {message}")


check(len(documents) == 7, f"expected 7 rendered CRDs, got {len(documents)}")
for short_name in short_names:
    group = "cluster.x-k8s.io" if short_name == "clusters" else "ipam.cluster.x-k8s.io"
    name = f"{short_name}.{group}"
    matches = [doc for doc in documents if doc["metadata"]["name"] == name]
    check(len(matches) == 1, f"expected exactly one rendered {name}")
    if len(matches) != 1:
        continue
    rendered = matches[0]
    vendor_path = crd_dir / f"{short_name}.yaml"
    check(vendor_path.is_file(), f"missing vendored file {vendor_path}")
    if not vendor_path.is_file():
        continue
    vendored = yaml.safe_load(vendor_path.read_text())
    for source, document in (("rendered", rendered), ("vendored", vendored)):
        metadata = document["metadata"]
        check(document.get("kind") == "CustomResourceDefinition"
              and metadata.get("name") == name, f"{source}: CRD identity {name}")
        expected_stamp = "v0.17.2" if short_name in pool_names else "v0.21.0"
        check(metadata.get("annotations", {}).get("controller-gen.kubebuilder.io/version")
              == expected_stamp, f"{source}: {name} controller-gen stamp {expected_stamp}")
        if short_name in pool_names:
            check(metadata.get("labels", {}).get("clusterctl.cluster.x-k8s.io/move-hierarchy")
                  == "", f"{source}: {name} move-hierarchy label present and empty")
    if live_available:
        live_path = live_dir / f"{name}.raw.yaml"
        check(live_path.is_file(), f"missing live capture {live_path}")
        if not live_path.is_file():
            continue
        live = yaml.safe_load(live_path.read_text())
        expected = yaml.safe_dump(normalize(live), sort_keys=True).splitlines(keepends=True)
        actual = yaml.safe_dump(normalize(rendered), sort_keys=True).splitlines(keepends=True)
        diff = "".join(difflib.unified_diff(expected, actual,
                                         fromfile=str(live_path), tofile=f"rendered/{name}"))
        check(not diff, f"{name} normalized live field-diff")
        if diff:
            print(diff)
        else:
            print(f"PASS: {name} normalized live field-diff empty")

if failures:
    sys.exit(1)
print("PASS: all 7 CRDs present; vendored and rendered metadata match the capture contract")
PY
