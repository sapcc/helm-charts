# Decides what is required for the 'is_admin:True' check to succeed.
#context_is_admin: role:admin
context_is_admin: role:cloud_compute_admin

owner_or_no_project: project_id:%(project_id)s or ccloud_no_project_id_in_target:True
member: role:member and rule:owner_or_no_project
viewer: (role:compute_viewer and rule:owner_or_no_project) or role:cloud_compute_viewer 
admin: (role:compute_admin or role:compute_admin_wsg) and rule:owner_or_no_project
context_is_compute_admin: rule:context_is_admin or rule:admin
context_is_editor: rule:context_is_compute_admin or rule:member
context_is_viewer: rule:context_is_editor or rule:viewer
compute_admin_all: role:compute_admin or role:cloud_compute_admin

context_is_quota_admin: role:resource_service
context_is_cloud_viewer: role:cloud_compute_viewer
context_is_cloud_compute_migrate: role:cloud_compute_migrate

### Upstream base rules
# Default rule for most Admin APIs.
#admin_api: is_admin:True
# Default rule for most non-Admin APIs.
#admin_or_owner: is_admin:True or project_id:%(project_id)s
# Default rule for Project level admin APIs.
#project_admin_api: role:admin and project_id:%(project_id)s
# Default rule for Project level non admin APIs.
#project_member_api: role:member and project_id:%(project_id)s
# Default rule for Project level read only APIs.
#project_reader_api: role:reader and project_id:%(project_id)s
# Default rule for System Admin APIs.
#system_admin_api: role:admin and system_scope:all
# Default rule for System admin+owner APIs.
#system_admin_or_owner: rule:system_admin_api or rule:project_member_api
# Default rule for System+Project read only APIs.
#system_or_project_reader: rule:system_reader_api or rule:project_reader_api
# Default rule for System level read only APIs.
#system_reader_api: role:reader and system_scope:all


# Attach an unshared external network to a server
#   POST /servers
#   POST /servers/{server_id}/os-interface
network:attach_external_network: rule:context_is_admin

# List all servers with detailed information for  all projects
#   GET /servers/detail
os_compute_api:servers:detail:get_all_tenants: rule:context_is_admin or rule:context_is_cloud_viewer

# List all servers for all projects
#   GET /servers
os_compute_api:servers:index:get_all_tenants: rule:context_is_admin or rule:context_is_cloud_viewer

# Confirm a server resize
#   POST /servers/{server_id}/action (confirmResize)
os_compute_api:servers:confirm_resize: rule:context_is_editor

# Create a server
#   POST /servers
os_compute_api:servers:create: rule:context_is_editor

# Create a server with the requested network attached  to it
#   POST /servers
os_compute_api:servers:create:attach_network: rule:context_is_editor

# Create a server with the requested volume attached to it
#   POST /servers
os_compute_api:servers:create:attach_volume: rule:context_is_editor

# Create a server on the specified host and/or node.
# In this case, the server is forced to launch on the specified
# host and/or node by bypassing the scheduler filters unlike the
# compute:servers:create:requested_destination rule.
#   POST /servers
os_compute_api:servers:create:forced_host: rule:compute_admin_all

# Delete a server
#   DELETE /servers/{server_id}
os_compute_api:servers:delete: rule:context_is_editor

# Update a server
#   PUT /servers/{server_id}
os_compute_api:servers:update: rule:context_is_editor

# List all servers with detailed information
#   GET /servers/detail
os_compute_api:servers:detail: rule:context_is_viewer

# List all servers
#   GET /servers
os_compute_api:servers:index: rule:context_is_viewer

# Reboot a server
#   POST /servers/{server_id}/action (reboot)
os_compute_api:servers:reboot: rule:context_is_editor

# Rebuild a server
#   POST /servers/{server_id}/action (rebuild)
os_compute_api:servers:rebuild: rule:context_is_editor

# Resize a server
#   POST /servers/{server_id}/action (resize)
os_compute_api:servers:resize: rule:context_is_editor

# Revert a server resize
#   POST /servers/{server_id}/action (revertResize)
os_compute_api:servers:revert_resize: rule:context_is_editor

# Show a server
#   GET /servers/{server_id}
os_compute_api:servers:show: rule:context_is_viewer

