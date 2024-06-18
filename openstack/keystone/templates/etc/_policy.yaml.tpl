#"admin_required": "role:admin"
"admin_required": "role:admin"

#"service_role": "role:service"
"service_role": "role:service"

#"service_or_admin": "rule:admin_required or rule:service_role"
"service_or_admin": "rule:admin_required or rule:service_role"

#"owner": "user_id:%(user_id)s"
"owner": "user_id:%(user_id)s"

#"admin_or_owner": "rule:admin_required or rule:owner"

#"token_subject": "user_id:%(target.token.user_id)s"
"token_subject": "user_id:%(target.token.user_id)s"

#"admin_or_token_subject": "rule:admin_required or rule:token_subject"

#"service_admin_or_token_subject": "rule:service_or_admin or rule:token_subject"

# ccloud: added these to allow a smooth transitioning from old cloud-admin to new system scopes
"cloud_admin": "(role:admin and system_scope:all) or
  (role:admin and ((is_admin_project:True or domain_id:default){{- if .Values.tempest.enabled }} or domain_id:{{.Values.tempest.domainId}}{{- end}}))"

"cloud_reader": "(role:reader and system_scope:all) or
  role:cloud_identity_viewer or
  rule:service_role or
  rule:cloud_admin"

"blocklist_roles": "'resource_service':%(target.role.name)s or
  'cloud_registry_admin':%(target.role.name)s or
  'cloud_registry_viewer':%(target.role.name)s or
  'cloud_dns_resource_admin':%(target.role.name)s or
  'cloud_resource_admin':%(target.role.name)s or
  'cloud_resource_viewer':%(target.role.name)s or
  'cloud_baremetal_admin':%(target.role.name)s or
  'cloud_network_admin':%(target.role.name)s or
  'cloud_dns_admin':%(target.role.name)s or
  'cloud_dns_viewer':%(target.role.name)s or
  'dns_admin':%(target.role.name)s or
  'dns_hostmaster':%(target.role.name)s or
  'dns_zonemaster':%(target.role.name)s or
  'dns_mailmaster':%(target.role.name)s or
  'cloud_image_admin':%(target.role.name)s or
  'cloud_compute_admin':%(target.role.name)s or
  'cloud_keymanager_admin':%(target.role.name)s or
  'cloud_volume_admin':%(target.role.name)s or
  'cloud_sharedfilesystem_admin':%(target.role.name)s or
  'cloud_sharedfilesystem_editor':%(target.role.name)s or
  'cloud_sharedfilesystem_viewer':%(target.role.name)s or
  'cloud_objectstore_admin':%(target.role.name)s or
  'cloud_objectstore_viewer':%(target.role.name)s or
  'service':%(target.role.name)s or
  'cloud_identity_viewer':%(target.role.name)s or
  'cloud_support_tools_viewer':%(target.role.name)s or
  'cloud_email_admin':%(target.role.name)s or
  'cloud_inventory_viewer':%(target.role.name)s"

"blocklist_projects": "'{{required ".Values.api.cloudAdminProjectId is missing" .Values.api.cloudAdminProjectId}}':%(target.project.id)s"

# Show access rule details.
# GET  /v3/users/{user_id}/access_rules/{access_rule_id}
# HEAD  /v3/users/{user_id}/access_rules/{access_rule_id}
# Intended scope(s): system, project
#"identity:get_access_rule": "(role:reader and system_scope:all) or user_id:%(target.user.id)s"
"identity:get_access_rule": "rule:cloud_reader or user_id:%(target.user.id)s"

# List access rules for a user.
# GET  /v3/users/{user_id}/access_rules
# HEAD  /v3/users/{user_id}/access_rules
# Intended scope(s): system, project
#"identity:list_access_rules": "(role:reader and system_scope:all) or user_id:%(target.user.id)s"
"identity:list_access_rules": "rule:cloud_reader or user_id:%(target.user.id)s"

# Delete an access_rule.
# DELETE  /v3/users/{user_id}/access_rules/{access_rule_id}
# Intended scope(s): system, project
#"identity:delete_access_rule": "(role:admin and system_scope:all) or user_id:%(target.user.id)s"
"identity:delete_access_rule": "rule:cloud_admin or user_id:%(target.user.id)s"

# Authorize OAUTH1 request token.
# PUT  /v3/OS-OAUTH1/authorize/{request_token_id}
# Intended scope(s): project
#"identity:authorize_request_token": "rule:admin_required"
"identity:authorize_request_token": "rule:cloud_admin"

# Get OAUTH1 access token for user by access token ID.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}
# Intended scope(s): project
#"identity:get_access_token": "rule:admin_required"
"identity:get_access_token": "rule:cloud_admin"

# Get role for user OAUTH1 access token.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}/roles/{role_id}
# Intended scope(s): project
#"identity:get_access_token_role": "rule:admin_required"
"identity:get_access_token_role": "rule:cloud_admin"

# List OAUTH1 access tokens for user.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens
# Intended scope(s): project
#"identity:list_access_tokens": "rule:admin_required"
"identity:list_access_tokens": "rule:cloud_admin"

# List OAUTH1 access token roles.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}/roles
# Intended scope(s): project
#"identity:list_access_token_roles": "rule:admin_required"
"identity:list_access_token_roles": "rule:cloud_admin"

# Delete OAUTH1 access token.
# DELETE  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}
# Intended scope(s): project
#"identity:delete_access_token": "rule:admin_required"
"identity:delete_access_token": "rule:cloud_admin"

# Show application credential details.
# GET  /v3/users/{user_id}/application_credentials/{application_credential_id}
# HEAD  /v3/users/{user_id}/application_credentials/{application_credential_id}
# Intended scope(s): system, project
#"identity:get_application_credential": "(role:reader and system_scope:all) or rule:owner"
"identity:get_application_credential": "rule:cloud_reader or rule:owner"

"identity:get_application_credentials": "rule:identity:get_application_credential"
# List application credentials for a user.
# GET  /v3/users/{user_id}/application_credentials
# HEAD  /v3/users/{user_id}/application_credentials
# Intended scope(s): system, project
#"identity:list_application_credentials": "(role:reader and system_scope:all) or rule:owner"
"identity:list_application_credentials": "rule:cloud_reader or rule:owner"

# Create an application credential.
# POST  /v3/users/{user_id}/application_credentials
# Intended scope(s): project
#"identity:create_application_credential": "user_id:%(user_id)s"

# Delete an application credential.
# DELETE  /v3/users/{user_id}/application_credentials/{application_credential_id}
# Intended scope(s): system, project
#"identity:delete_application_credential": "(role:admin and system_scope:all) or rule:owner"
"identity:delete_application_credential": "rule:cloud_admin or rule:owner"

"identity:delete_application_credentials": "rule:identity:delete_application_credential"
# Get service catalog.
# GET  /v3/auth/catalog
# HEAD  /v3/auth/catalog
#"identity:get_auth_catalog": ""

# List all projects a user has access to via role assignments.
# GET  /v3/auth/projects
# HEAD  /v3/auth/projects
#"identity:get_auth_projects": ""

# List all domains a user has access to via role assignments.
# GET  /v3/auth/domains
# HEAD  /v3/auth/domains
#"identity:get_auth_domains": ""

# List systems a user has access to via role assignments.
# GET  /v3/auth/system
# HEAD  /v3/auth/system
#"identity:get_auth_system": ""

# Show OAUTH1 consumer details.
# GET  /v3/OS-OAUTH1/consumers/{consumer_id}
# Intended scope(s): system
#"identity:get_consumer": "role:reader and system_scope:all"
"identity:get_consumer": "rule:cloud_reader"

