# CCloud-specific admin identification
context_is_cloud_admin: role:cloud_compute_admin
context_is_cloud_viewer: context_is_cloud_admin or role:cloud_compute_viewer

### 
# Grant read access to everything, but no write access, to the cloud_compute_viewer role
###
# List resource providers.
# GET  /resource_providers
# Intended scope(s): project
placement:resource_providers:list: rule:context_is_cloud_viewer

# Show resource provider.
# GET  /resource_providers/{uuid}
# Intended scope(s): project
placement:resource_providers:show:  rule:context_is_cloud_viewer

# List resource classes.
# GET  /resource_classes
# Intended scope(s): project
placement:resource_classes:list: rule:context_is_cloud_viewer

# Show resource class.
# GET  /resource_classes/{name}
# Intended scope(s): project
placement:resource_classes:show: rule:context_is_cloud_viewer

# List resource provider inventories.
# GET  /resource_providers/{uuid}/inventories
# Intended scope(s): project
placement:resource_providers:inventories:list: rule:context_is_cloud_viewer

# Show resource provider inventory.
# GET  /resource_providers/{uuid}/inventories/{resource_class}
# Intended scope(s): project
placement:resource_providers:inventories:show: rule:context_is_cloud_viewer

# List resource provider aggregates.
# GET  /resource_providers/{uuid}/aggregates
# Intended scope(s): project
placement:resource_providers:aggregates:list: rule:context_is_cloud_viewer

# List resource provider usages.
# GET  /resource_providers/{uuid}/usages
# Intended scope(s): project
placement:resource_providers:usages: rule:context_is_cloud_viewer

# List traits.
# GET  /traits
# Intended scope(s): project
placement:traits:list: rule:context_is_cloud_viewer

# Show trait.
# GET  /traits/{name}
# Intended scope(s): project
placement:traits:show: rule:context_is_cloud_viewer

# List resource provider traits.
# GET  /resource_providers/{uuid}/traits
# Intended scope(s): project
placement:resource_providers:traits:list: rule:context_is_cloud_viewer

# List allocations.
# GET  /allocations/{consumer_uuid}
# Intended scope(s): project
placement:allocations:list: rule:context_is_cloud_viewer

# List resource provider allocations.
# GET  /resource_providers/{uuid}/allocations
# Intended scope(s): project
placement:resource_providers:allocations:list: rule:context_is_cloud_viewer

# List allocation candidates.
# GET  /allocation_candidates
# Intended scope(s): project
placement:allocation_candidates:list: rule:context_is_cloud_viewer

###
# dalmatian changes to the policy
###
# Default rule for service-to-service placement APIs.
# Intended scope(s): project
#"service_api": "role:service"
"service_api": "rule:context_is_cloud_admin"

# Default rule for most placement APIs.
# Intended scope(s): project
#"admin_or_service_api": "role:admin or role:service"
"admin_or_service_api": "rule:context_is_cloud_admin"

# Default rule for Project level reader APIs.
# only used in rule:admin_or_project_reader_or_service_api
#"project_reader_api": "role:compute_viewer and project_id:%(project_id)s"

# Default rule for project level reader APIs.
# Intended scope(s): project
# only used for /usages
#"admin_or_project_reader_or_service_api": "role:admin or rule:project_reader_api or role:service"
"admin_or_project_reader_or_service_api": "rule:context_is_cloud_admin or rule:project_reader_api or rule:context_is_cloud_viewer"

###
# yoga-specific changes to the policy
###
"system_admin_api": "( role:admin and system_scope:all ) or rule:context_is_cloud_admin"
"system_reader_api": "( role:reader and system_scope:all ) or rule:system_admin_api"