# Show a server with additional host status information.
# This means host_status will be shown irrespective of status value. If showing
# only host_status UNKNOWN is desired, use the
# os_compute_api:servers:show:host_status:unknown-only policy rule.
# Microvision 2.75 added the host_status attribute in the
# PUT /servers/{server_id} and POST /servers/{server_id}/action (rebuild)
# API responses which are also controlled by this policy rule, like the
# GET /servers* APIs.
#   GET /servers/{server_id}
#   GET /servers/detail
#   PUT /servers/{server_id}
#   POST /servers/{server_id}/action (rebuild)
os_compute_api:servers:show:host_status: rule:context_is_admin or rule:context_is_cloud_viewer

# Create an image from a server
#   POST /servers/{server_id}/action (createImage)
os_compute_api:servers:create_image: rule:context_is_editor

# Create an image from a volume backed server
#   POST /servers/{server_id}/action (createImage)
os_compute_api:servers:create_image:allow_volume_backed: rule:context_is_editor

# Start a server
#   POST /servers/{server_id}/action (os-start)
os_compute_api:servers:start: rule:context_is_editor

# Stop a server
#   POST /servers/{server_id}/action (os-stop)
os_compute_api:servers:stop: rule:context_is_editor

# Trigger crash dump in a server
#   POST /servers/{server_id}/action (trigger_crash_dump)
os_compute_api:servers:trigger_crash_dump: rule:context_is_editor

# Force an in-progress live migration for a given server to complete
#   POST /servers/{server_id}/migrations/{migration_id}/action (force_complete)
os_compute_api:servers:migrations:force_complete: rule:context_is_admin or rule:context_is_cloud_compute_migrate

# Delete(Abort) an in-progress live migration
#   DELETE /servers/{server_id}/migrations/{migration_id}
os_compute_api:servers:migrations:delete: rule:context_is_admin or rule:context_is_cloud_compute_migrate

# Lists in-progress live migrations for a given server
#   GET /servers/{server_id}/migrations
os_compute_api:servers:migrations:index: rule:context_is_admin or rule:context_is_cloud_viewer or rule:context_is_cloud_compute_migrate

# Show details for an in-progress live migration for a given server
#   GET /servers/{server_id}/migrations/{migration_id}
os_compute_api:servers:migrations:show: rule:context_is_admin or rule:context_is_cloud_viewer or rule:context_is_cloud_compute_migrate

# Inject network information into the server
#   POST /servers/{server_id}/action (injectNetworkInfo)
os_compute_api:os-admin-actions:inject_network_info: rule:context_is_admin

# Reset the state of a given server
#   POST /servers/{server_id}/action (os-resetState)
os_compute_api:os-admin-actions:reset_state: rule:context_is_compute_admin

# Change the administrative password for a server
#   POST /servers/{server_id}/action (changePassword)
os_compute_api:os-admin-password: rule:context_is_editor

# List all aggregates
#   GET /os-aggregates
os_compute_api:os-aggregates:index: rule:context_is_admin or rule:context_is_cloud_viewer

# Create an aggregate
#   POST /os-aggregates
os_compute_api:os-aggregates:create: rule:context_is_admin

# Show details for an aggregate
#   GET /os-aggregates/{aggregate_id}
os_compute_api:os-aggregates:show: rule:context_is_admin or rule:context_is_cloud_viewer

# Update name and/or availability zone for an aggregate
#   PUT /os-aggregates/{aggregate_id}
os_compute_api:os-aggregates:update: rule:context_is_admin

# Delete an aggregate
#   DELETE /os-aggregates/{aggregate_id}
os_compute_api:os-aggregates:delete: rule:context_is_admin

# Add a host to an aggregate
#   POST /os-aggregates/{aggregate_id}/action (add_host)
os_compute_api:os-aggregates:add_host: rule:context_is_admin

# Remove a host from an aggregate
#   POST /os-aggregates/{aggregate_id}/action (remove_host)
os_compute_api:os-aggregates:remove_host: rule:context_is_admin

# Create or replace metadata for an aggregate
#   POST /os-aggregates/{aggregate_id}/action (set_metadata)
os_compute_api:os-aggregates:set_metadata: rule:context_is_admin