# List OAUTH1 consumers.
# GET  /v3/OS-OAUTH1/consumers
# Intended scope(s): system
#"identity:list_consumers": "role:reader and system_scope:all"
"identity:list_consumers": "rule:cloud_reader"

# Create OAUTH1 consumer.
# POST  /v3/OS-OAUTH1/consumers
# Intended scope(s): system
#"identity:create_consumer": "role:admin and system_scope:all"
"identity:create_consumer": "rule:cloud_admin"

# Update OAUTH1 consumer.
# PATCH  /v3/OS-OAUTH1/consumers/{consumer_id}
# Intended scope(s): system
#"identity:update_consumer": "role:admin and system_scope:all"
"identity:update_consumer": "rule:cloud_admin"

# Delete OAUTH1 consumer.
# DELETE  /v3/OS-OAUTH1/consumers/{consumer_id}
# Intended scope(s): system
#"identity:delete_consumer": "role:admin and system_scope:all"
"identity:delete_consumer": "rule:cloud_admin"

# Show credentials details.
# GET  /v3/credentials/{credential_id}
# Intended scope(s): system, project
#"identity:get_credential": "(role:reader and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:get_credential": "rule:cloud_reader or user_id:%(target.credential.user_id)s"

# List credentials.
# GET  /v3/credentials
# Intended scope(s): system, project
#"identity:list_credentials": "(role:reader and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:list_credentials": "rule:cloud_reader or user_id:%(target.credential.user_id)s"

# Create credential.
# POST  /v3/credentials
# Intended scope(s): system, project
#"identity:create_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:create_credential": "rule:cloud_admin or (user_id:%(target.credential.user_id)s and project_id:%(target.credential.project_id)s)"

# Update credential.
# PATCH  /v3/credentials/{credential_id}
# Intended scope(s): system, project
#"identity:update_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:update_credential": "rule:cloud_admin"

# Delete credential.
# DELETE  /v3/credentials/{credential_id}
# Intended scope(s): system, project
#"identity:delete_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:delete_credential": "rule:cloud_admin or user_id:%(target.credential.user_id)s"

# Show domain details.
# GET  /v3/domains/{domain_id}
# Intended scope(s): system, domain, project
#"identity:get_domain": "(role:reader and system_scope:all) or token.domain.id:%(target.domain.id)s or token.project.domain.id:%(target.domain.id)s"
"identity:get_domain": "rule:cloud_reader or
  token.domain.id:%(target.domain.id)s or
  token.project.domain.id:%(target.domain.id)s or
  role:role_viewer"

# List domains.
# GET  /v3/domains
# Intended scope(s): system
#"identity:list_domains": "role:reader and system_scope:all"
"identity:list_domains": "rule:cloud_reader or role:role_viewer"

# Create domain.
# POST  /v3/domains
# Intended scope(s): system
#"identity:create_domain": "role:admin and system_scope:all"
"identity:create_domain": "rule:cloud_admin"

# Update domain.
# PATCH  /v3/domains/{domain_id}
# Intended scope(s): system
#"identity:update_domain": "role:admin and system_scope:all"
"identity:update_domain": "rule:cloud_admin"

# Delete domain.
# DELETE  /v3/domains/{domain_id}
# Intended scope(s): system
#"identity:delete_domain": "role:admin and system_scope:all"
"identity:delete_domain": "rule:cloud_admin"

# Create domain configuration.
# PUT  /v3/domains/{domain_id}/config
# Intended scope(s): system
#"identity:create_domain_config": "role:admin and system_scope:all"
"identity:create_domain_config": "rule:cloud_admin"

# Get the entire domain configuration for a domain, an option group
# within a domain, or a specific configuration option within a group
# for a domain.
# GET  /v3/domains/{domain_id}/config
# HEAD  /v3/domains/{domain_id}/config
# GET  /v3/domains/{domain_id}/config/{group}
# HEAD  /v3/domains/{domain_id}/config/{group}
# GET  /v3/domains/{domain_id}/config/{group}/{option}
# HEAD  /v3/domains/{domain_id}/config/{group}/{option}
# Intended scope(s): system
#"identity:get_domain_config": "role:reader and system_scope:all"
"identity:get_domain_config": "rule:cloud_reader"

# Get security compliance domain configuration for either a domain or
# a specific option in a domain.
# GET  /v3/domains/{domain_id}/config/security_compliance
# HEAD  /v3/domains/{domain_id}/config/security_compliance
# GET  v3/domains/{domain_id}/config/security_compliance/{option}
# HEAD  v3/domains/{domain_id}/config/security_compliance/{option}
# Intended scope(s): system, domain, project
#"identity:get_security_compliance_domain_config": ""

# Update domain configuration for either a domain, specific group or a
# specific option in a group.
# PATCH  /v3/domains/{domain_id}/config
# PATCH  /v3/domains/{domain_id}/config/{group}
# PATCH  /v3/domains/{domain_id}/config/{group}/{option}
# Intended scope(s): system
#"identity:update_domain_config": "role:admin and system_scope:all"
"identity:update_domain_config": "rule:cloud_admin"

# Delete domain configuration for either a domain, specific group or a
# specific option in a group.
# DELETE  /v3/domains/{domain_id}/config
# DELETE  /v3/domains/{domain_id}/config/{group}
# DELETE  /v3/domains/{domain_id}/config/{group}/{option}
# Intended scope(s): system
#"identity:delete_domain_config": "role:admin and system_scope:all"
"identity:delete_domain_config": "rule:cloud_admin"

# Get domain configuration default for either a domain, specific group
# or a specific option in a group.
# GET  /v3/domains/config/default
# HEAD  /v3/domains/config/default
# GET  /v3/domains/config/{group}/default
# HEAD  /v3/domains/config/{group}/default
# GET  /v3/domains/config/{group}/{option}/default
# HEAD  /v3/domains/config/{group}/{option}/default
# Intended scope(s): system
#"identity:get_domain_config_default": "role:reader and system_scope:all"
"identity:get_domain_config_default": "rule:cloud_reader"

# Show ec2 credential details.
# GET  /v3/users/{user_id}/credentials/OS-EC2/{credential_id}
# Intended scope(s): system, project
#"identity:ec2_get_credential": "(role:reader and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:ec2_get_credential": "rule:cloud_reader or user_id:%(target.credential.user_id)s"

# List ec2 credentials.
# GET  /v3/users/{user_id}/credentials/OS-EC2
# Intended scope(s): system, project
#"identity:ec2_list_credentials": "(role:reader and system_scope:all) or rule:owner"
"identity:ec2_list_credentials": "rule:cloud_reader or rule:owner"

# Create ec2 credential.
# POST  /v3/users/{user_id}/credentials/OS-EC2
# Intended scope(s): system, project
#"identity:ec2_create_credential": "(role:admin and system_scope:all) or rule:owner"
"identity:ec2_create_credential": "rule:cloud_admin or (user_id:%(target.credential.user_id)s and project_id:%(target.credential.project_id)s)"

"identity:ec2_create_credentials": "rule:identity:ec2_create_credential"
# Delete ec2 credential.
# DELETE  /v3/users/{user_id}/credentials/OS-EC2/{credential_id}
# Intended scope(s): system, project
#"identity:ec2_delete_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"
"identity:ec2_delete_credential": "rule:cloud_admin or user_id:%(target.credential.user_id)s"

