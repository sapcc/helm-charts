{
    "policy": {
        "policy_id": "ds-opensearch-security-audit-ism",
        "description": "ISM policy for the OpenSearch security-plugin audit log datastream. Compliance: PCI-DSS 10.5.1, BSI IT-Grundschutz OPS.1.1.5 / ORP.4. Auto-cleanup at min_index_age.",
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
                            "min_index_age": "{{ .Values.global.data_stream.opensearch_security_audit.min_index_age }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_size": "{{ .Values.global.data_stream.opensearch_security_audit.min_size }}"
                        }
                    },
                    {
                        "state_name": "rollover",
                        "conditions": {
                            "min_doc_count": {{ .Values.global.data_stream.opensearch_security_audit.min_doc_count | int }}
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
                            "min_doc_count": 1,
                            "min_index_age": "1d",
                            "copy_alias": false
                        }
                    }
                ],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "{{ .Values.global.data_stream.opensearch_security_audit.retention }}"
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
                    "opensearch-security-audit"
                ],
                "priority": 2
            }
    }
}
