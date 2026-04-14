{
    "sm_policy": {
        "name": "snapshot-audit-delete-policy",
        "description": "Snapshot policy to remove old audit snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 0 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.data_stream.audit.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": ".ds-audit-datastream*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.data_stream.audit.snapshots.repository }}"
        },
        "enabled": true
    }
}