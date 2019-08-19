#"admin_required": "role:admin or is_admin:1"
#"service_role": "role:service"
#"service_or_admin": "rule:admin_required or rule:service_role"
#"owner": "user_id:%(user_id)s"
#"admin_or_owner": "rule:admin_required or rule:owner"
#"token_subject": "user_id:%(target.token.user_id)s"
#"admin_or_token_subject": "rule:admin_required or rule:token_subject"
#"service_admin_or_token_subject": "rule:service_or_admin or rule:token_subject"

# Show application credential details.
# GET  /v3/users/{user_id}/application_credentials/{application_credential_id}
# HEAD  /v3/users/{user_id}/application_credentials/{application_credential_id}
#"identity:get_application_credential": "rule:admin_or_owner"

# List application credentials for a user.
# GET  /v3/users/{user_id}/application_credentials
# HEAD  /v3/users/{user_id}/application_credentials
#"identity:list_application_credentials": "rule:admin_or_owner"

# Create an application credential.
# POST  /v3/users/{user_id}/application_credentials
#"identity:create_application_credential": "rule:admin_or_owner"

# Delete an application credential.
# DELETE  /v3/users/{user_id}/application_credentials/{application_credential_id}
#"identity:delete_application_credential": "rule:admin_or_owner"

# Authorize OAUTH1 request token.
# PUT  /v3/OS-OAUTH1/authorize/{request_token_id}
# Intended scope(s): project
#"identity:authorize_request_token": "rule:admin_required"

# Get OAUTH1 access token for user by access token ID.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}
# Intended scope(s): project
#"identity:get_access_token": "rule:admin_required"

# Get role for user OAUTH1 access token.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}/roles/{role_id}
# Intended scope(s): project
#"identity:get_access_token_role": "rule:admin_required"

# List OAUTH1 access tokens for user.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens
# Intended scope(s): project
#"identity:list_access_tokens": "rule:admin_required"

# List OAUTH1 access token roles.
# GET  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}/roles
# Intended scope(s): project
#"identity:list_access_token_roles": "rule:admin_required"

# Delete OAUTH1 access token.
# DELETE  /v3/users/{user_id}/OS-OAUTH1/access_tokens/{access_token_id}
# Intended scope(s): project
#"identity:delete_access_token": "rule:admin_required"

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
#"identity:get_consumer": "rule:admin_required"

# List OAUTH1 consumers.
# GET  /v3/OS-OAUTH1/consumers
# Intended scope(s): system
#"identity:list_consumers": "rule:admin_required"

# Create OAUTH1 consumer.
# POST  /v3/OS-OAUTH1/consumers
# Intended scope(s): system
#"identity:create_consumer": "rule:admin_required"

# Update OAUTH1 consumer.
# PATCH  /v3/OS-OAUTH1/consumers/{consumer_id}
# Intended scope(s): system
#"identity:update_consumer": "rule:admin_required"

# Delete OAUTH1 consumer.
# DELETE  /v3/OS-OAUTH1/consumers/{consumer_id}
# Intended scope(s): system
#"identity:delete_consumer": "rule:admin_required"

# Show credentials details.
# GET  /v3/credentials/{credential_id}
# Intended scope(s): system, project
#"identity:get_credential": "(role:reader and system_scope:all) or user_id:%(target.credential.user_id)s"

# DEPRECATED "identity:get_credential":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:get_credential":"(role:reader and system_scope:all) or
# user_id:%(target.credential.user_id)s". As of the Stein release, the
# credential API now understands how to handle system-scoped tokens in
# addition to project-scoped tokens, making the API more accessible to
# users without compromising security or manageability for
# administrators. The new default policies for this API account for
# these changes automatically.
"identity:get_credential": "rule:identity:get_credential"
# List credentials.
# GET  /v3/credentials
# Intended scope(s): system, project
#"identity:list_credentials": "(role:reader and system_scope:all) or user_id:%(target.credential.user_id)s"

# DEPRECATED "identity:list_credentials":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:list_credentials":"(role:reader and system_scope:all) or
# user_id:%(target.credential.user_id)s". As of the Stein release, the
# credential API now understands how to handle system-scoped tokens in
# addition to project-scoped tokens, making the API more accessible to
# users without compromising security or manageability for
# administrators. The new default policies for this API account for
# these changes automatically.
"identity:list_credentials": "rule:identity:list_credentials"
# Create credential.
# POST  /v3/credentials
# Intended scope(s): system, project
#"identity:create_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"

# DEPRECATED "identity:create_credential":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:create_credential":"(role:admin and system_scope:all) or
# user_id:%(target.credential.user_id)s". As of the Stein release, the
# credential API now understands how to handle system-scoped tokens in
# addition to project-scoped tokens, making the API more accessible to
# users without compromising security or manageability for
# administrators. The new default policies for this API account for
# these changes automatically.
"identity:create_credential": "rule:identity:create_credential"
# Update credential.
# PATCH  /v3/credentials/{credential_id}
# Intended scope(s): system, project
#"identity:update_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"

# DEPRECATED "identity:update_credential":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:update_credential":"(role:admin and system_scope:all) or
# user_id:%(target.credential.user_id)s". As of the Stein release, the
# credential API now understands how to handle system-scoped tokens in
# addition to project-scoped tokens, making the API more accessible to
# users without compromising security or manageability for
# administrators. The new default policies for this API account for
# these changes automatically.
"identity:update_credential": "rule:identity:update_credential"
# Delete credential.
# DELETE  /v3/credentials/{credential_id}
# Intended scope(s): system, project
#"identity:delete_credential": "(role:admin and system_scope:all) or user_id:%(target.credential.user_id)s"

# DEPRECATED "identity:delete_credential":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:delete_credential":"(role:admin and system_scope:all) or
# user_id:%(target.credential.user_id)s". As of the Stein release, the
# credential API now understands how to handle system-scoped tokens in
# addition to project-scoped tokens, making the API more accessible to
# users without compromising security or manageability for
# administrators. The new default policies for this API account for
# these changes automatically.
"identity:delete_credential": "rule:identity:delete_credential"
# Show domain details.
# GET  /v3/domains/{domain_id}
# Intended scope(s): system, domain, project
#"identity:get_domain": "(role:reader and system_scope:all) or token.domain.id:%(target.domain.id)s or token.project.domain.id:%(target.domain.id)s"

# DEPRECATED "identity:get_domain":"rule:admin_required or
# token.project.domain.id:%(target.domain.id)s" has been deprecated
# since S in favor of "identity:get_domain":"(role:reader and
# system_scope:all) or token.domain.id:%(target.domain.id)s or
# token.project.domain.id:%(target.domain.id)s".
#
# As of the Stein release, the domain API now understands how to
# handle system-scoped tokens in addition to project-scoped tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically
"identity:get_domain": "rule:identity:get_domain"
# List domains.
# GET  /v3/domains
# Intended scope(s): system
#"identity:list_domains": "role:reader and system_scope:all"

