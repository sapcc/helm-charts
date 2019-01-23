{
    "openstack": {
        "auth_url": "{{ .Values.global.keystone_api_endpoint_protocol_public | default "https"}}://{{include "keystone_api_endpoint_host_public" .}}/v3",
        "region_name": "{{ .Values.global.region }}",
        "endpoint_type": "internal",
        "admin": {
            "username": "neutron-tempestadmin1",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "domain_name": "tempest"
    },
    "users": [
        {
            "username": "neutron-tempestuser1",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest1",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser2",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest2",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser3",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest3",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser4",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest4",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser5",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest5",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser6",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest6",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuse7",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest7",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser8",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest8",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser9",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest9",
            "project_domain_name": "tempest"
        },
        {
            "username": "neutron-tempestuser10",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "neutron-tempest10",
            "project_domain_name": "tempest"
        }
    ],
        "https_insecure": true,
        "https_cacert": ""
    }
}
