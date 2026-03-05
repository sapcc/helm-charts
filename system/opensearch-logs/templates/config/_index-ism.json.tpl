{
    "policy": {
        "description": "Simple {{ .Values.retention.index}} log retention",
        "default_state": "ingest",
        "schema_version": 25,
        "states": [
            {
                "name": "ingest",
                "actions": [],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.retention.index}}"
                        }
                    }
                ]
            },
            {
                "name": "delete",
                "actions": [
                    {
                        "retry": {
                            "count": 3,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "delete": {}
                    }
                ],
                "transitions": []
            }
        ],
        "ism_template": [
            {
                "index_patterns": [
                    "logstash-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "systemd-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "qade2-logstash-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "qade3-logstash-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "qade5-logstash-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "jump-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "compute-*"
                ],
                "priority": 1
            }
            {
                "index_patterns": [
                    "storage-*"
                ],
                "priority": 1
            }
        ]
    }
}
