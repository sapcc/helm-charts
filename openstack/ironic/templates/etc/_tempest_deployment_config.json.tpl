{
    "openstack": {
        "auth_url": "{{ .Values.global.keystone_api_endpoint_protocol_public | default "https"}}://{{include "keystone_api_endpoint_host_public" .}}/v3",
        "region_name": "{{ .Values.global.region }}",
        "endpoint_type": "public",
        "admin": {
            "username": "admin",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "domain_name": "tempest",
    },
    "users": [
        {
            "username": "tempestuser1",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "tempest1",
            "project_domain_name": "tempest"
        },
        {
            "username": "tempestuser2",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "tempest2",
            "project_domain_name": "tempest"
        }
    ],
        "https_insecure": true,
        "https_cacert": ""
    }
}
