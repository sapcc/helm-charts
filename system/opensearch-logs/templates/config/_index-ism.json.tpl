{
    "policy": {
        "description": "Simple 31d log retention",
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
                            "min_index_age": "31d"
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
                    "syslog-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "admin-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "kubernikus-*"
                ],
                "priority": 1
            },
            {
                "index_patterns": [
                    "virtual-*"
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
                    "scaleout-*"
                ],
                "priority": 1
            }
        ]
    }
}
