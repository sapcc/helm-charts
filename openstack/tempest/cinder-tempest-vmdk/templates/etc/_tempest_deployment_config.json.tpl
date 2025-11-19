{
    "openstack": {
        "auth_url": "http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{ required "Missing clusterDomain value!" .Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{required "Missing region value!" .Values.global.region}}.{{ required "Missing tld value!" .Values.global.tld}}{{end}}:5000/v3",
        "region_name": "{{ .Values.global.region }}",
        "endpoint_type": "internal",
        "admin": {
            "username": "nova-tempestadmin5",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "domain_name": "tempest"
    },
    "users": [
        {
            "username": "nova-tempestuser9",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest9",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser10",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest10",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser11",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest11",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser12",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest12",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser13",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest13",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser14",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest14",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser15",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest15",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser16",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest16",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser17",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest17",
            "project_domain_name": "tempest"
        },
        {
            "username": "nova-tempestuser18",
            "password": {{ .Values.tempestAdminPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "nova-tempest18",
            "project_domain_name": "tempest"
        }
    ],
        "https_insecure": true,
        "https_cacert": ""
    }
}
