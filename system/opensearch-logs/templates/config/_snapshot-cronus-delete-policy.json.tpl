{
    "sm_policy": {
        "name": "snapshot-cronus-delete-policy",
        "description": "Snapshot policy to remove old cronus snapshots.",
        "schema_version": "{{ .Values.snapshots.schema_version }}",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 0 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.snapshots.cronus.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": ".ds-cronus-datastreamm*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.data_stream.cronus.snapshot_repository }}"
        },
        "enabled": true
    }
}