# Attach an interface to a server
#   POST /servers/{server_id}/os-interface
os_compute_api:os-attach-interfaces:create: rule:context_is_editor

# Detach an interface from a server
#   DELETE /servers/{server_id}/os-interface/{port_id}
os_compute_api:os-attach-interfaces:delete: rule:context_is_editor

# List port interfaces attached to a server
#   GET /servers/{server_id}/os-interface
os_compute_api:os-attach-interfaces:list: rule:context_is_editor or rule:context_is_cloud_viewer

# Show details of a port interface attached to a server
#   GET /servers/{server_id}/os-interface/{port_id}
os_compute_api:os-attach-interfaces:show: rule:context_is_editor or rule:context_is_cloud_viewer

# Show action details for a server.
#   GET /os-baremetal-nodes/{node_id}
os_compute_api:os-baremetal-nodes:show: rule:context_is_admin or rule:context_is_cloud_viewer

# Show console output for a server
#   POST /servers/{server_id}/action (os-getConsoleOutput)
os_compute_api:os-console-output: rule:context_is_editor

# Generate a URL to access remove server console.
# This policy is for POST /remote-consoles API and below Server actions APIs
# are deprecated:
#
# os-getRDPConsole
# os-getSerialConsole
# os-getSPICEConsole
# os-getVNCConsole.
#   POST /servers/{server_id}/action (os-getRDPConsole)
#   POST /servers/{server_id}/action (os-getSerialConsole)
#   POST /servers/{server_id}/action (os-getSPICEConsole)
#   POST /servers/{server_id}/action (os-getVNCConsole)
#   POST /servers/{server_id}/remote-consoles
os_compute_api:os-remote-consoles: rule:context_is_editor

# Create a back up of a server
#   POST /servers/{server_id}/action (createBackup)
os_compute_api:os-create-backup: rule:context_is_editor

# Restore a soft deleted server
#   POST /servers/{server_id}/action (restore)
os_compute_api:os-deferred-delete:restore: rule:context_is_editor

# Force delete a server before deferred cleanup
#   POST /servers/{server_id}/action (forceDelete)
os_compute_api:os-deferred-delete:force: rule:context_is_editor

# Evacuate a server from a failed host to a new host
#   POST /servers/{server_id}/action (evacuate)
os_compute_api:os-evacuate: rule:context_is_admin

# Return extended attributes for server.
# This rule will control the visibility for a set of servers attributes:
#
#   - OS-EXT-SRV-ATTR:host
#   - OS-EXT-SRV-ATTR:instance_name
#   - OS-EXT-SRV-ATTR:reservation_id (since microversion 2.3)
#   - OS-EXT-SRV-ATTR:launch_index (since microversion 2.3)
#   - OS-EXT-SRV-ATTR:hostname (since microversion 2.3)
#   - OS-EXT-SRV-ATTR:kernel_id (since microversion 2.3)
#   - OS-EXT-SRV-ATTR:ramdisk_id (since microversion 2.3)
#   - OS-EXT-SRV-ATTR:root_device_name (since microversion 2.3)
#   - OS-EXT-SRV-ATTR:user_data (since microversion 2.3)
#
# Microvision 2.75 added the above attributes in the PUT /servers/{server_id}
# and POST /servers/{server_id}/action (rebuild) API responses which are
# also controlled by this policy rule, like the GET /servers* APIs.
# Microversion 2.90 made the OS-EXT-SRV-ATTR:hostname attribute available to
# all users, so this policy has no effect on that field for microversions 2.90
# and greater. Controlling the visibility of this attribute for all microversions
# is therefore deprecated and will be removed in a future release.
#   GET /servers/{id}
#   GET /servers/detail
#   PUT /servers/{server_id}
#   POST /servers/{server_id}/action (rebuild)
os_compute_api:os-extended-server-attributes: rule:context_is_viewer

# List available extensions and show information for an extension by alias
#   GET /extensions
#   GET /extensions/{alias}
os_compute_api:extensions: rule:context_is_viewer

# List flavor access information
# Allows access to the full list of tenants that have access
# to a flavor via an os-flavor-access API.
#   GET /flavors/{flavor_id}/os-flavor-access
os_compute_api:os-flavor-access: rule:context_is_editor or rule:context_is_cloud_viewer

