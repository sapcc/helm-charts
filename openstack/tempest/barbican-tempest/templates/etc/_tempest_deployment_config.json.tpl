{
    "openstack": {
        "auth_url": "http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{ required "Missing clusterDomain value!" .Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{required "Missing region value!" .Values.global.region}}.{{ required "Missing tld value!" .Values.global.tld}}{{end}}:5000/v3",
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
    ],
        "https_insecure": true,
        "https_cacert": ""
    }
}
