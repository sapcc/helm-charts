[cinder]
username = {{ include "nova.helpers.default_service_user_username" . | include "resolve_secret" }}
password = {{ include "nova.helpers.default_service_user_password" . | include "resolve_secret" }}

[neutron]
username = {{ include "nova.helpers.default_service_user_username" . | include "resolve_secret" }}
password = {{ include "nova.helpers.default_service_user_password" . | include "resolve_secret" }}

[keystone_authtoken]
username = {{ include "nova.helpers.default_service_user_username" . | include "resolve_secret" }}
password = {{ include "nova.helpers.default_service_user_password" . | include "resolve_secret" }}

[placement]
username = {{ include "nova.helpers.default_service_user_username" . | include "resolve_secret" }}
password = {{ include "nova.helpers.default_service_user_password" . | include "resolve_secret" }}

[service_user]
username = {{ include "nova.helpers.default_service_user_username" . | include "resolve_secret" }}
password = {{ include "nova.helpers.default_service_user_password" . | include "resolve_secret" }}