# DEPRECATED "identity:list_domains":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_domains":"role:reader
# and system_scope:all".
#
# As of the Stein release, the domain API now understands how to
# handle system-scoped tokens in addition to project-scoped tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically
"identity:list_domains": "rule:identity:list_domains"
# Create domain.
# POST  /v3/domains
# Intended scope(s): system
#"identity:create_domain": "role:admin and system_scope:all"

# DEPRECATED "identity:create_domain":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_domain":"role:admin
# and system_scope:all".
#
# As of the Stein release, the domain API now understands how to
# handle system-scoped tokens in addition to project-scoped tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically
"identity:create_domain": "rule:identity:create_domain"
# Update domain.
# PATCH  /v3/domains/{domain_id}
# Intended scope(s): system
#"identity:update_domain": "role:admin and system_scope:all"

# DEPRECATED "identity:update_domain":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_domain":"role:admin
# and system_scope:all".
#
# As of the Stein release, the domain API now understands how to
# handle system-scoped tokens in addition to project-scoped tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically
"identity:update_domain": "rule:identity:update_domain"
# Delete domain.
# DELETE  /v3/domains/{domain_id}
# Intended scope(s): system
#"identity:delete_domain": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_domain":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_domain":"role:admin
# and system_scope:all".
#
# As of the Stein release, the domain API now understands how to
# handle system-scoped tokens in addition to project-scoped tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically
"identity:delete_domain": "rule:identity:delete_domain"
# Create domain configuration.
# PUT  /v3/domains/{domain_id}/config
# Intended scope(s): system
#"identity:create_domain_config": "rule:admin_required"

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
#"identity:get_domain_config": "rule:admin_required"

# Get security compliance domain configuration for either a domain or
# a specific option in a domain.
# GET  /v3/domains/{domain_id}/config/security_compliance
# HEAD  /v3/domains/{domain_id}/config/security_compliance
# GET  v3/domains/{domain_id}/config/security_compliance/{option}
# HEAD  v3/domains/{domain_id}/config/security_compliance/{option}
# Intended scope(s): system, project
#"identity:get_security_compliance_domain_config": ""

# Update domain configuration for either a domain, specific group or a
# specific option in a group.
# PATCH  /v3/domains/{domain_id}/config
# PATCH  /v3/domains/{domain_id}/config/{group}
# PATCH  /v3/domains/{domain_id}/config/{group}/{option}
# Intended scope(s): system
#"identity:update_domain_config": "rule:admin_required"

# Delete domain configuration for either a domain, specific group or a
# specific option in a group.
# DELETE  /v3/domains/{domain_id}/config
# DELETE  /v3/domains/{domain_id}/config/{group}
# DELETE  /v3/domains/{domain_id}/config/{group}/{option}
# Intended scope(s): system
#"identity:delete_domain_config": "rule:admin_required"

# Get domain configuration default for either a domain, specific group
# or a specific option in a group.
# GET  /v3/domains/config/default
# HEAD  /v3/domains/config/default
# GET  /v3/domains/config/{group}/default
# HEAD  /v3/domains/config/{group}/default
# GET  /v3/domains/config/{group}/{option}/default
# HEAD  /v3/domains/config/{group}/{option}/default
# Intended scope(s): system
#"identity:get_domain_config_default": "rule:admin_required"

# Show ec2 credential details.
# GET  /v3/users/{user_id}/credentials/OS-EC2/{credential_id}
#"identity:ec2_get_credential": "rule:admin_required or (rule:owner and user_id:%(target.credential.user_id)s)"

# List ec2 credentials.
# GET  /v3/users/{user_id}/credentials/OS-EC2
#"identity:ec2_list_credentials": "rule:admin_or_owner"

# Create ec2 credential.
# POST  /v3/users/{user_id}/credentials/OS-EC2
#"identity:ec2_create_credential": "rule:admin_or_owner"

# Delete ec2 credential.
# DELETE  /v3/users/{user_id}/credentials/OS-EC2/{credential_id}
#"identity:ec2_delete_credential": "rule:admin_required or (rule:owner and user_id:%(target.credential.user_id)s)"

# Show endpoint details.
# GET  /v3/endpoints/{endpoint_id}
# Intended scope(s): system
"identity:get_endpoint": "role:reader and system_scope:all"

# DEPRECATED "identity:get_endpoint":"rule:admin_required" has been
# deprecated since S in favor of "identity:get_endpoint":"role:reader
# and system_scope:all".
#
# As of the Stein release, the endpoint API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the endpoint API.
#"identity:get_endpoint": "rule:identity:get_endpoint"
# List endpoints.
# GET  /v3/endpoints
# Intended scope(s): system
"identity:list_endpoints": "role:reader and system_scope:all"

# DEPRECATED "identity:list_endpoints":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:list_endpoints":"role:reader and system_scope:all".
#
# As of the Stein release, the endpoint API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the endpoint API.
#"identity:list_endpoints": "rule:identity:list_endpoints"
# Create endpoint.
# POST  /v3/endpoints
# Intended scope(s): system
"identity:create_endpoint": "role:admin and system_scope:all"

# DEPRECATED "identity:create_endpoint":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:create_endpoint":"role:admin and system_scope:all".
#
# As of the Stein release, the endpoint API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the endpoint API.
#"identity:create_endpoint": "rule:identity:create_endpoint"
# Update endpoint.
# PATCH  /v3/endpoints/{endpoint_id}
# Intended scope(s): system
"identity:update_endpoint": "role:admin and system_scope:all"

# DEPRECATED "identity:update_endpoint":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:update_endpoint":"role:admin and system_scope:all".
#
# As of the Stein release, the endpoint API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the endpoint API.
#"identity:update_endpoint": "rule:identity:update_endpoint"
# Delete endpoint.
# DELETE  /v3/endpoints/{endpoint_id}
# Intended scope(s): system
"identity:delete_endpoint": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_endpoint":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:delete_endpoint":"role:admin and system_scope:all".
#
# As of the Stein release, the endpoint API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the endpoint API.
#"identity:delete_endpoint": "rule:identity:delete_endpoint"
# Create endpoint group.
# POST  /v3/OS-EP-FILTER/endpoint_groups
# Intended scope(s): system
#"identity:create_endpoint_group": "rule:admin_required"

# List endpoint groups.
# GET  /v3/OS-EP-FILTER/endpoint_groups
# Intended scope(s): system
#"identity:list_endpoint_groups": "rule:admin_required"

# Get endpoint group.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# HEAD  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# Intended scope(s): system
#"identity:get_endpoint_group": "rule:admin_required"

# Update endpoint group.
# PATCH  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# Intended scope(s): system
#"identity:update_endpoint_group": "rule:admin_required"

