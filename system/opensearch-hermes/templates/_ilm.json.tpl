{
    "policy": {
        "description": "Simple 365d log retention",
        "default_state": "ingest",
        "schema_version": 1,
        "states": [
            {
                "name": "ingest",
                "actions": [],
                "transitions": [
                    {
                        "state_name": "close",
                        "conditions": {
                            "min_index_age": "365d"
                        }
                    }
                ]
            },
            {
                "name": "close",
                "actions": [
                    {
                        "retry": {
                            "count": 3,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "close": {}
                    }
                ],
                "transitions": []
            }
        ],
        "ism_template": [
            {
                "index_patterns": [
                    "audit-*"
                ],
                "priority": 1
            }
        ]
    }
}