"identity:ec2_delete_credentials": "rule:identity:ec2_delete_credential"
# Show endpoint details.
# GET  /v3/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:get_endpoint": "role:reader and system_scope:all"
"identity:get_endpoint": "rule:cloud_reader"

# List endpoints.
# GET  /v3/endpoints
# Intended scope(s): system
#"identity:list_endpoints": "role:reader and system_scope:all"
"identity:list_endpoints": "rule:cloud_reader"

# Create endpoint.
# POST  /v3/endpoints
# Intended scope(s): system
#"identity:create_endpoint": "role:admin and system_scope:all"
"identity:create_endpoint": "rule:cloud_admin"

# Update endpoint.
# PATCH  /v3/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:update_endpoint": "role:admin and system_scope:all"
"identity:update_endpoint": "rule:cloud_admin"

# Delete endpoint.
# DELETE  /v3/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:delete_endpoint": "role:admin and system_scope:all"
"identity:delete_endpoint": "rule:cloud_admin"

# Create endpoint group.
# POST  /v3/OS-EP-FILTER/endpoint_groups
# Intended scope(s): system
#"identity:create_endpoint_group": "role:admin and system_scope:all"
"identity:create_endpoint_group": "rule:cloud_admin"

# List endpoint groups.
# GET  /v3/OS-EP-FILTER/endpoint_groups
# Intended scope(s): system
#"identity:list_endpoint_groups": "role:reader and system_scope:all"
"identity:list_endpoint_groups": "rule:cloud_reader"

# Get endpoint group.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# HEAD  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# Intended scope(s): system
#"identity:get_endpoint_group": "role:reader and system_scope:all"
"identity:get_endpoint_group": "rule:cloud_reader"

# Update endpoint group.
# PATCH  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# Intended scope(s): system
#"identity:update_endpoint_group": "role:admin and system_scope:all"
"identity:update_endpoint_group": "rule:cloud_admin"

# Delete endpoint group.
# DELETE  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# Intended scope(s): system
#"identity:delete_endpoint_group": "role:admin and system_scope:all"
"identity:delete_endpoint_group": "rule:cloud_admin"

# List all projects associated with a specific endpoint group.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects
# Intended scope(s): system
#"identity:list_projects_associated_with_endpoint_group": "role:reader and system_scope:all"
"identity:list_projects_associated_with_endpoint_group": "rule:cloud_reader"

# List all endpoints associated with an endpoint group.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/endpoints
# Intended scope(s): system
#"identity:list_endpoints_associated_with_endpoint_group": "role:reader and system_scope:all"
"identity:list_endpoints_associated_with_endpoint_group": "rule:cloud_reader"

# Check if an endpoint group is associated with a project.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# HEAD  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# Intended scope(s): system
#"identity:get_endpoint_group_in_project": "role:reader and system_scope:all"
"identity:get_endpoint_group_in_project": "rule:cloud_reader"

# List endpoint groups associated with a specific project.
# GET  /v3/OS-EP-FILTER/projects/{project_id}/endpoint_groups
# Intended scope(s): system
#"identity:list_endpoint_groups_for_project": "role:reader and system_scope:all"
"identity:list_endpoint_groups_for_project": "rule:cloud_reader"

# Allow a project to access an endpoint group.
# PUT  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# Intended scope(s): system
#"identity:add_endpoint_group_to_project": "role:admin and system_scope:all"
"identity:add_endpoint_group_to_project": "rule:cloud_admin"

# Remove endpoint group from project.
# DELETE  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# Intended scope(s): system
#"identity:remove_endpoint_group_from_project": "role:admin and system_scope:all"
"identity:remove_endpoint_group_from_project": "rule:cloud_admin"

# grant-specific rules
"domain_admin_for_grants": "(rule:domain_admin_for_global_role_grants or rule:domain_admin_for_domain_role_grants) and not rule:blocklist_roles and not rule:blocklist_projects"
"domain_admin_for_global_role_grants": "rule:admin_required and None:%(target.role.domain_id)s and rule:domain_admin_grant_match"
"domain_admin_for_domain_role_grants": "rule:admin_required and domain_id:%(target.role.domain_id)s and rule:domain_admin_grant_match"
"domain_admin_grant_match": "domain_id:%(domain_id)s or domain_id:%(target.project.domain_id)s"
"project_admin_for_grants": "(rule:project_admin_for_global_role_grants or rule:project_admin_for_domain_role_grants) and not rule:blocklist_roles and not rule:blocklist_projects"
"project_admin_for_global_role_grants": "(rule:admin_required or role:role_admin) and None:%(target.role.domain_id)s and (project_id:%(project_id)s or project_id:%(target.project.parent_id)s)"
"project_admin_for_domain_role_grants": "(rule:admin_required or role:role_admin) and project_domain_id:%(target.role.domain_id)s and (project_id:%(project_id)s or project_id:%(target.project.parent_id)s)"
"domain_admin_for_list_grants": "rule:admin_required and rule:domain_admin_grant_match"
"project_admin_for_list_grants": "(rule:admin_required or role:role_admin or role:role_viewer) and (project_id:%(project_id)s or project_id:%(target.project.parent_id)s)"

# Check a role grant between a target and an actor. A target can be
# either a domain or a project. An actor can be either a user or a
# group. These terms also apply to the OS-INHERIT APIs, where grants
# on the target are inherited to all projects in the subtree, if
# applicable.
# HEAD  /v3/projects/{project_id}/users/{user_id}/roles/{role_id}
# GET  /v3/projects/{project_id}/users/{user_id}/roles/{role_id}
# HEAD  /v3/projects/{project_id}/groups/{group_id}/roles/{role_id}
# GET  /v3/projects/{project_id}/groups/{group_id}/roles/{role_id}
# HEAD  /v3/domains/{domain_id}/users/{user_id}/roles/{role_id}
# GET  /v3/domains/{domain_id}/users/{user_id}/roles/{role_id}
# HEAD  /v3/domains/{domain_id}/groups/{group_id}/roles/{role_id}
# GET  /v3/domains/{domain_id}/groups/{group_id}/roles/{role_id}
# HEAD  /v3/OS-INHERIT/projects/{project_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# GET  /v3/OS-INHERIT/projects/{project_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# HEAD  /v3/OS-INHERIT/projects/{project_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# GET  /v3/OS-INHERIT/projects/{project_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# HEAD  /v3/OS-INHERIT/domains/{domain_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# GET  /v3/OS-INHERIT/domains/{domain_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# HEAD  /v3/OS-INHERIT/domains/{domain_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# GET  /v3/OS-INHERIT/domains/{domain_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# Intended scope(s): system, domain
#"identity:check_grant": "(role:reader and system_scope:all) or ((role:reader and domain_id:%(target.user.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:reader and domain_id:%(target.user.domain_id)s and domain_id:%(target.domain.id)s) or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.domain.id)s)) and (domain_id:%(target.role.domain_id)s or None:%(target.role.domain_id)s)"
"identity:check_grant": "rule:cloud_admin or rule:domain_admin_for_grants or rule:project_admin_for_grants"

