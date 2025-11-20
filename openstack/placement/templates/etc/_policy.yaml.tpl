# CCloud-specific admin identification
"context_is_cloud_admin": "role:cloud_compute_admin"

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
"admin_or_project_reader_or_service_api": "rule:context_is_cloud_admin or rule:project_reader_api"

###
# yoga-specific changes to the policy
###
"system_admin_api": "( role:admin and system_scope:all ) or rule:context_is_cloud_admin"
"system_reader_api": "( role:reader and system_scope:all ) or rule:system_admin_api"
