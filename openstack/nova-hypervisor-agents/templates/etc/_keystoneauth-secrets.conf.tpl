[cinder]
{{ include "nova.helpers.keystone_credentials" . }}

[neutron]
{{ include "nova.helpers.keystone_credentials" . }}

[keystone_authtoken]
{{ include "nova.helpers.keystone_credentials" . }}

[placement]
{{ include "nova.helpers.keystone_credentials" . }}

[service_user]
{{ include "nova.helpers.keystone_credentials" . }}
