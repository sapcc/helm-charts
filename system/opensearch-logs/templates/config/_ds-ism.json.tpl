{
    "policy": {
        "policy_id": "otel-_DS_NAME_-ism",
        "description": "Datastream (ds) ism policy for _DS_NAME_-ds",
        "schema_version": _SCHEMAVERSION_,
        "default_state": "initial",
        "states": [
            {
                "name": "initial",
                "actions": [],
                "transitions": [
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_index_age": "_MIN_INDEX_AGE_"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_size": "_MIN_SIZE_"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_doc_count": "_MIN_DOC_COUNT_"
                        }
                    }
                ]
            },
            {
                "name": "rollover",
                "actions": [
                    {
                        "retry": {
                            "count": 5,
                            "backoff": "exponential",
                            "delay": "1m"
                        },
                        "rollover": {
                            "min_doc_count": 5,
                            "min_index_age": "1d",
                            "copy_alias": false
                        }
                    }
                ],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.retention.ds }}"
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
        "ism_template":
            {
                "index_patterns": [
                    "_DS_NAME_-datastream"
                ],
                "priority": 1
            }
    }
}