# List roles granted to an actor on a target. A target can be either a
# domain or a project. An actor can be either a user or a group. For
# the OS-INHERIT APIs, it is possible to list inherited role grants
# for actors on domains, where grants are inherited to all projects in
# the specified domain.
# GET  /v3/projects/{project_id}/users/{user_id}/roles
# HEAD  /v3/projects/{project_id}/users/{user_id}/roles
# GET  /v3/projects/{project_id}/groups/{group_id}/roles
# HEAD  /v3/projects/{project_id}/groups/{group_id}/roles
# GET  /v3/domains/{domain_id}/users/{user_id}/roles
# HEAD  /v3/domains/{domain_id}/users/{user_id}/roles
# GET  /v3/domains/{domain_id}/groups/{group_id}/roles
# HEAD  /v3/domains/{domain_id}/groups/{group_id}/roles
# GET  /v3/OS-INHERIT/domains/{domain_id}/groups/{group_id}/roles/inherited_to_projects
# GET  /v3/OS-INHERIT/domains/{domain_id}/users/{user_id}/roles/inherited_to_projects
# Intended scope(s): system, domain
#"identity:list_grants": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.user.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:reader and domain_id:%(target.user.domain_id)s and domain_id:%(target.domain.id)s) or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.domain.id)s)"
"identity:list_grants": "rule:cloud_admin or rule:domain_admin_for_list_grants or rule:project_admin_for_list_grants"

# Create a role grant between a target and an actor. A target can be
# either a domain or a project. An actor can be either a user or a
# group. These terms also apply to the OS-INHERIT APIs, where grants
# on the target are inherited to all projects in the subtree, if
# applicable.
# PUT  /v3/projects/{project_id}/users/{user_id}/roles/{role_id}
# PUT  /v3/projects/{project_id}/groups/{group_id}/roles/{role_id}
# PUT  /v3/domains/{domain_id}/users/{user_id}/roles/{role_id}
# PUT  /v3/domains/{domain_id}/groups/{group_id}/roles/{role_id}
# PUT  /v3/OS-INHERIT/projects/{project_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# PUT  /v3/OS-INHERIT/projects/{project_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# PUT  /v3/OS-INHERIT/domains/{domain_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# PUT  /v3/OS-INHERIT/domains/{domain_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# Intended scope(s): system, domain
#"identity:create_grant": "(role:admin and system_scope:all) or ((role:admin and domain_id:%(target.user.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:admin and domain_id:%(target.user.domain_id)s and domain_id:%(target.domain.id)s) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.domain.id)s)) and (domain_id:%(target.role.domain_id)s or None:%(target.role.domain_id)s)"
"identity:create_grant": "rule:cloud_admin or rule:domain_admin_for_grants or rule:project_admin_for_grants"

# Revoke a role grant between a target and an actor. A target can be
# either a domain or a project. An actor can be either a user or a
# group. These terms also apply to the OS-INHERIT APIs, where grants
# on the target are inherited to all projects in the subtree, if
# applicable. In that case, revoking the role grant in the target
# would remove the logical effect of inheriting it to the target's
# projects subtree.
# DELETE  /v3/projects/{project_id}/users/{user_id}/roles/{role_id}
# DELETE  /v3/projects/{project_id}/groups/{group_id}/roles/{role_id}
# DELETE  /v3/domains/{domain_id}/users/{user_id}/roles/{role_id}
# DELETE  /v3/domains/{domain_id}/groups/{group_id}/roles/{role_id}
# DELETE  /v3/OS-INHERIT/projects/{project_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# DELETE  /v3/OS-INHERIT/projects/{project_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# DELETE  /v3/OS-INHERIT/domains/{domain_id}/users/{user_id}/roles/{role_id}/inherited_to_projects
# DELETE  /v3/OS-INHERIT/domains/{domain_id}/groups/{group_id}/roles/{role_id}/inherited_to_projects
# Intended scope(s): system, domain
#"identity:revoke_grant": "(role:admin and system_scope:all) or ((role:admin and domain_id:%(target.user.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:admin and domain_id:%(target.user.domain_id)s and domain_id:%(target.domain.id)s) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.project.domain_id)s) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.domain.id)s)) and (domain_id:%(target.role.domain_id)s or None:%(target.role.domain_id)s)"
"identity:revoke_grant": "rule:cloud_admin or rule:domain_admin_for_grants or rule:project_admin_for_grants"

# List all grants a specific user has on the system.
# ['HEAD', 'GET']  /v3/system/users/{user_id}/roles
# Intended scope(s): system
#"identity:list_system_grants_for_user": "role:reader and system_scope:all"
"identity:list_system_grants_for_user": "rule:cloud_reader"

# Check if a user has a role on the system.
# ['HEAD', 'GET']  /v3/system/users/{user_id}/roles/{role_id}
# Intended scope(s): system
#"identity:check_system_grant_for_user": "role:reader and system_scope:all"
"identity:check_system_grant_for_user": "rule:cloud_reader"

# Grant a user a role on the system.
# ['PUT']  /v3/system/users/{user_id}/roles/{role_id}
# Intended scope(s): system
#"identity:create_system_grant_for_user": "role:admin and system_scope:all"
"identity:create_system_grant_for_user": "rule:cloud_admin"

# Remove a role from a user on the system.
# ['DELETE']  /v3/system/users/{user_id}/roles/{role_id}
# Intended scope(s): system
#"identity:revoke_system_grant_for_user": "role:admin and system_scope:all"
"identity:revoke_system_grant_for_user": "rule:cloud_admin"

# List all grants a specific group has on the system.
# ['HEAD', 'GET']  /v3/system/groups/{group_id}/roles
# Intended scope(s): system
#"identity:list_system_grants_for_group": "role:reader and system_scope:all"
"identity:list_system_grants_for_group": "rule:cloud_reader"

# Check if a group has a role on the system.
# ['HEAD', 'GET']  /v3/system/groups/{group_id}/roles/{role_id}
# Intended scope(s): system
#"identity:check_system_grant_for_group": "role:reader and system_scope:all"
"identity:check_system_grant_for_group": "rule:cloud_reader"

# Grant a group a role on the system.
# ['PUT']  /v3/system/groups/{group_id}/roles/{role_id}
# Intended scope(s): system
#"identity:create_system_grant_for_group": "role:admin and system_scope:all"
"identity:create_system_grant_for_group": "rule:cloud_admin"

# Remove a role from a group on the system.
# ['DELETE']  /v3/system/groups/{group_id}/roles/{role_id}
# Intended scope(s): system
#"identity:revoke_system_grant_for_group": "role:admin and system_scope:all"
"identity:revoke_system_grant_for_group": "rule:cloud_admin"

# Show group details.
# GET  /v3/groups/{group_id}
# HEAD  /v3/groups/{group_id}
# Intended scope(s): system, domain
#"identity:get_group": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s)"
"identity:get_group": "rule:cloud_reader or
  (role:reader and domain_id:%(target.group.domain_id)s) or
  role:role_viewer"

# List groups.
# GET  /v3/groups
# HEAD  /v3/groups
# Intended scope(s): system, domain
#"identity:list_groups": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s)"
"identity:list_groups": "rule:cloud_reader or
  (role:reader and (domain_id:%(target.group.domain_id)s or domain_id:%(domain_id)s)) or
  (role:role_viewer and (project_domain_id:%(domain_id)s) or project_domain_id:%(target.group.domain_id)s)"

# List groups to which a user belongs.
# GET  /v3/users/{user_id}/groups
# HEAD  /v3/users/{user_id}/groups
# Intended scope(s): system, domain, project
#"identity:list_groups_for_user": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.user.domain_id)s) or user_id:%(user_id)s"
"identity:list_groups_for_user": "rule:cloud_reader or
  (role:reader and domain_id:%(target.user.domain_id)s) or
  user_id:%(user_id)s"

# Create group.
# POST  /v3/groups
# Intended scope(s): system, domain
#"identity:create_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s)"
"identity:create_group": "rule:cloud_admin or (role:admin and domain_id:%(target.group.domain_id)s)"