# Remove flavor access from a tenant
#   POST /flavors/{flavor_id}/action (removeTenantAccess)
os_compute_api:os-flavor-access:remove_tenant_access: rule:context_is_admin

# Add flavor access to a tenant
#   POST /flavors/{flavor_id}/action (addTenantAccess)
os_compute_api:os-flavor-access:add_tenant_access: rule:context_is_admin

# List extra specs for a flavor. Starting with microversion 2.47, the flavor
# used for a server is also returned in the response when showing server details,
# updating a server or rebuilding a server. Starting with microversion 2.61,
# extra specs may be returned in responses for the flavor resource.
#   GET /flavors/{flavor_id}/os-extra_specs/
#   GET /servers/detail
#   GET /servers/{server_id}
#   PUT /servers/{server_id}
#   POST /servers/{server_id}/action (rebuild)
#   POST /flavors
#   GET /flavors/detail
#   GET /flavors/{flavor_id}
#   PUT /flavors/{flavor_id}
os_compute_api:os-flavor-extra-specs:index: rule:context_is_viewer

# Show an extra spec for a flavor
#   GET /flavors/{flavor_id}/os-extra_specs/{flavor_extra_spec_key}
os_compute_api:os-flavor-extra-specs:show: rule:context_is_viewer

# Create extra specs for a flavor
#   POST /flavors/{flavor_id}/os-extra_specs/
os_compute_api:os-flavor-extra-specs:create: rule:context_is_admin

# Update an extra spec for a flavor
#   PUT /flavors/{flavor_id}/os-extra_specs/{flavor_extra_spec_key}
os_compute_api:os-flavor-extra-specs:update: rule:context_is_admin

# Delete an extra spec for a flavor
#   DELETE /flavors/{flavor_id}/os-extra_specs/{flavor_extra_spec_key}
os_compute_api:os-flavor-extra-specs:delete: rule:context_is_admin

# Create a flavor
#   POST /flavors
os_compute_api:os-flavor-manage:create: rule:context_is_admin

# Update a flavor
#   PUT /flavors/{flavor_id}
os_compute_api:os-flavor-manage:update: rule:context_is_admin

# Delete a flavor
#   DELETE /flavors/{flavor_id}
os_compute_api:os-flavor-manage:delete: rule:context_is_admin

# List all hypervisors.
#   GET /os-hypervisors
os_compute_api:os-hypervisors:list: rule:context_is_admin or rule:context_is_cloud_viewer

# List all hypervisors with details
#   GET /os-hypervisors/details
os_compute_api:os-hypervisors:list-detail: rule:context_is_admin or rule:context_is_cloud_viewer

# Search hypervisor by hypervisor_hostname pattern.
#   GET /os-hypervisors/{hypervisor_hostname_pattern}/search
os_compute_api:os-hypervisors:search: rule:context_is_admin or rule:context_is_cloud_viewer

# List all servers on hypervisors that can match the provided hypervisor_hostname pattern.
#   GET /os-hypervisors/{hypervisor_hostname_pattern}/servers
os_compute_api:os-hypervisors:servers: rule:context_is_admin or rule:context_is_cloud_viewer

# Show details for a hypervisor.
#   GET /os-hypervisors/{hypervisor_id}
os_compute_api:os-hypervisors:show: rule:context_is_admin or rule:context_is_cloud_viewer

# Show summary statistics for all hypervisors over all compute nodes.
#   GET /os-hypervisors/statistics
os_compute_api:os-hypervisors:statistics: rule:context_is_admin or rule:context_is_cloud_viewer

# Show the uptime of a hypervisor.
#   GET /os-hypervisors/{hypervisor_id}/uptime
os_compute_api:os-hypervisors:uptime: rule:context_is_admin or rule:context_is_cloud_viewer

# List actions for a server.
#   GET /servers/{server_id}/os-instance-actions
os_compute_api:os-instance-actions:list: rule:context_is_viewer

# Show action details for a server.
#   GET /servers/{server_id}/os-instance-actions/{request_id}
os_compute_api:os-instance-actions:show: rule:context_is_editor or rule:context_is_cloud_viewer

