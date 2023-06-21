# CCloud-specific admin identification
"context_is_cloud_admin": "role:cloud_compute_admin"

# Default rule for System Admin APIs.
#"system_admin_api": "role:admin and system_scope:all"
"system_admin_api": "( role:admin and system_scope:all ) or rule:context_is_cloud_admin"

# Default rule for System level read only APIs.
#"system_reader_api": "role:reader and system_scope:all"
"system_reader_api": "( role:reader and system_scope:all ) or rule:system_admin_api"

# Default rule for Project level read only APIs.
#"project_reader_api": "role:reader and project_id:%(project_id)s"

# Default rule for System+Project read only APIs.
#"system_or_project_reader": "rule:system_reader_api or rule:project_reader_api"

# List resource providers.
# GET  /resource_providers
# Intended scope(s): system
#"placement:resource_providers:list": "rule:system_reader_api"

# Create resource provider.
# POST  /resource_providers
# Intended scope(s): system
#"placement:resource_providers:create": "rule:system_admin_api"

# Show resource provider.
# GET  /resource_providers/{uuid}
# Intended scope(s): system
#"placement:resource_providers:show": "rule:system_reader_api"

# Update resource provider.
# PUT  /resource_providers/{uuid}
# Intended scope(s): system
#"placement:resource_providers:update": "rule:system_admin_api"

# Delete resource provider.
# DELETE  /resource_providers/{uuid}
# Intended scope(s): system
#"placement:resource_providers:delete": "rule:system_admin_api"

# List resource classes.
# GET  /resource_classes
# Intended scope(s): system
#"placement:resource_classes:list": "rule:system_reader_api"

# Create resource class.
# POST  /resource_classes
# Intended scope(s): system
#"placement:resource_classes:create": "rule:system_admin_api"

# Show resource class.
# GET  /resource_classes/{name}
# Intended scope(s): system
#"placement:resource_classes:show": "rule:system_reader_api"

# Update resource class.
# PUT  /resource_classes/{name}
# Intended scope(s): system
#"placement:resource_classes:update": "rule:system_admin_api"

# Delete resource class.
# DELETE  /resource_classes/{name}
# Intended scope(s): system
#"placement:resource_classes:delete": "rule:system_admin_api"

# List resource provider inventories.
# GET  /resource_providers/{uuid}/inventories
# Intended scope(s): system
#"placement:resource_providers:inventories:list": "rule:system_reader_api"

# Create one resource provider inventory.
# POST  /resource_providers/{uuid}/inventories
# Intended scope(s): system
#"placement:resource_providers:inventories:create": "rule:system_admin_api"

# Show resource provider inventory.
# GET  /resource_providers/{uuid}/inventories/{resource_class}
# Intended scope(s): system
#"placement:resource_providers:inventories:show": "rule:system_reader_api"

# Update resource provider inventory.
# PUT  /resource_providers/{uuid}/inventories
# PUT  /resource_providers/{uuid}/inventories/{resource_class}
# Intended scope(s): system
#"placement:resource_providers:inventories:update": "rule:system_admin_api"

# Delete resource provider inventory.
# DELETE  /resource_providers/{uuid}/inventories
# DELETE  /resource_providers/{uuid}/inventories/{resource_class}
# Intended scope(s): system
#"placement:resource_providers:inventories:delete": "rule:system_admin_api"

# List resource provider aggregates.
# GET  /resource_providers/{uuid}/aggregates
# Intended scope(s): system
#"placement:resource_providers:aggregates:list": "rule:system_reader_api"

# Update resource provider aggregates.
# PUT  /resource_providers/{uuid}/aggregates
# Intended scope(s): system
#"placement:resource_providers:aggregates:update": "rule:system_admin_api"

# List resource provider usages.
# GET  /resource_providers/{uuid}/usages
# Intended scope(s): system
#"placement:resource_providers:usages": "rule:system_reader_api"

# List total resource usages for a given project.
# GET  /usages
# Intended scope(s): system, project
#"placement:usages": "rule:system_or_project_reader"

# List traits.
# GET  /traits
# Intended scope(s): system
#"placement:traits:list": "rule:system_reader_api"

# Show trait.
# GET  /traits/{name}
# Intended scope(s): system
#"placement:traits:show": "rule:system_reader_api"

# Update trait.
# PUT  /traits/{name}
# Intended scope(s): system
#"placement:traits:update": "rule:system_admin_api"

# Delete trait.
# DELETE  /traits/{name}
# Intended scope(s): system
#"placement:traits:delete": "rule:system_admin_api"

# List resource provider traits.
# GET  /resource_providers/{uuid}/traits
# Intended scope(s): system
#"placement:resource_providers:traits:list": "rule:system_reader_api"

# Update resource provider traits.
# PUT  /resource_providers/{uuid}/traits
# Intended scope(s): system
#"placement:resource_providers:traits:update": "rule:system_admin_api"

# Delete resource provider traits.
# DELETE  /resource_providers/{uuid}/traits
# Intended scope(s): system
#"placement:resource_providers:traits:delete": "rule:system_admin_api"

# Manage allocations.
# POST  /allocations
# Intended scope(s): system
#"placement:allocations:manage": "rule:system_admin_api"

# List allocations.
# GET  /allocations/{consumer_uuid}
# Intended scope(s): system
#"placement:allocations:list": "rule:system_reader_api"

# Update allocations.
# PUT  /allocations/{consumer_uuid}
# Intended scope(s): system
#"placement:allocations:update": "rule:system_admin_api"

# Delete allocations.
# DELETE  /allocations/{consumer_uuid}
# Intended scope(s): system
#"placement:allocations:delete": "rule:system_admin_api"

# List resource provider allocations.
# GET  /resource_providers/{uuid}/allocations
# Intended scope(s): system
#"placement:resource_providers:allocations:list": "rule:system_reader_api"

# List allocation candidates.
# GET  /allocation_candidates
# Intended scope(s): system
#"placement:allocation_candidates:list": "rule:system_reader_api"

# Reshape Inventory and Allocations.
# POST  /reshaper
# Intended scope(s): system
#"placement:reshaper:reshape": "rule:system_admin_api"

