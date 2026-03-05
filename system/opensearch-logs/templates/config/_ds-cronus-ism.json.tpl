{
    "policy": {
        "policy_id": "ds-cronus-ism",
        "description": "Datastream (ds) ism policy for cronus-ds",
        "schema_version": "{{ .Values.global.data_stream.schema_version }}",
        "default_state": "initial",
        "states": [
            {
                "name": "initial",
                "actions": [],
                "transitions": [
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.data_stream.cronus.min_index_age }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_size": "{{ .Values.global.data_stream.cronus.min_size }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_doc_count": "{{ .Values.global.data_stream.cronus.min_doc_count }}"
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
                            "min_index_age": "7d"
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
                    "cronus-datastream"
                ],
                "priority": 2
            }
    }
}