# Add events details in action details for a server.
# This check is performed only after the check
# os_compute_api:os-instance-actions:show passes. Beginning with Microversion
# 2.51, events details are always included; traceback information is provided
# per event if policy enforcement passes. Beginning with Microversion 2.62,
# each event includes a hashed host identifier and, if policy enforcement
# passes, the name of the host.
#   GET /servers/{server_id}/os-instance-actions/{request_id}
os_compute_api:os-instance-actions:events: rule:context_is_admin or rule:context_is_cloud_viewer

# List all usage audits.
#   GET /os-instance_usage_audit_log
os_compute_api:os-instance-usage-audit-log:list: rule:context_is_admin or rule:context_is_cloud_viewer

# List all usage audits occurred before a specified time for all servers on all
# compute hosts where usage auditing is configured
#   GET /os-instance_usage_audit_log/{before_timestamp}
os_compute_api:os-instance-usage-audit-log:show: rule:context_is_admin or rule:context_is_cloud_viewer

# List IP addresses that are assigned to a server
#   GET /servers/{server_id}/ips
os_compute_api:ips:index: rule:context_is_viewer

# Show IP addresses details for a network label of a  server
#   GET /servers/{server_id}/ips/{network_label}
os_compute_api:ips:show: rule:context_is_viewer

# List all keypairs
#   GET /os-keypairs
os_compute_api:os-keypairs:index: rule:context_is_admin or user_id:%(user_id)s or rule:context_is_cloud_viewer

# Show details of a keypair
#   GET /os-keypairs/{keypair_name}
os_compute_api:os-keypairs:show: rule:context_is_admin or user_id:%(user_id)s or rule:context_is_cloud_viewer

# Create a keypair
#   POST /os-keypairs
os_compute_api:os-keypairs:create: rule:context_is_admin or user_id:%(user_id)s

# Delete a keypair
#   DELETE /os-keypairs/{keypair_name}
os_compute_api:os-keypairs:delete: rule:context_is_admin or user_id:%(user_id)s

# Show rate and absolute limits for the current user project
#   GET /limits
os_compute_api:limits: rule:context_is_viewer

# Lock a server
#   POST /servers/{server_id}/action (lock)
os_compute_api:os-lock-server:lock: rule:context_is_compute_admin

# Unlock a server
#   POST /servers/{server_id}/action (unlock)
os_compute_api:os-lock-server:unlock: rule:context_is_compute_admin

# Unlock a server, regardless who locked the server.
# This check is performed only after the check
# os_compute_api:os-lock-server:unlock passes
#   POST /servers/{server_id}/action (unlock)
os_compute_api:os-lock-server:unlock:unlock_override: rule:context_is_admin

# Cold migrate a server to a host
#   POST /servers/{server_id}/action (migrate)
os_compute_api:os-migrate-server:migrate: rule:context_is_admin or rule:context_is_cloud_compute_migrate

# Cold migrate a server to a specified host
# POST  /servers/{server_id}/action (migrate)
# Intended scope(s): project
os_compute_api:os-migrate-server:migrate:host: rule:context_is_admin or rule:context_is_cloud_compute_migrate

# Live migrate a server to a new host without a reboot
#   POST /servers/{server_id}/action (os-migrateLive)
os_compute_api:os-migrate-server:migrate_live: rule:context_is_admin or rule:context_is_cloud_compute_migrate

# Pause a server
#   POST /servers/{server_id}/action (pause)
os_compute_api:os-pause-server:pause: rule:context_is_editor

# Unpause a paused server
#   POST /servers/{server_id}/action (unpause)
os_compute_api:os-pause-server:unpause: rule:context_is_editor

# Show a quota
#   GET /os-quota-sets/{tenant_id}
os_compute_api:os-quota-sets:show: rule:context_is_viewer

# List default quotas
#   GET /os-quota-sets/{tenant_id}/defaults
os_compute_api:os-quota-sets:defaults: rule:context_is_viewer

# Update the quotas
#   PUT /os-quota-sets/{tenant_id}
os_compute_api:os-quota-sets:update: rule:context_is_quota_admin

# Revert quotas to defaults
#   DELETE /os-quota-sets/{tenant_id}
os_compute_api:os-quota-sets:delete: rule:context_is_quota_admin