# Delete endpoint group.
# DELETE  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}
# Intended scope(s): system
#"identity:delete_endpoint_group": "rule:admin_required"

# List all projects associated with a specific endpoint group.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects
# Intended scope(s): system
#"identity:list_projects_associated_with_endpoint_group": "rule:admin_required"

# List all endpoints associated with an endpoint group.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/endpoints
# Intended scope(s): system
#"identity:list_endpoints_associated_with_endpoint_group": "rule:admin_required"

# Check if an endpoint group is associated with a project.
# GET  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# HEAD  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# Intended scope(s): system
#"identity:get_endpoint_group_in_project": "rule:admin_required"

# List endpoint groups associated with a specific project.
# GET  /v3/OS-EP-FILTER/projects/{project_id}/endpoint_groups
# Intended scope(s): system
#"identity:list_endpoint_groups_for_project": "rule:admin_required"

# Allow a project to access an endpoint group.
# PUT  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# Intended scope(s): system
#"identity:add_endpoint_group_to_project": "rule:admin_required"

# Remove endpoint group from project.
# DELETE  /v3/OS-EP-FILTER/endpoint_groups/{endpoint_group_id}/projects/{project_id}
# Intended scope(s): system
#"identity:remove_endpoint_group_from_project": "rule:admin_required"

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
# Intended scope(s): system
"identity:check_grant": "role:reader and system_scope:all"

# DEPRECATED "identity:check_grant":"rule:admin_required" has been
# deprecated since S in favor of "identity:check_grant":"role:reader
# and system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:check_grant": "rule:identity:check_grant"
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
# Intended scope(s): system
"identity:list_grants": "role:reader and system_scope:all"

# DEPRECATED "identity:list_grants":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_grants":"role:reader
# and system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:list_grants": "rule:identity:list_grants"
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
# Intended scope(s): system
"identity:create_grant": "role:admin and system_scope:all"

# DEPRECATED "identity:create_grant":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_grant":"role:admin
# and system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:create_grant": "rule:identity:create_grant"
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
# Intended scope(s): system
"identity:revoke_grant": "role:admin and system_scope:all"

# DEPRECATED "identity:revoke_grant":"rule:admin_required" has been
# deprecated since S in favor of "identity:revoke_grant":"role:admin
# and system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:revoke_grant": "rule:identity:revoke_grant"
# List all grants a specific user has on the system.
# ['HEAD', 'GET']  /v3/system/users/{user_id}/roles
# Intended scope(s): system
"identity:list_system_grants_for_user": "role:reader and system_scope:all"

# DEPRECATED
# "identity:list_system_grants_for_user":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:list_system_grants_for_user":"role:reader and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:list_system_grants_for_user": "rule:identity:list_system_grants_for_user"
# Check if a user has a role on the system.
# ['HEAD', 'GET']  /v3/system/users/{user_id}/roles/{role_id}
# Intended scope(s): system
"identity:check_system_grant_for_user": "role:reader and system_scope:all"

# DEPRECATED
# "identity:check_system_grant_for_user":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:check_system_grant_for_user":"role:reader and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:check_system_grant_for_user": "rule:identity:check_system_grant_for_user"
# Grant a user a role on the system.
# ['PUT']  /v3/system/users/{user_id}/roles/{role_id}
# Intended scope(s): system
"identity:create_system_grant_for_user": "role:admin and system_scope:all"

# DEPRECATED
# "identity:create_system_grant_for_user":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:create_system_grant_for_user":"role:admin and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:create_system_grant_for_user": "rule:identity:create_system_grant_for_user"
# Remove a role from a user on the system.
# ['DELETE']  /v3/system/users/{user_id}/roles/{role_id}
# Intended scope(s): system
"identity:revoke_system_grant_for_user": "role:admin and system_scope:all"

# DEPRECATED
# "identity:revoke_system_grant_for_user":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:revoke_system_grant_for_user":"role:admin and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:revoke_system_grant_for_user": "rule:identity:revoke_system_grant_for_user"
# List all grants a specific group has on the system.
# ['HEAD', 'GET']  /v3/system/groups/{group_id}/roles
# Intended scope(s): system
"identity:list_system_grants_for_group": "role:reader and system_scope:all"

# DEPRECATED
# "identity:list_system_grants_for_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:list_system_grants_for_group":"role:reader and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:list_system_grants_for_group": "rule:identity:list_system_grants_for_group"
# Check if a group has a role on the system.
# ['HEAD', 'GET']  /v3/system/groups/{group_id}/roles/{role_id}
# Intended scope(s): system
"identity:check_system_grant_for_group": "role:reader and system_scope:all"

# DEPRECATED
# "identity:check_system_grant_for_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:check_system_grant_for_group":"role:reader and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:check_system_grant_for_group": "rule:identity:check_system_grant_for_group"
# Grant a group a role on the system.
# ['PUT']  /v3/system/groups/{group_id}/roles/{role_id}
# Intended scope(s): system
"identity:create_system_grant_for_group": "role:admin and system_scope:all"

# DEPRECATED
# "identity:create_system_grant_for_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:create_system_grant_for_group":"role:admin and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:create_system_grant_for_group": "rule:identity:create_system_grant_for_group"
# Remove a role from a group on the system.
# ['DELETE']  /v3/system/groups/{group_id}/roles/{role_id}
# Intended scope(s): system
"identity:revoke_system_grant_for_group": "role:admin and system_scope:all"

# DEPRECATED
# "identity:revoke_system_grant_for_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:revoke_system_grant_for_group":"role:admin and
# system_scope:all".
#
# As of the Stein release, the assignment API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the system assignment API.
#"identity:revoke_system_grant_for_group": "rule:identity:revoke_system_grant_for_group"
# Show group details.
# GET  /v3/groups/{group_id}
# HEAD  /v3/groups/{group_id}
# Intended scope(s): system, domain
"identity:get_group": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s)"

# DEPRECATED "identity:get_group":"rule:admin_required" has been
# deprecated since S in favor of "identity:get_group":"(role:reader
# and system_scope:all) or (role:reader and
# domain_id:%(target.group.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:get_group": "rule:identity:get_group"
# List groups.
# GET  /v3/groups
# HEAD  /v3/groups
# Intended scope(s): system, domain
"identity:list_groups": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s)"

# DEPRECATED "identity:list_groups":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_groups":"(role:reader
# and system_scope:all) or (role:reader and
# domain_id:%(target.group.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_groups": "rule:identity:list_groups"
# List groups to which a user belongs.
# GET  /v3/users/{user_id}/groups
# HEAD  /v3/users/{user_id}/groups
# Intended scope(s): system, domain, project
"identity:list_groups_for_user": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.user.domain_id)s) or user_id:%(user_id)s"

