{
    "sm_policy": {
        "name": "snapshot-maillogkr-delete-policy",
        "description": "Snapshot policy to remove old maillogkr snapshots.",
        "deletion": {
            "schedule": {
                "cron": {
                    "expression": "0 6 * * *",
                    "timezone": "UTC"
                }
            },
            "condition": {
                "max_age": "{{ .Values.global.index.maillogkr.snapshots.retention }}",
                "min_count": 1
            },
            "time_limit": "1h",
            "snapshot_pattern": "{{ .Values.global.index.maillogkr.index_pattern }}*"
        },
        "snapshot_config": {
            "repository": "{{ .Values.global.index.maillogkr.snapshots.repository }}"
        },
        "enabled": true
    }
}