# Show the detail of quota
#   GET /os-quota-sets/{tenant_id}/detail
os_compute_api:os-quota-sets:detail: rule:context_is_viewer

# Update quotas for specific quota class
#   PUT /os-quota-class-sets/{quota_class}
os_compute_api:os-quota-class-sets:update: rule:context_is_admin

# List quotas for specific quota classs
#   GET /os-quota-class-sets/{quota_class}
os_compute_api:os-quota-class-sets:show: rule:context_is_admin or quota_class:%(quota_class)s or rule:context_is_cloud_viewer

# Rescue a server
#   POST /servers/{server_id}/action (rescue)
os_compute_api:os-rescue: rule:context_is_editor

# Unrescue a server
#   POST /servers/{server_id}/action (unrescue)
os_compute_api:os-unrescue: rule:context_is_editor

# Show the usage data for a server
#   GET /servers/{server_id}/diagnostics
os_compute_api:os-server-diagnostics: rule:context_is_admin or rule:context_is_cloud_viewer

# Clear the encrypted administrative password of a server
#   DELETE /servers/{server_id}/os-server-password
os_compute_api:os-server-password:clear: rule:context_is_editor

# Show the encrypted administrative password of a server
#   GET /servers/{server_id}/os-server-password
os_compute_api:os-server-password:show: rule:context_is_editor or rule:context_is_cloud_viewer

# Create a new server group
#   POST /os-server-groups
os_compute_api:os-server-groups:create: rule:context_is_editor

# Delete a server group
#   DELETE /os-server-groups/{server_group_id}
os_compute_api:os-server-groups:delete: rule:context_is_editor

# List all server groups
#   GET /os-server-groups
os_compute_api:os-server-groups:index: rule:context_is_editor or rule:context_is_cloud_viewer

# List all server groups for all projects
#   GET /os-server-groups
os_compute_api:os-server-groups:index:all_projects: rule:context_is_admin or rule:context_is_cloud_viewer

# Show details of a server group
#   GET /os-server-groups/{server_group_id}
os_compute_api:os-server-groups:show: rule:context_is_editor or rule:context_is_cloud_viewer

# Edit details of a server group
# [SAP-custom API extension]
#   PUT /os-server-groups/{server_group_id}
os_compute_api:os-server-groups:update: rule:context_is_editor

# Delete a Compute service.
#   DELETE /os-services/{service_id}
os_compute_api:os-services:delete: rule:context_is_admin

# List all running Compute services in a region.
#   GET /os-services
os_compute_api:os-services:list: rule:context_is_admin or rule:context_is_cloud_viewer

# Update a Compute service.
#   PUT /os-services/{service_id}
os_compute_api:os-services:update: rule:context_is_admin

# List all metadata of a server
#   GET /servers/{server_id}/metadata
os_compute_api:server-metadata:index: rule:context_is_viewer

# Show metadata for a server
#   GET /servers/{server_id}/metadata/{key}
os_compute_api:server-metadata:show: rule:context_is_viewer

# Delete metadata from a server
#   DELETE /servers/{server_id}/metadata/{key}
os_compute_api:server-metadata:delete: rule:context_is_editor

# Create metadata for a server
#   POST /servers/{server_id}/metadata
os_compute_api:server-metadata:create: rule:context_is_editor

# Update metadata from a server
#   PUT /servers/{server_id}/metadata/{key}
os_compute_api:server-metadata:update: rule:context_is_editor

# Replace metadata for a server
#   PUT /servers/{server_id}/metadata
os_compute_api:server-metadata:update_all: rule:context_is_editor

# Shelve server
#   POST /servers/{server_id}/action (shelve)
os_compute_api:os-shelve:shelve: rule:context_is_editor

# Shelf-offload (remove) server
#   POST /servers/{server_id}/action (shelveOffload)
os_compute_api:os-shelve:shelve_offload: rule:context_is_admin

# Show usage statistics for a specific tenant
#   GET /os-simple-tenant-usage/{tenant_id}
os_compute_api:os-simple-tenant-usage:show: rule:context_is_viewer

# List per tenant usage statistics for all tenants
#   GET /os-simple-tenant-usage
os_compute_api:os-simple-tenant-usage:list: rule:context_is_admin or rule:context_is_cloud_viewer