# DEPRECATED "identity:list_groups_for_user":"rule:admin_or_owner" has
# been deprecated since S in favor of
# "identity:list_groups_for_user":"(role:reader and system_scope:all)
# or (role:reader and domain_id:%(target.user.domain_id)s) or
# user_id:%(user_id)s".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_groups_for_user": "rule:identity:list_groups_for_user"
# Create group.
# POST  /v3/groups
# Intended scope(s): system, domain
"identity:create_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s)"

# DEPRECATED "identity:create_group":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_group":"(role:admin
# and system_scope:all) or (role:admin and
# domain_id:%(target.group.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:create_group": "rule:identity:create_group"
# Update group.
# PATCH  /v3/groups/{group_id}
# Intended scope(s): system, domain
"identity:update_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s)"

# DEPRECATED "identity:update_group":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_group":"(role:admin
# and system_scope:all) or (role:admin and
# domain_id:%(target.group.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:update_group": "rule:identity:update_group"
# Delete group.
# DELETE  /v3/groups/{group_id}
# Intended scope(s): system, domain
"identity:delete_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s)"

# DEPRECATED "identity:delete_group":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_group":"(role:admin
# and system_scope:all) or (role:admin and
# domain_id:%(target.group.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:delete_group": "rule:identity:delete_group"
# List members of a specific group.
# GET  /v3/groups/{group_id}/users
# HEAD  /v3/groups/{group_id}/users
# Intended scope(s): system, domain
"identity:list_users_in_group": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s)"

# DEPRECATED "identity:list_users_in_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:list_users_in_group":"(role:reader and system_scope:all)
# or (role:reader and domain_id:%(target.group.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_users_in_group": "rule:identity:list_users_in_group"
# Remove user from group.
# DELETE  /v3/groups/{group_id}/users/{user_id}
# Intended scope(s): system, domain
"identity:remove_user_from_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"

# DEPRECATED "identity:remove_user_from_group":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:remove_user_from_group":"(role:admin and system_scope:all)
# or (role:admin and domain_id:%(target.group.domain_id)s and
# domain_id:%(target.user.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:remove_user_from_group": "rule:identity:remove_user_from_group"
# Check whether a user is a member of a group.
# HEAD  /v3/groups/{group_id}/users/{user_id}
# GET  /v3/groups/{group_id}/users/{user_id}
# Intended scope(s): system, domain
"identity:check_user_in_group": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"

# DEPRECATED "identity:check_user_in_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:check_user_in_group":"(role:reader and system_scope:all)
# or (role:reader and domain_id:%(target.group.domain_id)s and
# domain_id:%(target.user.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:check_user_in_group": "rule:identity:check_user_in_group"
# Add user to group.
# PUT  /v3/groups/{group_id}/users/{user_id}
# Intended scope(s): system, domain
"identity:add_user_to_group": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.group.domain_id)s and domain_id:%(target.user.domain_id)s)"

# DEPRECATED "identity:add_user_to_group":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:add_user_to_group":"(role:admin and system_scope:all) or
# (role:admin and domain_id:%(target.group.domain_id)s and
# domain_id:%(target.user.domain_id)s)".
#
# As of the Stein release, the group API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:add_user_to_group": "rule:identity:add_user_to_group"
# Create identity provider.
# PUT  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
"identity:create_identity_provider": "role:admin and system_scope:all"

# DEPRECATED
# "identity:create_identity_providers":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:create_identity_provider":"role:admin and
# system_scope:all".
#
# As of the Stein release, the identity provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the identity provider API.
#"identity:create_identity_providers": "rule:identity:create_identity_provider"
# List identity providers.
# GET  /v3/OS-FEDERATION/identity_providers
# HEAD  /v3/OS-FEDERATION/identity_providers
# Intended scope(s): system
"identity:list_identity_providers": "role:reader and system_scope:all"

# DEPRECATED "identity:list_identity_providers":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:list_identity_providers":"role:reader and
# system_scope:all".
#
# As of the Stein release, the identity provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the identity provider API.
#"identity:list_identity_providers": "rule:identity:list_identity_providers"
# Get identity provider.
# GET  /v3/OS-FEDERATION/identity_providers/{idp_id}
# HEAD  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
"identity:get_identity_provider": "role:reader and system_scope:all"

# DEPRECATED "identity:get_identity_providers":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:get_identity_provider":"role:reader and system_scope:all".
#
# As of the Stein release, the identity provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the identity provider API.
#"identity:get_identity_providers": "rule:identity:get_identity_provider"
# Update identity provider.
# PATCH  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
"identity:update_identity_provider": "role:admin and system_scope:all"

# DEPRECATED
# "identity:update_identity_providers":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:update_identity_provider":"role:admin and
# system_scope:all".
#
# As of the Stein release, the identity provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the identity provider API.
#"identity:update_identity_providers": "rule:identity:update_identity_provider"
# Delete identity provider.
# DELETE  /v3/OS-FEDERATION/identity_providers/{idp_id}
# Intended scope(s): system
"identity:delete_identity_provider": "role:admin and system_scope:all"

# DEPRECATED
# "identity:delete_identity_providers":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:delete_identity_provider":"role:admin and
# system_scope:all".
#
# As of the Stein release, the identity provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the identity provider API.
#identity:delete_identity_providers": "rule:identity:delete_identity_provider"
# Get information about an association between two roles. When a
# relationship exists between a prior role and an implied role and the
# prior role is assigned to a user, the user also assumes the implied
# role.
# GET  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:get_implied_role": "rule:admin_required"

# List associations between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role. This
# will return all the implied roles that would be assumed by the user
# who gets the specified prior role.
# GET  /v3/roles/{prior_role_id}/implies
# HEAD  /v3/roles/{prior_role_id}/implies
# Intended scope(s): system
#"identity:list_implied_roles": "rule:admin_required"

# Create an association between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role.
# PUT  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:create_implied_role": "rule:admin_required"

# Delete the association between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role. Removing
# the association will cause that effect to be eliminated.
# DELETE  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:delete_implied_role": "rule:admin_required"

# List all associations between two roles in the system. When a
# relationship exists between a prior role and an implied role and the
# prior role is assigned to a user, the user also assumes the implied
# role.
# GET  /v3/role_inferences
# HEAD  /v3/role_inferences
# Intended scope(s): system
#"identity:list_role_inference_rules": "rule:admin_required"

# Check an association between two roles. When a relationship exists
# between a prior role and an implied role and the prior role is
# assigned to a user, the user also assumes the implied role.
# HEAD  /v3/roles/{prior_role_id}/implies/{implied_role_id}
# Intended scope(s): system
#"identity:check_implied_role": "rule:admin_required"

# Get limit enforcement model.
# GET  /v3/limits/model
# HEAD  /v3/limits/model
# Intended scope(s): system, project
#"identity:get_limit_model": ""

# Show limit details.
# GET  /v3/limits/{limit_id}
# HEAD  /v3/limits/{limit_id}
# Intended scope(s): system, project, domain
#"identity:get_limit": "(role:reader and system_scope:all) or project_id:%(target.limit.project_id)s or domain_id:%(target.limit.domain_id)s"