# Update group.
# PATCH  /v3/groups/{group_id}
# Intended scope(s): system, domain
#"identity:update_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s)"
"identity:update_group": "rule:cloud_admin or (role:admin and domain_id:%(target.group.domain_id)s)"

# Delete group.
# DELETE  /v3/groups/{group_id}
# Intended scope(s): system, domain
#"identity:delete_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s)"
"identity:delete_group": "rule:cloud_admin"

# List members of a specific group.
# GET  /v3/groups/{group_id}/users
# HEAD  /v3/groups/{group_id}/users
# Intended scope(s): system, domain
#"identity:list_users_in_group": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s)"
"identity:list_users_in_group": "rule:cloud_reader or (role:reader and domain_id:%(target.group.domain_id)s)"

# Remove user from group.
# DELETE  /v3/groups/{group_id}/users/{user_id}
# Intended scope(s): system, domain
#"identity:remove_user_from_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"
"identity:remove_user_from_group": "rule:cloud_admin or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"

# Check whether a user is a member of a group.
# HEAD  /v3/groups/{group_id}/users/{user_id}
# GET  /v3/groups/{group_id}/users/{user_id}
# Intended scope(s): system, domain
#"identity:check_user_in_group": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"
"identity:check_user_in_group": "rule:cloud_reader or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"

# Add user to group.
# PUT  /v3/groups/{group_id}/users/{user_id}
# Intended scope(s): system, domain
#"identity:add_user_to_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"
"identity:add_user_to_group": "rule:cloud_admin or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"

# Create identity provider.
# PUT  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
#"identity:create_identity_provider": "role:admin and system_scope:all"
"identity:create_identity_provider": "rule:cloud_admin"

"identity:create_identity_providers": "rule:identity:create_identity_provider"
# List identity providers.
# GET  /v3/OS-FEDERATION/identity_providers
# HEAD  /v3/OS-FEDERATION/identity_providers
# Intended scope(s): system
#"identity:list_identity_providers": "role:reader and system_scope:all"
"identity:list_identity_providers": "rule:cloud_reader"

# Get identity provider.
# GET  /v3/OS-FEDERATION/identity_providers/{idp_id}
# HEAD  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
#"identity:get_identity_provider": "role:reader and system_scope:all"
"identity:get_identity_provider": "rule:cloud_reader"

"identity:get_identity_providers": "rule:identity:get_identity_provider"
# Update identity provider.
# PATCH  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
#"identity:update_identity_provider": "role:admin and system_scope:all"
"identity:update_identity_provider": "rule:cloud_admin"

"identity:update_identity_providers": "rule:identity:update_identity_provider"
# Delete identity provider.
# DELETE  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
#"identity:delete_identity_provider": "role:admin and system_scope:all"
"identity:delete_identity_provider": "rule:cloud_admin"

"identity:delete_identity_providers": "rule:identity:delete_identity_provider"
# Get information about an association between two roles. When a
# relationship exists between a prior role and an implied role and the
# prior role is assigned to a user, the user also assumes the implied
# role.
# GET  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:get_implied_role": "role:reader and system_scope:all"
"identity:get_implied_role": "rule:cloud_reader"

# List associations between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role. This
# will return all the implied roles that would be assumed by the user
# who gets the specified prior role.
# GET  /v3/roles/{prior_role_id}/implies
# HEAD  /v3/roles/{prior_role_id}/implies
# Intended scope(s): system
#"identity:list_implied_roles": "role:reader and system_scope:all"
"identity:list_implied_roles": "rule:cloud_reader"

# Create an association between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role.
# PUT  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:create_implied_role": "role:admin and system_scope:all"
"identity:create_implied_role": "rule:cloud_admin"

# Delete the association between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role. Removing
# the association will cause that effect to be eliminated.
# DELETE  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:delete_implied_role": "role:admin and system_scope:all"
"identity:delete_implied_role": "rule:cloud_admin"

# List all associations between two roles in the system. When a
# relationship exists between a prior role and an implied role and the
# prior role is assigned to a user, the user also assumes the implied
# role.
# GET  /v3/role_inferences
# HEAD  /v3/role_inferences
# Intended scope(s): system
#"identity:list_role_inference_rules": "role:reader and system_scope:all"
"identity:list_role_inference_rules": "rule:cloud_reader or role:role_viewer"

# Check an association between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role.
# HEAD  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:check_implied_role": "role:reader and system_scope:all"
"identity:check_implied_role": "rule:cloud_reader or role:role_viewer"

# Get limit enforcement model.
# GET  /v3/limits/model
# HEAD  /v3/limits/model
# Intended scope(s): system, domain, project
#"identity:get_limit_model": ""

# Show limit details.
# GET  /v3/limits/{limit_id}
# HEAD  /v3/limits/{limit_id}
# Intended scope(s): system, domain, project
#"identity:get_limit": "(role:reader and system_scope:all) or (domain_id:%(target.limit.domain.id)s or domain_id:%(target.limit.project.domain_id)s) or (project_id:%(target.limit.project_id)s and not None:%(target.limit.project_id)s)"
"identity:get_limit": "rule:cloud_reader or
  (domain_id:%(target.limit.domain.id)s or domain_id:%(target.limit.project.domain_id)s) or
  (project_id:%(target.limit.project_id)s and not None:%(target.limit.project_id)s)"

# List limits.
# GET  /v3/limits
# HEAD  /v3/limits
# Intended scope(s): system, domain, project
#"identity:list_limits": ""

# Create limits.
# POST  /v3/limits
# Intended scope(s): system
#"identity:create_limits": "role:admin and system_scope:all"
"identity:create_limits": "rule:cloud_admin"

# Update limit.
# PATCH  /v3/limits/{limit_id}
# Intended scope(s): system
#"identity:update_limit": "role:admin and system_scope:all"
"identity:update_limit": "rule:cloud_admin"

# Delete limit.
# DELETE  /v3/limits/{limit_id}
# Intended scope(s): system
#"identity:delete_limit": "role:admin and system_scope:all"
"identity:delete_limit": "rule:cloud_admin"

# Create a new federated mapping containing one or more sets of rules.
# PUT  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
#"identity:create_mapping": "role:admin and system_scope:all"
"identity:create_mapping": "rule:cloud_admin"

# Get a federated mapping.
# GET  /v3/OS-FEDERATION/mappings/{mapping_id}
# HEAD  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
#"identity:get_mapping": "role:reader and system_scope:all"
"identity:get_mapping": "rule:cloud_reader"

# List federated mappings.
# GET  /v3/OS-FEDERATION/mappings
# HEAD  /v3/OS-FEDERATION/mappings
# Intended scope(s): system
#"identity:list_mappings": "role:reader and system_scope:all"
"identity:list_mappings": "rule:cloud_reader"

# Delete a federated mapping.
# DELETE  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
#"identity:delete_mapping": "role:admin and system_scope:all"
"identity:delete_mapping": "rule:cloud_admin"

# Update a federated mapping.
# PATCH  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
#"identity:update_mapping": "role:admin and system_scope:all"
"identity:update_mapping": "rule:cloud_admin"

# Show policy details.
# GET  /v3/policies/{policy_id}
# Intended scope(s): system
#"identity:get_policy": "role:reader and system_scope:all"
"identity:get_policy": "rule:cloud_reader"

# List policies.
# GET  /v3/policies
# Intended scope(s): system
#"identity:list_policies": "role:reader and system_scope:all"
"identity:list_policies": "rule:cloud_reader"

