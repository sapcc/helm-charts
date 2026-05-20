{
    "sm_policy": {
        "name": "snapshot-logs-swift-delete-policy",
        "description": "Snapshot policy to remove old logs-swift snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 3 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.data_stream.logs_swift.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": ".ds-logs-swift-datastream*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.data_stream.logs_swift.snapshots.repository }}"
        },
        "enabled": true
    }
}
