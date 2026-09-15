{
    "sm_policy": {
        "name": "snapshot-logs-delete-policy",
        "description": "Snapshot policy to remove old logs snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 2 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.data_stream.logs.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": ".ds-logs-datastream*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.data_stream.logs.snapshots.repository }}"
        },
        "enabled": true
    }
}