# Create policy.
# POST  /v3/policies
# Intended scope(s): system
#"identity:create_policy": "role:admin and system_scope:all"
"identity:create_policy": "rule:cloud_admin"

# Update policy.
# PATCH  /v3/policies/{policy_id}
# Intended scope(s): system
#"identity:update_policy": "role:admin and system_scope:all"
"identity:update_policy": "rule:cloud_admin"

# Delete policy.
# DELETE  /v3/policies/{policy_id}
# Intended scope(s): system
#"identity:delete_policy": "role:admin and system_scope:all"
"identity:delete_policy": "rule:cloud_admin"

# Associate a policy to a specific endpoint.
# PUT  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:create_policy_association_for_endpoint": "role:admin and system_scope:all"
"identity:create_policy_association_for_endpoint": "rule:cloud_admin"

# Check policy association for endpoint.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# HEAD  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:check_policy_association_for_endpoint": "role:reader and system_scope:all"
"identity:check_policy_association_for_endpoint": "rule:cloud_reader"

# Delete policy association for endpoint.
# DELETE  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:delete_policy_association_for_endpoint": "role:admin and system_scope:all"
"identity:delete_policy_association_for_endpoint": "rule:cloud_admin"

# Associate a policy to a specific service.
# PUT  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# Intended scope(s): system
#"identity:create_policy_association_for_service": "role:admin and system_scope:all"
"identity:create_policy_association_for_service": "rule:cloud_admin"

# Check policy association for service.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# HEAD  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# Intended scope(s): system
#"identity:check_policy_association_for_service": "role:reader and system_scope:all"
"identity:check_policy_association_for_service": "rule:cloud_reader"

# Delete policy association for service.
# DELETE  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# Intended scope(s): system
#"identity:delete_policy_association_for_service": "role:admin and system_scope:all"
"identity:delete_policy_association_for_service": "rule:cloud_admin"

# Associate a policy to a specific region and service combination.
# PUT  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# Intended scope(s): system
#"identity:create_policy_association_for_region_and_service": "role:admin and system_scope:all"
"identity:create_policy_association_for_region_and_service": "rule:cloud_admin"

# Check policy association for region and service.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# HEAD  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# Intended scope(s): system
#"identity:check_policy_association_for_region_and_service": "role:reader and system_scope:all"
"identity:check_policy_association_for_region_and_service": "rule:cloud_reader"

# Delete policy association for region and service.
# DELETE  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# Intended scope(s): system
#"identity:delete_policy_association_for_region_and_service": "role:admin and system_scope:all"
"identity:delete_policy_association_for_region_and_service": "rule:cloud_admin"

# Get policy for endpoint.
# GET  /v3/endpoints/{endpoint_id}/OS-ENDPOINT-POLICY/policy
# HEAD  /v3/endpoints/{endpoint_id}/OS-ENDPOINT-POLICY/policy
# Intended scope(s): system
#"identity:get_policy_for_endpoint": "role:reader and system_scope:all"
"identity:get_policy_for_endpoint": "rule:cloud_reader"

# List endpoints for policy.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints
# Intended scope(s): system
#"identity:list_endpoints_for_policy": "role:reader and system_scope:all"
"identity:list_endpoints_for_policy": "rule:cloud_reader"

# Show project details.
# GET  /v3/projects/{project_id}
# Intended scope(s): system, domain, project
#"identity:get_project": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"
"identity:get_project": "rule:cloud_reader or
  (role:reader and domain_id:%(target.project.domain_id)s) or
  project_id:%(target.project.id)s or
  role:role_viewer"

# List projects.
# GET  /v3/projects
# Intended scope(s): system, domain
#"identity:list_projects": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"
"identity:list_projects": "rule:cloud_reader or
  (role:reader and domain_id:%(target.domain_id)s) or
  (role:reader and project_id:%(target.parent_id)s)"

# List projects for user.
# GET  /v3/users/{user_id}/projects
# Intended scope(s): system, domain, project
#"identity:list_user_projects": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.user.domain_id)s) or user_id:%(target.user.id)s"
"identity:list_user_projects": "rule:cloud_reader or
  (role:reader and domain_id:%(target.user.domain_id)s) or
  user_id:%(target.user.id)s"

# Create project.
# POST  /v3/projects
# Intended scope(s): system, domain
#"identity:create_project": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s)"
"identity:create_project": "rule:cloud_admin or (role:admin and domain_id:%(target.project.domain_id)s) or (role:admin and project_id:%(target.project.parent_id)s)"

# Update project.
# PATCH  /v3/projects/{project_id}
# Intended scope(s): system, domain
#"identity:update_project": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s)"
"identity:update_project": "rule:cloud_admin or (role:admin and domain_id:%(target.project.domain_id)s)"

# Delete project.
# DELETE  /v3/projects/{project_id}
# Intended scope(s): system, domain
#"identity:delete_project": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s)"
# The corresponding `prodel` service details are available on GitHub under `cc/prodel`
"identity:delete_project": "(rule:cloud_admin or (rule:admin_required and (project_id:%(project_id)s or project_id:%(target.project.parent_id)s))) and ({{- if .Values.tempest.enabled }}domain_id:{{.Values.tempest.domainId}} or {{ end }}{{ .Values.prodel.url }})"

# List tags for a project.
# GET  /v3/projects/{project_id}/tags
# HEAD  /v3/projects/{project_id}/tags
# Intended scope(s): system, domain, project
#"identity:list_project_tags": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"
"identity:list_project_tags": "rule:cloud_reader or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"

# Check if project contains a tag.
# GET  /v3/projects/{project_id}/tags/{value}
# HEAD  /v3/projects/{project_id}/tags/{value}
# Intended scope(s): system, domain, project
#"identity:get_project_tag": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"
"identity:get_project_tag": "rule:cloud_reader or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"

# Replace all tags on a project with the new set of tags.
# PUT  /v3/projects/{project_id}/tags
# Intended scope(s): system, domain, project
#"identity:update_project_tags": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s) or (role:admin and project_id:%(target.project.id)s)"
"identity:update_project_tags": "rule:cloud_admin or rule:service_role"

# Add a single tag to a project.
# PUT  /v3/projects/{project_id}/tags/{value}
# Intended scope(s): system, domain, project
#"identity:create_project_tag": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s) or (role:admin and project_id:%(target.project.id)s)"
"identity:create_project_tag": "rule:cloud_admin or rule:service_role"

# Remove all tags from a project.
# DELETE  /v3/projects/{project_id}/tags
# Intended scope(s): system, domain, project
#"identity:delete_project_tags": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s) or (role:admin and project_id:%(target.project.id)s)"
"identity:delete_project_tags": "rule:cloud_admin or rule:service_role"

# Delete a specified tag from project.
# DELETE  /v3/projects/{project_id}/tags/{value}
# Intended scope(s): system, domain, project
#"identity:delete_project_tag": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s) or (role:admin and project_id:%(target.project.id)s)"
"identity:delete_project_tag": "rule:cloud_admin or rule:service_role"

# List projects allowed to access an endpoint.
# GET  /v3/OS-EP-FILTER/endpoints/{endpoint_id}/projects
# Intended scope(s): system
#"identity:list_projects_for_endpoint": "role:reader and system_scope:all"
"identity:list_projects_for_endpoint": "rule:cloud_reader"

# Allow project to access an endpoint.
# PUT  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:add_endpoint_to_project": "role:admin and system_scope:all"
"identity:add_endpoint_to_project": "rule:cloud_admin"

