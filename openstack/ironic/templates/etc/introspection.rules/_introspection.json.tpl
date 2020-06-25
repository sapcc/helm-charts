[
    {
        "description": "Set default IPMI credentials",
        "conditions": [
            {"op": "eq", "field": "data://auto_discovered", "value": true}
        ],
        "actions": [
            {"action": "set-attribute", "path": "driver_info/ipmi_username",
             "value": "ironic"},
            {"action": "set-attribute", "path": "driver_info/ipmi_password",
             "value": "{{ .Values.global.ipmi_password }}"}
        ]
    },
    {
        "description": "Enroll auto-discovered nodes with ipmi hardware type",
        "actions": [
            {"action": "set-attribute", "path": "driver", "value": "ipmi"}
        ],
        "conditions": [
            {"op": "eq", "field": "data://auto_discovered", "value": true}
        ]
    }
]