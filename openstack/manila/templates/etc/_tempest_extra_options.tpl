[auth]
use_dynamic_credentials = false
create_isolated_networks = false
test_accounts_file = /manila-etc/tempest_accounts.yaml
admin_username = admin
admin_password = {{ .Values.tempestAdminPassword }}
admin_project_name = admin
admin_domain_name = tempest
admin_domain_scope = True
default_credentials_domain_name = tempest
[share]
run_revert_to_snapshot_tests = true
run_multiple_share_replicas_tests = false
default_share_type_name = default
catalog_type = sharev2
max_api_microversion = 2.43
[identity]
auth_version = v3
