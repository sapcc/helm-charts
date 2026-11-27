#!/usr/bin/env bash
set -euo pipefail

# Exit code 4 means orphaned allocations were found and deleted. Treat this as
# success, like exit code 0 when no orphaned allocations were found.
nova-manage placement audit --verbose --delete || [[ "$?" == "4" ]]
