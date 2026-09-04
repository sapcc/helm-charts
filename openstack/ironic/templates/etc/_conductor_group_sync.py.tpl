{{- define "ironic_conductor_group_sync_py" }}
#!/usr/bin/env python3
"""
conductor-group-sync: update conductor_group on Ironic nodes to match the
conductor groups defined in conductor.hosts.

Reads OpenStack credentials from the environment (sourced from ironic.conf
and secrets.conf by the CronJob wrapper).
"""

import re
import sys
import json
import subprocess

# Block -> conductor group mapping, rendered from conductor.hosts at deploy time
BLOCK_TO_GROUP = {
{{- range .Values.conductor.hosts }}
{{- $group := .name }}
{{- range (.blocks | default list) }}
    {{ . | quote }}: {{ $group | quote }},
{{- end }}
{{- end }}
}


def openstack(args):
    cmd = ["openstack"] + args + ["-f", "json"]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"ERROR: openstack {' '.join(args)} failed:\n{result.stderr}", file=sys.stderr)
        sys.exit(1)
    return json.loads(result.stdout)


def main():
    if not BLOCK_TO_GROUP:
        print("No block-to-group mapping configured, nothing to do.")
        sys.exit(0)

    print("Listing Ironic nodes...")
    nodes = openstack(["baremetal", "node", "list", "--fields", "uuid", "name", "conductor_group", "--limit", "0"])

    updates = []
    for node in nodes:
        name = node.get("Name") or node.get("name") or ""
        uuid = node.get("UUID") or node.get("uuid") or ""
        current_group = node.get("Conductor Group") or node.get("conductor_group") or ""

        if not name or not uuid:
            continue

        # Extract block from node name: last segment after - or .
        m = re.search(r'[.\-]([^.\-]+)$', name)
        if not m:
            continue
        block = m.group(1)

        expected_group = BLOCK_TO_GROUP.get(block)
        if expected_group is None:
            continue  # block not managed by us

        if current_group != expected_group:
            updates.append((uuid, name, block, current_group, expected_group))

    if not updates:
        print("All nodes already have the correct conductor_group.")
        sys.exit(0)

    print(f"Updating conductor_group on {len(updates)} node(s):")
    errors = 0
    for uuid, name, block, current, expected in updates:
        print(f"  {name} ({block}): {current!r} -> {expected!r}")
        result = subprocess.run(
            ["openstack", "baremetal", "node", "set", "--conductor-group", expected, uuid],
            capture_output=True, text=True
        )
        if result.returncode != 0:
            print(f"    ERROR: {result.stderr.strip()}", file=sys.stderr)
            errors += 1

    if errors:
        print(f"{errors} error(s) during update.", file=sys.stderr)
        sys.exit(1)

    print("Done.")
    sys.exit(0)


if __name__ == "__main__":
    main()
{{- end }}
