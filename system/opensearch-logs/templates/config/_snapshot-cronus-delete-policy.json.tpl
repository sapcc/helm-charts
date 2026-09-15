{
    "sm_policy": {
        "name": "snapshot-cronus-delete-policy",
        "description": "Snapshot policy to remove old cronus snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 1 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.data_stream.cronus.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": ".ds-cronus-datastream*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.data_stream.cronus.snapshots.repository }}"
        },
        "enabled": true
    }
}