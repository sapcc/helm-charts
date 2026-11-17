#!/usr/bin/env bash
set -euo pipefail

finish() {
    status=$?
    trap - EXIT
    set +e
    {{- include "utils.script.job_finished_hook" . | nindent 4 }}
    exit "$status"
}
trap finish EXIT

manage=(keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf)
phase=${1:?Expected initialize, expand or contract}

case "$phase" in
    initialize)
        "${manage[@]}" db_sync
        "${manage[@]}" doctor
        ;;
    expand)
        # Skip doctor until "--ignore" is supported
        # "${manage[@]}" doctor
        "${manage[@]}" db_sync --expand
        ;;
    contract)
        # A ready Service can still route to old replicas. Recheck the target
        # rollout immediately before the destructive schema step.
        python3 /upgrade/rollout.py
        "${manage[@]}" db_sync --contract
        ;;
    *)
        echo "Unknown database migration phase: $phase" >&2
        exit 1
        ;;
esac

status=0
"${manage[@]}" db_sync --check || status=$?
if [[ "$status" == 0 || ( "$phase" == expand && "$status" == 4 ) ]]; then
    echo "Database $phase completed (schema check: $status)."
else
    echo "Unexpected database state after $phase (schema check: $status)." >&2
    exit "$status"
fi