# List limits.
# GET  /v3/limits
# HEAD  /v3/limits
# Intended scope(s): system, project
#"identity:list_limits": ""

# Create limits.
# POST  /v3/limits
# Intended scope(s): system
#"identity:create_limits": "role:admin and system_scope:all"

# Update limit.
# PATCH  /v3/limits/{limit_id}
# Intended scope(s): system
#"identity:update_limit": "role:admin and system_scope:all"

# Delete limit.
# DELETE  /v3/limits/{limit_id}
# Intended scope(s): system
#"identity:delete_limit": "role:admin and system_scope:all"

# Create a new federated mapping containing one or more sets of rules.
# PUT  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
"identity:create_mapping": "role:admin and system_scope:all"

# DEPRECATED "identity:create_mapping":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_mapping":"role:admin
# and system_scope:all".
#
# As of the Stein release, the federated mapping API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the federated mapping API.
#"identity:create_mapping": "rule:identity:create_mapping"
# Get a federated mapping.
# GET  /v3/OS-FEDERATION/mappings/{mapping_id}
# HEAD  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
"identity:get_mapping": "role:reader and system_scope:all"

# DEPRECATED "identity:get_mapping":"rule:admin_required" has been
# deprecated since S in favor of "identity:get_mapping":"role:reader
# and system_scope:all".
#
# As of the Stein release, the federated mapping API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the federated mapping API.
#"identity:get_mapping": "rule:identity:get_mapping"
# List federated mappings.
# GET  /v3/OS-FEDERATION/mappings
# HEAD  /v3/OS-FEDERATION/mappings
# Intended scope(s): system
"identity:list_mappings": "role:reader and system_scope:all"

# DEPRECATED "identity:get_mapping":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_mappings":"role:reader
# and system_scope:all".
#
# As of the Stein release, the federated mapping API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the federated mapping API.
#"identity:get_mapping": "rule:identity:list_mappings"
# Delete a federated mapping.
# DELETE  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
"identity:delete_mapping": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_mapping":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_mapping":"role:admin
# and system_scope:all".
#
# As of the Stein release, the federated mapping API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the federated mapping API.
#"identity:delete_mapping": "rule:identity:delete_mapping"
# Update a federated mapping.
# PATCH  /v3/OS-FEDERATION/mappings/{mapping_id}
# Intended scope(s): system
"identity:update_mapping": "role:admin and system_scope:all"

# DEPRECATED "identity:update_mapping":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_mapping":"role:admin
# and system_scope:all".
#
# As of the Stein release, the federated mapping API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the federated mapping API.
#"identity:update_mapping": "rule:identity:update_mapping"
# Show policy details.
# GET  /v3/policy/{policy_id}
# Intended scope(s): system
#"identity:get_policy": "rule:admin_required"

# List policies.
# GET  /v3/policies
# Intended scope(s): system
#"identity:list_policies": "rule:admin_required"

# Create policy.
# POST  /v3/policies
# Intended scope(s): system
#"identity:create_policy": "rule:admin_required"

# Update policy.
# PATCH  /v3/policies/{policy_id}
# Intended scope(s): system
#"identity:update_policy": "rule:admin_required"

# Delete policy.
# DELETE  /v3/policies/{policy_id}
# Intended scope(s): system
#"identity:delete_policy": "rule:admin_required"

# Associate a policy to a specific endpoint.
# PUT  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:create_policy_association_for_endpoint": "rule:admin_required"

# Check policy association for endpoint.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# HEAD  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:check_policy_association_for_endpoint": "rule:admin_required"

# Delete policy association for endpoint.
# DELETE  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:delete_policy_association_for_endpoint": "rule:admin_required"

# Associate a policy to a specific service.
# PUT  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# Intended scope(s): system
#"identity:create_policy_association_for_service": "rule:admin_required"

# Check policy association for service.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# HEAD  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# Intended scope(s): system
#"identity:check_policy_association_for_service": "rule:admin_required"

# Delete policy association for service.
# DELETE  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}
# Intended scope(s): system
#"identity:delete_policy_association_for_service": "rule:admin_required"

# Associate a policy to a specific region and service combination.
# PUT  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# Intended scope(s): system
#"identity:create_policy_association_for_region_and_service": "rule:admin_required"

# Check policy association for region and service.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# HEAD  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# Intended scope(s): system
#"identity:check_policy_association_for_region_and_service": "rule:admin_required"

# Delete policy association for region and service.
# DELETE  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/services/{service_id}/regions/{region_id}
# Intended scope(s): system
#"identity:delete_policy_association_for_region_and_service": "rule:admin_required"

# Get policy for endpoint.
# GET  /v3/endpoints/{endpoint_id}/OS-ENDPOINT-POLICY/policy
# HEAD  /v3/endpoints/{endpoint_id}/OS-ENDPOINT-POLICY/policy
# Intended scope(s): system
#"identity:get_policy_for_endpoint": "rule:admin_required"

# List endpoints for policy.
# GET  /v3/policies/{policy_id}/OS-ENDPOINT-POLICY/endpoints
# Intended scope(s): system
#"identity:list_endpoints_for_policy": "rule:admin_required"

# Show project details.
# GET  /v3/projects/{project_id}
# Intended scope(s): system, domain, project
"identity:get_project": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.project.domain_id)s) or project_id:%(target.project.id)s"

# DEPRECATED "identity:get_project":"rule:admin_required or
# project_id:%(target.project.id)s" has been deprecated since S in
# favor of "identity:get_project":"(role:reader and system_scope:all)
# or (role:reader and domain_id:%(target.project.domain_id)s) or
# project_id:%(target.project.id)s".
#
# As of the Stein release, the project API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:get_project": "rule:identity:get_project"
# List projects.
# GET  /v3/projects
# Intended scope(s): system, domain
"identity:list_projects": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"

# DEPRECATED "identity:list_projects":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:list_projects":"(role:reader and system_scope:all) or
# (role:reader and domain_id:%(target.domain_id)s)".
#
# As of the Stein release, the project API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_projects": "rule:identity:list_projects"
# List projects for user.
# GET  /v3/users/{user_id}/projects
# Intended scope(s): system, domain, project
"identity:list_user_projects": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.user.domain_id)s) or user_id:%(target.user.id)s"

# DEPRECATED "identity:list_user_projects":"rule:admin_or_owner" has
# been deprecated since S in favor of
# "identity:list_user_projects":"(role:reader and system_scope:all) or
# (role:reader and domain_id:%(target.user.domain_id)s) or
# user_id:%(target.user.id)s".
#
# As of the Stein release, the project API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_user_projects": "rule:identity:list_user_projects"
# Create project.
# POST  /v3/projects
# Intended scope(s): system, domain
"identity:create_project": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s)"

