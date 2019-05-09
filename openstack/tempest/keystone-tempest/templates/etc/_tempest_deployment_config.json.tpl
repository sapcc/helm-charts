{
    "openstack": {
        "auth_url": "http://{{ if .Values.global.clusterDomain }}keystone.{{.Release.Namespace}}.svc.{{.Values.global.clusterDomain}}{{ else }}keystone.{{.Release.Namespace}}.svc.kubernetes.{{.Values.global.region}}.{{.Values.global.tld}}{{end}}:5000/v3",

        "region_name": "{{ .Values.global.region }}",
        "endpoint_type": "internal",
        "admin": {
            "username": "admin",
            "password": {{ required "A valid .Values.tempest.adminPassword required!" .Values.tempest.adminPassword | quote }},
            "user_domain_name": "tempest",
            "domain_name": "tempest",
    },
    "users": [
        {
            "username": "tempestuser1",
            "password": {{ required "A valid .Values.tempest.userPassword required!" .Values.tempest.userPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "tempest1",
            "project_domain_name": "tempest"
        },
        {
            "username": "tempestuser2",
            "password": {{ required "A valid .Values.tempest.userPassword required!" .Values.tempest.userPassword | quote }},
            "user_domain_name": "tempest",
            "project_name": "tempest2",
            "project_domain_name": "tempest"
        }
    ],
        "https_insecure": true,
        "https_cacert": ""
    }
}
