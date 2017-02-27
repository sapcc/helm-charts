declare -x OS_AUTH_URL={{ .os_auth_url | quote }}
declare -x OS_AUTH_VERSION={{ .os_auth_version | quote }}
declare -x OS_USERNAME={{ .os_username | quote }}
declare -x OS_USER_DOMAIN_NAME={{ .os_user_domain | quote }}
declare -x OS_PROJECT_NAME={{ .os_project_name | quote }}
declare -x OS_PROJECT_DOMAIN_NAME={{ .os_project_domain | quote }}
declare -x OS_REGION_NAME={{ .os_region_name | quote }}
declare -x OS_PASSWORD={{ .os_password | quote }}