# Check if a project is allowed to access an endpoint.
# GET  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# HEAD  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:check_endpoint_in_project": "role:reader and system_scope:all"
"identity:check_endpoint_in_project": "rule:cloud_reader"

# List the endpoints a project is allowed to access.
# GET  /v3/OS-EP-FILTER/projects/{project_id}/endpoints
# Intended scope(s): system
#"identity:list_endpoints_for_project": "role:reader and system_scope:all"
"identity:list_endpoints_for_project": "rule:cloud_reader"

# Remove access to an endpoint from a project that has previously been
# given explicit access.
# DELETE  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:remove_endpoint_from_project": "role:admin and system_scope:all"
"identity:remove_endpoint_from_project": "rule:cloud_admin"

# Create federated protocol.
# PUT  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
#"identity:create_protocol": "role:admin and system_scope:all"
"identity:create_protocol": "rule:cloud_admin"

# Update federated protocol.
# PATCH  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
#"identity:update_protocol": "role:admin and system_scope:all"
"identity:update_protocol": "rule:cloud_admin"

# Get federated protocol.
# GET  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
#"identity:get_protocol": "role:reader and system_scope:all"
"identity:get_protocol": "rule:cloud_reader"

# List federated protocols.
# GET  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols
# Intended scope(s): system
#"identity:list_protocols": "role:reader and system_scope:all"
"identity:list_protocols": "rule:cloud_reader"

# Delete federated protocol.
# DELETE  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
#"identity:delete_protocol": "role:admin and system_scope:all"
"identity:delete_protocol": "rule:cloud_admin"

# Show region details.
# GET  /v3/regions/{region_id}
# HEAD  /v3/regions/{region_id}
# Intended scope(s): system, domain, project
#"identity:get_region": ""

# List regions.
# GET  /v3/regions
# HEAD  /v3/regions
# Intended scope(s): system, domain, project
#"identity:list_regions": ""

# Create region.
# POST  /v3/regions
# PUT  /v3/regions/{region_id}
# Intended scope(s): system
#"identity:create_region": "role:admin and system_scope:all"
"identity:create_region": "rule:cloud_admin"

# Update region.
# PATCH  /v3/regions/{region_id}
# Intended scope(s): system
#"identity:update_region": "role:admin and system_scope:all"
"identity:update_region": "rule:cloud_admin"

# Delete region.
# DELETE  /v3/regions/{region_id}
# Intended scope(s): system
#"identity:delete_region": "role:admin and system_scope:all"
"identity:delete_region": "rule:cloud_admin"

# Show registered limit details.
# GET  /v3/registered_limits/{registered_limit_id}
# HEAD  /v3/registered_limits/{registered_limit_id}
# Intended scope(s): system, domain, project
#"identity:get_registered_limit": ""

# List registered limits.
# GET  /v3/registered_limits
# HEAD  /v3/registered_limits
# Intended scope(s): system, domain, project
#"identity:list_registered_limits": ""

# Create registered limits.
# POST  /v3/registered_limits
# Intended scope(s): system
#"identity:create_registered_limits": "role:admin and system_scope:all"
"identity:create_registered_limits": "rule:cloud_admin"

# Update registered limit.
# PATCH  /v3/registered_limits/{registered_limit_id}
# Intended scope(s): system
#"identity:update_registered_limit": "role:admin and system_scope:all"
"identity:update_registered_limit": "rule:cloud_admin"

# Delete registered limit.
# DELETE  /v3/registered_limits/{registered_limit_id}
# Intended scope(s): system
#"identity:delete_registered_limit": "role:admin and system_scope:all"
"identity:delete_registered_limit": "rule:cloud_admin"

# List revocation events.
# GET  /v3/OS-REVOKE/events
# Intended scope(s): system
#"identity:list_revoke_events": "rule:service_or_admin"

# Show role details.
# GET  /v3/roles/{role_id}
# HEAD  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:get_role": "role:reader and system_scope:all"
"identity:get_role": "rule:cloud_reader or
  role:admin or
  role:role_admin or
  role:role_viewer"

# List roles.
# GET  /v3/roles
# HEAD  /v3/roles
# Intended scope(s): system
#"identity:list_roles": "role:reader and system_scope:all"
"identity:list_roles": "rule:cloud_reader or
  role:admin or
  role:role_admin or
  role:role_viewer"

# Create role.
# POST  /v3/roles
# Intended scope(s): system
#"identity:create_role": "role:admin and system_scope:all"
"identity:create_role": "rule:cloud_admin"

# PATCH  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:update_role": "role:admin and system_scope:all"
"identity:update_role": "rule:cloud_admin"

# Delete role.
# DELETE  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:delete_role": "role:admin and system_scope:all"
"identity:delete_role": "rule:cloud_admin"

# Show domain role.
# GET  /v3/roles/{role_id}
# HEAD  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:get_domain_role": "role:reader and system_scope:all"
"identity:get_domain_role": "rule:cloud_reader"

# List domain roles.
# GET  /v3/roles?domain_id={domain_id}
# HEAD  /v3/roles?domain_id={domain_id}
# Intended scope(s): system
#"identity:list_domain_roles": "role:reader and system_scope:all"
"identity:list_domain_roles": "rule:cloud_reader"

# Create domain role.
# POST  /v3/roles
# Intended scope(s): system
#"identity:create_domain_role": "role:admin and system_scope:all"
"identity:create_domain_role": "rule:cloud_admin"

# Update domain role.
# PATCH  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:update_domain_role": "role:admin and system_scope:all"
"identity:update_domain_role": "rule:cloud_admin"

# Delete domain role.
# DELETE  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:delete_domain_role": "role:admin and system_scope:all"
"identity:delete_domain_role": "rule:cloud_admin"

# List role assignments.
# GET  /v3/role_assignments
# HEAD  /v3/role_assignments
# Intended scope(s): system, domain
#"identity:list_role_assignments": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"
"identity:list_role_assignments": "rule:cloud_reader or
  (role:reader and domain_id:%(target.domain_id)s) or
  (role:reader and domain_id:%(scope.domain.id)s) or
  ((role:reader or role:role_viewer) and project_id:%(scope.project.id)s)"

# List all role assignments for a given tree of hierarchical projects.
# GET  /v3/role_assignments?include_subtree
# HEAD  /v3/role_assignments?include_subtree
# Intended scope(s): system, domain, project
#"identity:list_role_assignments_for_tree": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.project.domain_id)s) or (role:admin and project_id:%(target.project.id)s)"
"identity:list_role_assignments_for_tree": "rule:cloud_reader or
  (role:reader and domain_id:%(target.project.domain_id)s) or
  ((role:reader or role:role_viewer) and project_id:%(target.project.id)s)"

# Show service details.
# GET  /v3/services/{service_id}
# Intended scope(s): system
#"identity:get_service": "role:reader and system_scope:all"
"identity:get_service": "rule:cloud_reader or
  rule:service_or_admin"

# List services.
# GET  /v3/services
# Intended scope(s): system
#"identity:list_services": "role:reader and system_scope:all"
"identity:list_services": "rule:cloud_reader or
  rule:service_or_admin"

# Create service.
# POST  /v3/services
# Intended scope(s): system
#"identity:create_service": "role:admin and system_scope:all"
"identity:create_service": "rule:cloud_admin"

# Update service.
# PATCH  /v3/services/{service_id}
# Intended scope(s): system
#"identity:update_service": "role:admin and system_scope:all"
"identity:update_service": "rule:cloud_admin"

# Delete service.
# DELETE  /v3/services/{service_id}
# Intended scope(s): system
#"identity:delete_service": "role:admin and system_scope:all"
"identity:delete_service": "rule:cloud_admin"