# Suspend server
#   POST /servers/{server_id}/action (suspend)
os_compute_api:os-suspend-server:suspend: rule:context_is_editor

# Resume suspended server
#   POST /servers/{server_id}/action (resume)
os_compute_api:os-suspend-server:resume: rule:context_is_editor

# Unshelve (restore) shelved server
#   POST /servers/{server_id}/action (unshelve)
os_compute_api:os-shelve:unshelve: rule:context_is_editor

# List volume attachments for an instance
#   GET /servers/{server_id}/os-volume_attachments
os_compute_api:os-volumes-attachments:index: rule:context_is_viewer

# Show details of a volume attachment
#   GET /servers/{server_id}/os-volume_attachments/{volume_id}
os_compute_api:os-volumes-attachments:show: rule:context_is_viewer

# Attach a volume to an instance
#   POST /servers/{server_id}/os-volume_attachments
os_compute_api:os-volumes-attachments:create: rule:context_is_editor

# Update a volume attachment.
# New 'update' policy about 'swap + update' request (which is possible
# only >2.85) only <swap policy> is checked. We expect <swap policy> to be
# always superset of this policy permission.
#   PUT /servers/{server_id}/os-volume_attachments/{volume_id}
os_compute_api:os-volumes-attachments:update: rule:context_is_editor

# Detach a volume from an instance
#   DELETE /servers/{server_id}/os-volume_attachments/{volume_id}
os_compute_api:os-volumes-attachments:delete: rule:context_is_editor

# List availability zone information without host information
#   GET /os-availability-zone
os_compute_api:os-availability-zone:list: rule:context_is_viewer

# List detailed availability zone information with host information
#   GET /os-availability-zone/detail
os_compute_api:os-availability-zone:detail: rule:context_is_admin or rule:context_is_cloud_viewer

# Show rate and absolute limits of other project.
# This policy only checks if the user has access to the requested
# project limits. And this check is performed only after the check
# os_compute_api:limits passes
#   GET /limits
os_compute_api:limits:other_project: rule:context_is_admin or rule:context_is_cloud_viewer

# List migrations
#   GET /os-migrations
os_compute_api:os-migrations:index: rule:context_is_admin or rule:context_is_cloud_viewer

# Create an assisted volume snapshot
#   POST /os-assisted-volume-snapshots
os_compute_api:os-assisted-volume-snapshots:create: rule:context_is_admin

# Delete an assisted volume snapshot
#   DELETE /os-assisted-volume-snapshots/{snapshot_id}
os_compute_api:os-assisted-volume-snapshots:delete: rule:context_is_admin

# Show console connection information for a given console authentication token
#   GET /os-console-auth-tokens/{console_token}
os_compute_api:os-console-auth-tokens: rule:context_is_admin or rule:context_is_cloud_viewer

# Create one or more external events
#   POST /os-server-external-events
os_compute_api:os-server-external-events:create: rule:context_is_admin

# Create a server on the requested compute service host and/or
# hypervisor_hostname.
# In this case, the requested host and/or hypervisor_hostname is
# validated by the scheduler filters unlike the
# os_compute_api:servers:create:forced_host rule.
#   POST /servers
compute:servers:create:requested_destination: rule:compute_admin_all

# List SAP admin API endpoints
# GET  /sap/endpoints
# Intended scope(s): system, project
#"os_compute_api:sap:endpoints:list": "rule:admin_api"
os_compute_api:sap:endpoints:list: rule:context_is_admin or rule:context_is_cloud_viewer

# vMotion a VM inside its cluster
# POST  /sap/in_cluster_vmotion
# Intended scope(s): system, project
#"os_compute_api:sap:in-cluster-vmotion": "rule:admin_api"
os_compute_api:sap:in-cluster-vmotion: rule:context_is_admin or rule:context_is_cloud_compute_migrate

# Expose the current scheduler settings
# GET  /sap/get_scheduler_settings
# Intended scope(s): system, project
#"os_compute_api:sap:get-scheduler-settings": "rule:admin_api"
os_compute_api:sap:get-scheduler-settings: rule:context_is_admin or rule:context_is_cloud_viewer