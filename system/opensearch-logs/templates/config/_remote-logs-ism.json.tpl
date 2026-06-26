{
    "policy": {
        "policy_id": "remote-logs-ism",
        "description": "ISM policy for logs searchable snapshot.",
        "default_state": "initial",
        "states": [
            {
                "name": "initial",
                "actions": [
                    {
                        "retry": {
                            "count": 3,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "replica_count": {
                            "number_of_replicas": 0
                        }
                    }
                ],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.data_stream.logs.searchable_snapshots.retention }}"
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
        "ism_template":  {
            "index_patterns": [
                "remote_.ds-logs-datastream*"
            ],
            "priority": 2
        }
    }
}