# DEPRECATED "identity:create_project":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:create_project":"(role:admin and system_scope:all) or
# (role:admin and domain_id:%(target.project.domain_id)s)".
#
# As of the Stein release, the project API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:create_project": "rule:identity:create_project"
# Update project.
# PATCH  /v3/projects/{project_id}
# Intended scope(s): system, domain
"identity:update_project": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s)"

# DEPRECATED "identity:update_project":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:update_project":"(role:admin and system_scope:all) or
# (role:admin and domain_id:%(target.project.domain_id)s)".
#
# As of the Stein release, the project API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:update_project": "rule:identity:update_project"
# Delete project.
# DELETE  /v3/projects/{project_id}
# Intended scope(s): system, domain
"identity:delete_project": "(role:admin and system_scope:all) or (role:admin and domain_id:%(target.project.domain_id)s)"

# DEPRECATED "identity:delete_project":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:delete_project":"(role:admin and system_scope:all) or
# (role:admin and domain_id:%(target.project.domain_id)s)".
#
# As of the Stein release, the project API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:delete_project": "rule:identity:delete_project"
# List tags for a project.
# GET  /v3/projects/{project_id}/tags
# HEAD  /v3/projects/{project_id}/tags
#"identity:list_project_tags": "rule:admin_required or project_id:%(target.project.id)s"

# Check if project contains a tag.
# GET  /v3/projects/{project_id}/tags/{value}
# HEAD  /v3/projects/{project_id}/tags/{value}
#"identity:get_project_tag": "rule:admin_required or project_id:%(target.project.id)s"

# Replace all tags on a project with the new set of tags.
# PUT  /v3/projects/{project_id}/tags
# Intended scope(s): system
#"identity:update_project_tags": "rule:admin_required"

# Add a single tag to a project.
# PUT  /v3/projects/{project_id}/tags/{value}
# Intended scope(s): system
#"identity:create_project_tag": "rule:admin_required"

# Remove all tags from a project.
# DELETE  /v3/projects/{project_id}/tags
# Intended scope(s): system
#"identity:delete_project_tags": "rule:admin_required"

# Delete a specified tag from project.
# DELETE  /v3/projects/{project_id}/tags/{value}
# Intended scope(s): system
#"identity:delete_project_tag": "rule:admin_required"

# List projects allowed to access an endpoint.
# GET  /v3/OS-EP-FILTER/endpoints/{endpoint_id}/projects
# Intended scope(s): system
#"identity:list_projects_for_endpoint": "rule:admin_required"

# Allow project to access an endpoint.
# PUT  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:add_endpoint_to_project": "rule:admin_required"

# Check if a project is allowed to access an endpoint.
# GET  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# HEAD  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:check_endpoint_in_project": "rule:admin_required"

# List the endpoints a project is allowed to access.
# GET  /v3/OS-EP-FILTER/projects/{project_id}/endpoints
# Intended scope(s): system
#"identity:list_endpoints_for_project": "rule:admin_required"

# Remove access to an endpoint from a project that has previously been
# given explicit access.
# DELETE  /v3/OS-EP-FILTER/projects/{project_id}/endpoints/{endpoint_id}
# Intended scope(s): system
#"identity:remove_endpoint_from_project": "rule:admin_required"

# Create federated protocol.
# PUT  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
"identity:create_protocol": "role:admin and system_scope:all"

# DEPRECATED "identity:create_protocol":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:create_protocol":"role:admin and system_scope:all".
#
# As of the Stein release, the federated protocol API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the protocol API.
#"identity:create_protocol": "rule:identity:create_protocol"
# Update federated protocol.
# PATCH  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
"identity:update_protocol": "role:admin and system_scope:all"

# DEPRECATED "identity:update_protocol":"rule:admin_required" has been
# deprecated since S in favor of
#"identity:update_protocol":"role:admin and system_scope:all".
#
# As of the Stein release, the federated protocol API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the protocol API.
#"identity:update_protocol": "rule:identity:update_protocol"
# Get federated protocol.
# GET  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
"identity:get_protocol": "role:reader and system_scope:all"

# DEPRECATED "identity:get_protocol":"rule:admin_required" has been
# deprecated since S in favor of "identity:get_protocol":"role:reader
# and system_scope:all".
#
# As of the Stein release, the federated protocol API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the protocol API.
#"identity:get_protocol": "rule:identity:get_protocol"
# List federated protocols.
# GET  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols
# Intended scope(s): system
#"identity:list_protocols": "role:reader and system_scope:all"

# DEPRECATED "identity:list_protocols":"rule:admin_required" has been
# deprecated since S in favor of
"identity:list_protocols":"role:reader and system_scope:all".
#
# As of the Stein release, the federated protocol API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the protocol API.
#"identity:list_protocols": "rule:identity:list_protocols"
# Delete federated protocol.
# DELETE  /v3/OS-FEDERATION/identity_providers/{idp_id}/protocols/{protocol_id}
# Intended scope(s): system
"identity:delete_protocol": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_protocol":"rule:admin_required" has been
# deprecated since S in favor of
# "identity:delete_protocol":"role:admin and system_scope:all".
#
# As of the Stein release, the federated protocol API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the protocol API.
#"identity:delete_protocol": "rule:identity:delete_protocol"
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
"identity:create_region": "role:admin and system_scope:all"

# DEPRECATED "identity:create_region":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_region":"role:admin
# and system_scope:all". As of the Stein release, the region API now
# understands default roles and system-scoped tokens, making the API
# more granular without compromising security. The new policies for
# this API account for these changes automatically. Be sure to take
# these new defaults into consideration if you are relying on
# overrides in your deployment for the region API.
#"identity:create_region": "rule:identity:create_region"
# Update region.
# PATCH  /v3/regions/{region_id}
# Intended scope(s): system
"identity:update_region": "role:admin and system_scope:all"

# DEPRECATED "identity:update_region":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_region":"role:admin
# and system_scope:all". As of the Stein release, the region API now
# understands default roles and system-scoped tokens, making the API
# more granular without compromising security. The new policies for
# this API account for these changes automatically. Be sure to take
# these new defaults into consideration if you are relying on
# overrides in your deployment for the region API.
#"identity:update_region": "rule:identity:update_region"
# Delete region.
# DELETE  /v3/regions/{region_id}
# Intended scope(s): system
"identity:delete_region": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_region":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_region":"role:admin
# and system_scope:all". As of the Stein release, the region API now
# understands default roles and system-scoped tokens, making the API
# more granular without compromising security. The new policies for
# this API account for these changes automatically. Be sure to take
# these new defaults into consideration if you are relying on
# overrides in your deployment for the region API.
#"identity:delete_region": "rule:identity:delete_region"
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

# Update registered limit.
# PATCH  /v3/registered_limits/{registered_limit_id}
# Intended scope(s): system
#"identity:update_registered_limit": "role:admin and system_scope:all"

