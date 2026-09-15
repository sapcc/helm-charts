{
    "sm_policy": {
        "name": "snapshot-mailloges-delete-policy",
        "description": "Snapshot policy to remove old mailloges snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 6 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.index.mailloges.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": "{{ .Values.global.index.mailloges.index_pattern }}*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.index.mailloges.snapshots.repository }}"
        },
        "enabled": true
    }
}
