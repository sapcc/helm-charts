#!/usr/bin/env bash
manage=(keystone-manage --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf)
phase=${1:?Expected initialize, expand or contract}

if [[ "$phase" != contract ]]; then
    # TODO(habetuz): Make doctor fail loud once '--ignore' is supported.
    echo "Keystone doctor:"
    "${manage[@]}" doctor
fi

if [[ "$phase" != contract ]]; then
    echo "Status before migration:"
    keystone-status --config-file=/etc/keystone/keystone.conf --config-file=/etc/keystone/keystone.conf.d/secrets.conf upgrade check
    status=$?
    if [[ "$status" == 1 ]]; then
        echo "WARNING: upgrade check returned warning (exit code 1). Continuing."
    elif [[ "$status" != 0 ]]; then
        echo "ERROR: upgrade check failed with exit code $status. Aborting." >&2
        {{ include "utils.script.job_finished_hook" . | trim }}
        exit "$status"
    fi
fi

echo "DB Version before migration:"
"${manage[@]}" db_version

status=0
case "$phase" in
    initialize)
        "${manage[@]}" db_sync || status=$?
        ;;
    expand)
        "${manage[@]}" db_sync --expand || status=$?
        ;;
    contract)
        # A ready Service can still route to old replicas. Recheck the target
        # rollout immediately before the destructive schema step.
        python3 /upgrade/rollout-check.py || status=$?
        if [[ "$status" == 0 ]]; then
            "${manage[@]}" db_sync --contract || status=$?
        fi
        ;;
    *)
        echo "Unknown database migration phase: $phase" >&2
        exit 1
        ;;
esac

echo "DB Version after migration:"
"${manage[@]}" db_version


if [[ "$status" == 0 ]]; then
    "${manage[@]}" db_sync --check || status=$?
    if [[ "$status" == 0 || ( "$phase" == expand && "$status" == 4 ) ]]; then
        echo "Database $phase completed (schema check: $status)."
        status=0
    else
        echo "Unexpected database state after $phase (schema check: $status)." >&2
    fi
fi

{{ include "utils.script.job_finished_hook" . | trim }}
exit "$status"
