# CCloud-specific admin identification
"context_is_cloud_admin": "role:cloud_compute_admin"

# Default rule for most Admin APIs.
"admin_api": "rule:context_is_cloud_admin"

# List available extensions.
# GET  /extensions
#"os_masakari_api:extensions:index": "rule:admin_api"

# Shows information for an extension.
# GET  /extensions/{extensions_id}
#"os_masakari_api:extensions:detail": "rule:admin_api"

# Extension Info API extensions to change the API.
#"os_masakari_api:extensions:discoverable": "rule:admin_api"

# Lists IDs, names, type, reserved, on_maintenance for all hosts.
# GET  /segments/{segment_id}/hosts
#"os_masakari_api:os-hosts:index": "rule:admin_api"

# Shows details for a host.
# GET  /segments/{segment_id}/hosts/{host_id}
#"os_masakari_api:os-hosts:detail": "rule:admin_api"

# Creates a host under given segment.
# POST  /segments/{segment_id}/hosts
#"os_masakari_api:os-hosts:create": "rule:admin_api"

# Updates the editable attributes of an existing host.
# PUT  /segments/{segment_id}/hosts/{host_id}
#"os_masakari_api:os-hosts:update": "rule:admin_api"

# Deletes a host from given segment.
# DELETE  /segments/{segment_id}/hosts/{host_id}
#"os_masakari_api:os-hosts:delete": "rule:admin_api"

# Host API extensions to change the API.
#"os_masakari_api:os-hosts:discoverable": "rule:admin_api"

# Lists IDs, notification types, host_name, generated_time, payload
# and status for all notifications.
# GET  /notifications
#"os_masakari_api:notifications:index": "rule:admin_api"

# Shows details for a notification.
# GET  /notifications/{notification_id}
#"os_masakari_api:notifications:detail": "rule:admin_api"

# Creates a notification.
# POST  /notifications
#"os_masakari_api:notifications:create": "rule:admin_api"

# Notification API extensions to change the API.
#"os_masakari_api:notifications:discoverable": "rule:admin_api"

# Lists IDs, names, description, recovery_method, service_type for all
# segments.
# GET  /segments
#"os_masakari_api:segments:index": "rule:admin_api"

# Shows details for a segment.
# GET  /segments/{segment_id}
#"os_masakari_api:segments:detail": "rule:admin_api"

# Creates a segment.
# POST  /segments
#"os_masakari_api:segments:create": "rule:admin_api"

# Updates the editable attributes of an existing host.
# PUT  /segments/{segment_id}
#"os_masakari_api:segments:update": "rule:admin_api"

# Deletes a segment.
# DELETE  /segments/{segment_id}
#"os_masakari_api:segments:delete": "rule:admin_api"

# Segment API extensions to change the API.
#"os_masakari_api:segments:discoverable": "rule:admin_api"

# List all versions.
# GET  /
#"os_masakari_api:versions:index": "@"

# Version API extensions to change the API.
#"os_masakari_api:versions:discoverable": "@"

# Lists IDs, notification_id, instance_id, source_host, dest_host,
# status and type for all VM moves.
# GET  /notifications/{notification_id}/vmoves
#"os_masakari_api:vmoves:index": "rule:admin_api"

# Shows details for one VM move.
# GET  /notifications/{notification_id}/vmoves/{vmove_id}
#"os_masakari_api:vmoves:detail": "rule:admin_api"

# VM moves API extensions to change the API.
#"os_masakari_api:vmoves:discoverable": "rule:admin_api"