# Delete registered limit.
# DELETE  /v3/registered_limits/{registered_limit_id}
# Intended scope(s): system
#"identity:delete_registered_limit": "role:admin and system_scope:all"

# List revocation events.
# GET  /v3/OS-REVOKE/events
# Intended scope(s): system
#"identity:list_revoke_events": "rule:service_or_admin"

# Show role details.
# GET  /v3/roles/{role_id}
# HEAD  /v3/roles/{role_id}
# Intended scope(s): system
"identity:get_role": "role:reader and system_scope:all"

# DEPRECATED "identity:get_role":"rule:admin_required" has been
# deprecated since S in favor of "identity:get_role":"role:reader and
# system_scope:all".
#
# As of the Stein release, the role API now understands default roles
# and system-scoped tokens, making the API more granular by default
# without compromising security. The new policy defaults account for
# these changes automatically. Be sure to take these new defaults into
# consideration if you are relying on overrides in your deployment for
# the role API.
#"identity:get_role": "rule:identity:get_role"
# List roles.
# GET  /v3/roles
# HEAD  /v3/roles
# Intended scope(s): system
"identity:list_roles": "role:reader and system_scope:all"

# DEPRECATED "identity:list_roles":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_roles":"role:reader
# and system_scope:all".
#
# As of the Stein release, the role API now understands default roles
# and system-scoped tokens, making the API more granular by default
# without compromising security. The new policy defaults account for
# these changes automatically. Be sure to take these new defaults into
# consideration if you are relying on overrides in your deployment for
# the role API.
#"identity:list_roles": "rule:identity:list_roles"
# Create role.
# POST  /v3/roles
# Intended scope(s): system
"identity:create_role": "role:admin and system_scope:all"

# DEPRECATED "identity:create_role":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_role":"role:admin
# and system_scope:all".
#
# As of the Stein release, the role API now understands default roles
# and system-scoped tokens, making the API more granular by default
# without compromising security. The new policy defaults account for
# these changes automatically. Be sure to take these new defaults into
# consideration if you are relying on overrides in your deployment for
# the role API.
#"identity:create_role": "rule:identity:create_role"
# Update role.
# PATCH  /v3/roles/{role_id}
# Intended scope(s): system
"identity:update_role": "role:admin and system_scope:all"

# DEPRECATED "identity:update_role":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_role":"role:admin
# and system_scope:all".
#
# As of the Stein release, the role API now understands default roles
# and system-scoped tokens, making the API more granular by default
# without compromising security. The new policy defaults account for
# these changes automatically. Be sure to take these new defaults into
# consideration if you are relying on overrides in your deployment for
# the role API.
#"identity:update_role": "rule:identity:update_role"
# Delete role.
# DELETE  /v3/roles/{role_id}
# Intended scope(s): system
"identity:delete_role": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_role":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_role":"role:admin
# and system_scope:all".
#
# As of the Stein release, the role API now understands default roles
# and system-scoped tokens, making the API more granular by default
# without compromising security. The new policy defaults account for
# these changes automatically. Be sure to take these new defaults into
# consideration if you are relying on overrides in your deployment for
# the role API.
#"identity:delete_role": "rule:identity:delete_role"
# Show domain role.
# GET  /v3/roles/{role_id}
# HEAD  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:get_domain_role": "rule:admin_required"

# List domain roles.
# GET  /v3/roles?domain_id={domain_id}
# HEAD  /v3/roles?domain_id={domain_id}
# Intended scope(s): system
#"identity:list_domain_roles": "rule:admin_required"

# Create domain role.
# POST  /v3/roles
# Intended scope(s): system
#"identity:create_domain_role": "rule:admin_required"

# Update domain role.
# PATCH  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:update_domain_role": "rule:admin_required"

# Delete domain role.
# DELETE  /v3/roles/{role_id}
# Intended scope(s): system
#"identity:delete_domain_role": "rule:admin_required"

# List role assignments.
# GET  /v3/role_assignments
# HEAD  /v3/role_assignments
# Intended scope(s): system, domain
"identity:list_role_assignments": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"

# DEPRECATED "identity:list_role_assignments":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:list_role_assignments":"(role:reader and system_scope:all)
# or (role:reader and domain_id:%(target.domain_id)s)".
#
# As of the Stein release, the role assignment API now understands how
# to handle system-scoped tokens in addition to project-scoped tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_role_assignments": "rule:identity:list_role_assignments"
# List all role assignments for a given tree of hierarchical projects.
# GET  /v3/role_assignments?include_subtree
# HEAD  /v3/role_assignments?include_subtree
# Intended scope(s): project
#"identity:list_role_assignments_for_tree": "rule:admin_required"

# Show service details.
# GET  /v3/services/{service_id}
# Intended scope(s): system
"identity:get_service": "role:reader and system_scope:all"

# DEPRECATED "identity:get_service":"rule:admin_required" has been
# deprecated since S in favor of "identity:get_service":"role:reader
# and system_scope:all".
#
# As of the Stein release, the service API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service API.
#"identity:get_service": "rule:identity:get_service"
# List services.
# GET  /v3/services
# Intended scope(s): system
"identity:list_services": "role:reader and system_scope:all"

# DEPRECATED "identity:list_services":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_services":"role:reader
# and system_scope:all".
#
# As of the Stein release, the service API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service API.
#"identity:list_services": "rule:identity:list_services"
# Create service.
# POST  /v3/services
# Intended scope(s): system
"identity:create_service": "role:admin and system_scope:all"

# DEPRECATED "identity:create_service":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_service":"role:admin
# and system_scope:all".
#
# As of the Stein release, the service API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service API.
#"identity:create_service": "rule:identity:create_service"
# Update service.
# PATCH  /v3/services/{service_id}
# Intended scope(s): system
"identity:update_service": "role:admin and system_scope:all"

# DEPRECATED "identity:update_service":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_service":"role:admin
# and system_scope:all".
#
# As of the Stein release, the service API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service API.
#"identity:update_service": "rule:identity:update_service"
# Delete service.
# DELETE  /v3/services/{service_id}
# Intended scope(s): system
"identity:delete_service": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_service":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_service":"role:admin
# and system_scope:all".
#
# As of the Stein release, the service API now understands default
# roles and system-scoped tokens, making the API more granular by
# default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service API.
#"identity:delete_service": "rule:identity:delete_service"
# Create federated service provider.
# PUT  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
"identity:create_service_provider": "role:admin and system_scope:all"

# DEPRECATED "identity:create_service_provider":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:create_service_provider":"role:admin and
# system_scope:all".
#
# As of the Stein release, the service provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service provider API.
#"identity:create_service_provider": "rule:identity:create_service_provider"
# List federated service providers.
# GET  /v3/OS-FEDERATION/service_providers
# HEAD  /v3/OS-FEDERATION/service_providers
# Intended scope(s): system
"identity:list_service_providers": "role:reader and system_scope:all"