# Create federated service provider.
# PUT  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
#"identity:create_service_provider": "role:admin and system_scope:all"
"identity:create_service_provider": "rule:cloud_admin"

# List federated service providers.
# GET  /v3/OS-FEDERATION/service_providers
# HEAD  /v3/OS-FEDERATION/service_providers
# Intended scope(s): system
#"identity:list_service_providers": "role:reader and system_scope:all"
"identity:list_service_providers": "rule:cloud_reader"

# Get federated service provider.
# GET  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# HEAD  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
#"identity:get_service_provider": "role:reader and system_scope:all"
"identity:get_service_provider": "rule:cloud_reader"

# Update federated service provider.
# PATCH  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
#"identity:update_service_provider": "role:admin and system_scope:all"
"identity:update_service_provider": "rule:cloud_admin"

# Delete federated service provider.
# DELETE  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
#"identity:delete_service_provider": "role:admin and system_scope:all"
"identity:delete_service_provider": "rule:cloud_admin"

# List revoked PKI tokens.
# GET  /v3/auth/tokens/OS-PKI/revoked
# Intended scope(s): system, project
#"identity:revocation_list": "rule:service_or_admin"

# Check a token.
# HEAD  /v3/auth/tokens
# Intended scope(s): system, domain, project
#"identity:check_token": "(role:reader and system_scope:all) or rule:token_subject"
"identity:check_token": "rule:cloud_reader or rule:token_subject"

# Validate a token.
# GET  /v3/auth/tokens
# Intended scope(s): system, domain, project
#"identity:validate_token": "(role:reader and system_scope:all) or rule:service_role or rule:token_subject"
"identity:validate_token": "rule:cloud_reader or rule:service_role or rule:token_subject"

# Revoke a token.
# DELETE  /v3/auth/tokens
# Intended scope(s): system, domain, project
#"identity:revoke_token": "(role:admin and system_scope:all) or rule:token_subject"
"identity:revoke_token": "rule:cloud_admin or rule:token_subject"

# Create trust.
# POST  /v3/OS-TRUST/trusts
# Intended scope(s): project
#"identity:create_trust": "user_id:%(trust.trustor_user_id)s"

# List trusts.
# GET  /v3/OS-TRUST/trusts
# HEAD  /v3/OS-TRUST/trusts
# Intended scope(s): system
#"identity:list_trusts": "role:reader and system_scope:all"
"identity:list_trusts": "rule:cloud_reader"

# List trusts for trustor.
# GET  /v3/OS-TRUST/trusts?trustor_user_id={trustor_user_id}
# HEAD  /v3/OS-TRUST/trusts?trustor_user_id={trustor_user_id}
# Intended scope(s): system, project
#"identity:list_trusts_for_trustor": "role:reader and system_scope:all or user_id:%(target.trust.trustor_user_id)s"
"identity:list_trusts_for_trustor": "rule:cloud_reader or user_id:%(target.trust.trustor_user_id)s"

# List trusts for trustee.
# GET  /v3/OS-TRUST/trusts?trustee_user_id={trustee_user_id}
# HEAD  /v3/OS-TRUST/trusts?trustee_user_id={trustee_user_id}
# Intended scope(s): system, project
#"identity:list_trusts_for_trustee": "role:reader and system_scope:all or user_id:%(target.trust.trustee_user_id)s"
"identity:list_trusts_for_trustee": "rule:cloud_reader or user_id:%(target.trust.trustee_user_id)s"

# List roles delegated by a trust.
# GET  /v3/OS-TRUST/trusts/{trust_id}/roles
# HEAD  /v3/OS-TRUST/trusts/{trust_id}/roles
# Intended scope(s): system, project
#"identity:list_roles_for_trust": "role:reader and system_scope:all or user_id:%(target.trust.trustor_user_id)s or user_id:%(target.trust.trustee_user_id)s"
"identity:list_roles_for_trust": "rule:cloud_reader or user_id:%(target.trust.trustor_user_id)s or user_id:%(target.trust.trustee_user_id)s"

# Check if trust delegates a particular role.
# GET  /v3/OS-TRUST/trusts/{trust_id}/roles/{role_id}
# HEAD  /v3/OS-TRUST/trusts/{trust_id}/roles/{role_id}
# Intended scope(s): system, project
#"identity:get_role_for_trust": "role:reader and system_scope:all or user_id:%(target.trust.trustor_user_id)s or user_id:%(target.trust.trustee_user_id)s"
"identity:get_role_for_trust": "rule:cloud_reader or user_id:%(target.trust.trustor_user_id)s or user_id:%(target.trust.trustee_user_id)s"

# Revoke trust.
# DELETE  /v3/OS-TRUST/trusts/{trust_id}
# Intended scope(s): system, project
#"identity:delete_trust": "role:admin and system_scope:all or user_id:%(target.trust.trustor_user_id)s"
"identity:delete_trust": "rule:cloud_admin or user_id:%(target.trust.trustor_user_id)s"

# Get trust.
# GET  /v3/OS-TRUST/trusts/{trust_id}
# HEAD  /v3/OS-TRUST/trusts/{trust_id}
# Intended scope(s): system, project
#"identity:get_trust": "role:reader and system_scope:all or user_id:%(target.trust.trustor_user_id)s or user_id:%(target.trust.trustee_user_id)s"
"identity:get_trust": "rule:cloud_reader or user_id:%(target.trust.trustor_user_id)s or user_id:%(target.trust.trustee_user_id)s"

# Show user details.
# GET  /v3/users/{user_id}
# HEAD  /v3/users/{user_id}
# Intended scope(s): system, domain, project
#"identity:get_user": "(role:reader and system_scope:all) or (role:reader and token.domain.id:%(target.user.domain_id)s) or user_id:%(target.user.id)s"
"identity:get_user": "rule:cloud_reader or
  (role:reader and token.domain.id:%(target.user.domain_id)s) or
  user_id:%(target.user.id)s or
  role:role_viewer"

# List users.
# GET  /v3/users
# HEAD  /v3/users
# Intended scope(s): system, domain
#"identity:list_users": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"
"identity:list_users": "rule:cloud_reader or
  (role:reader and domain_id:%(target.domain_id)s) or
  project_domain_id:%(target.domain_id)s or
  user_domain_id:%(target.domain_id)s"

# List all projects a user has access to via role assignments.
# GET   /v3/auth/projects
#"identity:list_projects_for_user": ""

# List all domains a user has access to via role assignments.
# GET  /v3/auth/domains
#"identity:list_domains_for_user": ""

# Create a user.
# POST  /v3/users
# Intended scope(s): system, domain
#"identity:create_user": "(role:admin and system_scope:all) or (role:admin and token.domain.id:%(target.user.domain_id)s)"
"identity:create_user": "rule:cloud_admin or (role:admin and token.domain.id:%(target.user.domain_id)s)"

# Update a user, including administrative password resets.
# PATCH  /v3/users/{user_id}
# Intended scope(s): system, domain
#"identity:update_user": "(role:admin and system_scope:all) or (role:admin and token.domain.id:%(target.user.domain_id)s)"
"identity:update_user": "rule:cloud_admin or (role:admin and token.domain.id:%(target.user.domain_id)s)"

# Delete a user.
# DELETE  /v3/users/{user_id}
# Intended scope(s): system, domain
#"identity:delete_user": "(role:admin and system_scope:all) or (role:admin and token.domain.id:%(target.user.domain_id)s)"
"identity:delete_user": "rule:cloud_admin"
