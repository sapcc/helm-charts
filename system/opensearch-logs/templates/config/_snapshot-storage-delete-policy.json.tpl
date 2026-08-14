{
    "sm_policy": {
        "name": "snapshot-storage-delete-policy",
        "description": "Snapshot policy to remove old storage snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 4 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.data_stream.storage.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": ".ds-storage-datastream*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.data_stream.storage.snapshots.repository }}"
        },
        "enabled": true
    }
}
