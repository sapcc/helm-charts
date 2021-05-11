[dispersion]
auth_user = swift_dispersion
user_domain_name = Default
project_name = swift_dispersion
project_domain_name = cc3test
auth_key = { fromEnv: DISPERSION_PASSWORD }
auth_url = {{.Values.dispersion_auth_url}}
auth_version = 3
keystone_api_insecure = no
region_name = {{.Values.global.region}}