# DEPRECATED "identity:list_service_providers":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:list_service_providers":"role:reader and
# system_scope:all".
#
# As of the Stein release, the service provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service provider API.
#"identity:list_service_providers": "rule:identity:list_service_providers"
# Get federated service provider.
# GET  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# HEAD  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
"identity:get_service_provider": "role:reader and system_scope:all"

# DEPRECATED "identity:get_service_provider":"rule:admin_required" has
# been deprecated since S in favor of
# "identity:get_service_provider":"role:reader and system_scope:all".
#
# As of the Stein release, the service provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service provider API.
#"identity:get_service_provider": "rule:identity:get_service_provider"
# Update federated service provider.
# PATCH  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
"identity:update_service_provider": "role:admin and system_scope:all"

# DEPRECATED "identity:update_service_provider":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:update_service_provider":"role:admin and
# system_scope:all".
#
# As of the Stein release, the service provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service provider API.
#"identity:update_service_provider": "rule:identity:update_service_provider"
# Delete federated service provider.
# DELETE  /v3/OS-FEDERATION/service_providers/{service_provider_id}
# Intended scope(s): system
"identity:delete_service_provider": "role:admin and system_scope:all"

# DEPRECATED "identity:delete_service_provider":"rule:admin_required"
# has been deprecated since S in favor of
# "identity:delete_service_provider":"role:admin and
# system_scope:all".
#
# As of the Stein release, the service provider API now understands
# default roles and system-scoped tokens, making the API more granular
# by default without compromising security. The new policy defaults
# account for these changes automatically. Be sure to take these new
# defaults into consideration if you are relying on overrides in your
# deployment for the service provider API.
#"identity:delete_service_provider": "rule:identity:delete_service_provider"
# List revoked PKI tokens.
# GET  /v3/auth/tokens/OS-PKI/revoked
# Intended scope(s): system, project
#"identity:revocation_list": "rule:service_or_admin"

# Check a token.
# HEAD  /v3/auth/tokens
#"identity:check_token": "rule:admin_or_token_subject"

# Validate a token.
# GET  /v3/auth/tokens
#"identity:validate_token": "rule:service_admin_or_token_subject"

# Revoke a token.
# DELETE  /v3/auth/tokens
#"identity:revoke_token": "rule:admin_or_token_subject"

# Create trust.
# POST  /v3/OS-TRUST/trusts
# Intended scope(s): project
#"identity:create_trust": "user_id:%(trust.trustor_user_id)s"

# List trusts.
# GET  /v3/OS-TRUST/trusts
# HEAD  /v3/OS-TRUST/trusts
# Intended scope(s): project
#"identity:list_trusts": ""

# List roles delegated by a trust.
# GET  /v3/OS-TRUST/trusts/{trust_id}/roles
# HEAD  /v3/OS-TRUST/trusts/{trust_id}/roles
# Intended scope(s): project
#"identity:list_roles_for_trust": ""

# Check if trust delegates a particular role.
# GET  /v3/OS-TRUST/trusts/{trust_id}/roles/{role_id}
# HEAD  /v3/OS-TRUST/trusts/{trust_id}/roles/{role_id}
# Intended scope(s): project
#"identity:get_role_for_trust": ""

# Revoke trust.
# DELETE  /v3/OS-TRUST/trusts/{trust_id}
# Intended scope(s): project
#"identity:delete_trust": ""

# Get trust.
# GET  /v3/OS-TRUST/trusts/{trust_id}
# HEAD  /v3/OS-TRUST/trusts/{trust_id}
# Intended scope(s): project
#"identity:get_trust": ""

# Show user details.
# GET  /v3/users/{user_id}
# HEAD  /v3/users/{user_id}
# Intended scope(s): system, domain, project
"identity:get_user": "(role:reader and system_scope:all) or (role:reader and token.domain.id:%(target.user.domain_id)s) or user_id:%(target.user.id)s"

# DEPRECATED "identity:get_user":"rule:admin_or_owner" has been
# deprecated since S in favor of "identity:get_user":"(role:reader and
# system_scope:all) or (role:reader and
# token.domain.id:%(target.user.domain_id)s) or
# user_id:%(target.user.id)s".
#
# As of the Stein release, the user API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:get_user": "rule:identity:get_user"
# List users.
# GET  /v3/users
# HEAD  /v3/users
# Intended scope(s): system, domain
"identity:list_users": "(role:reader and system_scope:all) or (role:reader and domain_id:%(target.domain_id)s)"

# DEPRECATED "identity:list_users":"rule:admin_required" has been
# deprecated since S in favor of "identity:list_users":"(role:reader
# and system_scope:all) or (role:reader and
# domain_id:%(target.domain_id)s)".
#
# As of the Stein release, the user API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:list_users": "rule:identity:list_users"
# List all projects a user has access to via role assignments.
# GET   /v3/auth/projects
#"identity:list_projects_for_user": ""

# List all domains a user has access to via role assignments.
# GET  /v3/auth/domains
#"identity:list_domains_for_user": ""

# Create a user.
# POST  /v3/users
# Intended scope(s): system, domain
"identity:create_user": "(role:admin and system_scope:all) or (role:admin and token.domain.id:%(target.user.domain_id)s)"

# DEPRECATED "identity:create_user":"rule:admin_required" has been
# deprecated since S in favor of "identity:create_user":"(role:admin
# and system_scope:all) or (role:admin and
# token.domain.id:%(target.user.domain_id)s)".
#
# As of the Stein release, the user API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:create_user": "rule:identity:create_user"
# Update a user, including administrative password resets.
# PATCH  /v3/users/{user_id}
# Intended scope(s): system, domain
"identity:update_user": "(role:admin and system_scope:all) or (role:admin and token.domain.id:%(target.user.domain_id)s)"

# DEPRECATED "identity:update_user":"rule:admin_required" has been
# deprecated since S in favor of "identity:update_user":"(role:admin
# and system_scope:all) or (role:admin and
# token.domain.id:%(target.user.domain_id)s)".
#
# As of the Stein release, the user API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:update_user": "rule:identity:update_user"
# Delete a user.
# DELETE  /v3/users/{user_id}
# Intended scope(s): system, domain
"identity:delete_user": "(role:admin and system_scope:all) or (role:admin and token.domain.id:%(target.user.domain_id)s)"

# DEPRECATED "identity:delete_user":"rule:admin_required" has been
# deprecated since S in favor of "identity:delete_user":"(role:admin
# and system_scope:all) or (role:admin and
# token.domain.id:%(target.user.domain_id)s)".
#
# As of the Stein release, the user API understands how to handle
# system-scoped tokens in addition to project and domain tokens,
# making the API more accessible to users without compromising
# security or manageability for administrators. The new default
# policies for this API account for these changes automatically.
#"identity:delete_user": "rule:identity:delete_user"
