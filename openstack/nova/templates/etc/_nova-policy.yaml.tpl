# ??
context_is_quota_admin: role:resource_service

# Decides what is required for the 'is_admin:True' check to succeed.
#context_is_admin: role:admin
context_is_admin: role:cloud_compute_admin

# ??
owner: project_id:%(project_id)s

# ??
member: role:member and rule:owner

# ??
viewer: role:compute_viewer and rule:owner

# ??
admin: (role:compute_admin or role:compute_admin_wsg) and rule:owner

# ??
context_is_compute_admin: is_admin:True or rule:admin

# ??
context_is_editor: rule:context_is_compute_admin or rule:member

# ??
context_is_viewer: rule:context_is_editor or rule:viewer

# ??
compute_admin_all: role:compute_admin or role:cloud_compute_admin

# ??
default: is_admin:True

# ??
network_admin: role:network_admin and rule:owner

# ??
context_is_network_admin: role:cloud_network_admin or rule:network_admin

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



# ??
compute:create: rule:context_is_editor

# ??
compute:create:attach_network: rule:context_is_editor

# ??
compute:create:attach_volume: rule:context_is_editor

# ??
compute:create:forced_host: rule:compute_admin_all

# ??
compute:get: rule:context_is_viewer

# ??
compute:get_all: rule:context_is_viewer

# ??
compute:get_all_tenants: is_admin:True

# ??
compute:update: rule:context_is_editor

# ??
compute:get_instance_metadata: rule:context_is_viewer

# ??
compute:get_all_instance_metadata: rule:context_is_viewer

# ??
compute:get_all_instance_system_metadata: rule:context_is_viewer

# ??
compute:update_instance_metadata: rule:context_is_editor

# ??
compute:delete_instance_metadata: rule:context_is_editor

# ??
compute:get_diagnostics: is_admin:True

# ??
compute:get_instance_diagnostics: is_admin:True

# ??
compute:start: rule:context_is_editor

# ??
compute:stop: rule:context_is_editor

# ??
compute:lock: rule:context_is_compute_admin

# ??
compute:unlock: rule:context_is_compute_admin

# ??
compute:unlock_override: is_admin:True

# ??
compute:get_vnc_console: rule:context_is_editor

# ??
compute:get_spice_console: rule:context_is_editor

# ??
compute:get_rdp_console: rule:context_is_editor

# ??
compute:get_serial_console: rule:context_is_editor

# ??
compute:get_mks_console: rule:context_is_editor

# ??
compute:get_console_output: rule:context_is_editor

# ??
compute:reset_network: rule:context_is_editor

# ??
compute:inject_network_info: rule:context_is_editor

# ??
compute:add_fixed_ip: rule:context_is_editor

# ??
compute:remove_fixed_ip: rule:context_is_editor

# ??
compute:attach_volume: rule:context_is_editor

# ??
compute:detach_volume: rule:context_is_editor

# ??
compute:swap_volume: rule:context_is_editor

# ??
compute:attach_interface: rule:context_is_editor

# ??
compute:detach_interface: rule:context_is_editor

# ??
compute:set_admin_password: rule:context_is_editor

# ??
compute:rescue: rule:context_is_editor

# ??
compute:unrescue: rule:context_is_editor

# ??
compute:suspend: rule:context_is_editor

# ??
compute:resume: rule:context_is_editor

# ??
compute:pause: rule:context_is_editor

# ??
compute:unpause: rule:context_is_editor

# ??
compute:shelve: rule:context_is_editor

# ??
compute:shelve_offload: rule:context_is_editor

# ??
compute:unshelve: rule:context_is_editor

# ??
compute:snapshot: rule:context_is_editor

# ??
compute:snapshot_volume_backed: rule:context_is_editor

# ??
compute:backup: rule:context_is_editor

# ??
compute:resize: rule:context_is_editor

# ??
compute:confirm_resize: rule:context_is_editor

# ??
compute:revert_resize: rule:context_is_editor

# ??
compute:rebuild: rule:context_is_editor

# ??
compute:reboot: rule:context_is_editor

# ??
compute:delete: rule:context_is_editor

# ??
compute:soft_delete: rule:context_is_editor

# ??
compute:force_delete: rule:context_is_editor

# ??
compute:security_groups:add_to_instance: rule:context_is_compute_admin or rule:context_is_network_admin

# ??
compute:security_groups:remove_from_instance: rule:context_is_compute_admin or rule:context_is_network_admin

# ??
compute:restore: rule:context_is_editor

# ??
compute:volume_snapshot_create: rule:context_is_editor

# ??
compute:volume_snapshot_delete: rule:context_is_editor

# ??
compute_extension:accounts: is_admin:True

# ??
compute_extension:admin_actions: is_admin:True

# ??
compute_extension:admin_actions:pause: rule:context_is_editor

# ??
compute_extension:admin_actions:unpause: rule:context_is_editor

# ??
compute_extension:admin_actions:suspend: rule:context_is_editor

# ??
compute_extension:admin_actions:resume: rule:context_is_editor

# ??
compute_extension:admin_actions:lock: rule:context_is_compute_admin

# ??
compute_extension:admin_actions:unlock: rule:context_is_compute_admin

# ??
compute_extension:admin_actions:resetNetwork: is_admin:True

# ??
compute_extension:admin_actions:injectNetworkInfo: is_admin:True

# ??
compute_extension:admin_actions:createBackup: rule:context_is_editor

# ??
compute_extension:admin_actions:migrateLive: is_admin:True

# ??
compute_extension:admin_actions:resetState: rule:context_is_compute_admin

# ??
compute_extension:admin_actions:migrate: is_admin:True

# ??
compute_extension:aggregates: is_admin:True

# ??
compute_extension:agents: is_admin:True

# ??
compute_extension:attach_interfaces: rule:context_is_editor

# ??
compute_extension:baremetal_nodes: is_admin:True

# ??
compute_extension:cells: is_admin:True

# ??
compute_extension:cells:create: is_admin:True

# ??
compute_extension:cells:delete: is_admin:True

# ??
compute_extension:cells:update: is_admin:True

# ??
compute_extension:cells:sync_instances: is_admin:True

# ??
compute_extension:certificates: rule:context_is_editor

# ??
compute_extension:cloudpipe: is_admin:True

# ??
compute_extension:cloudpipe_update: is_admin:True

# ??
compute_extension:config_drive: rule:context_is_editor

# ??
compute_extension:console_output: rule:context_is_editor

# ??
compute_extension:consoles: rule:context_is_editor

# ??
compute_extension:createserverext: rule:context_is_editor

# ??
compute_extension:deferred_delete: rule:context_is_editor

# ??
compute_extension:disk_config: rule:context_is_editor

# ??
compute_extension:evacuate: is_admin:True

# ??
compute_extension:extended_server_attributes: rule:context_is_editor

# ??
compute_extension:extended_status: rule:context_is_viewer

# ??
compute_extension:extended_availability_zone: rule:context_is_viewer

# ??
compute_extension:extended_ips: rule:context_is_viewer

# ??
compute_extension:extended_ips_mac: rule:context_is_viewer

# ??
compute_extension:extended_vif_net: rule:context_is_viewer

# ??
compute_extension:extended_volumes: rule:context_is_viewer

# ??
compute_extension:fixed_ips: is_admin:True

# ??
compute_extension:flavor_access: rule:context_is_editor

# ??
compute_extension:flavor_access:addTenantAccess: is_admin:True

# ??
compute_extension:flavor_access:removeTenantAccess: is_admin:True

# ??
compute_extension:flavor_disabled: rule:context_is_editor

# ??
compute_extension:flavor_rxtx: rule:context_is_editor

# ??
compute_extension:flavor_swap: rule:context_is_editor

# ??
compute_extension:flavorextradata: rule:context_is_editor

# ??
compute_extension:flavorextraspecs:index: rule:context_is_editor

# ??
compute_extension:flavorextraspecs:show: rule:context_is_editor

# ??
compute_extension:flavorextraspecs:create: is_admin:True

# ??
compute_extension:flavorextraspecs:update: is_admin:True

# ??
compute_extension:flavorextraspecs:delete: is_admin:True

# ??
compute_extension:flavormanage: is_admin:True

# ??
compute_extension:floating_ip_dns: rule:context_is_editor

# ??
compute_extension:floating_ip_pools: rule:context_is_editor

# ??
compute_extension:floating_ips: rule:context_is_editor

# ??
compute_extension:floating_ips_bulk: is_admin:True

# ??
compute_extension:fping: rule:context_is_editor

# ??
compute_extension:fping:all_tenants: is_admin:True

# ??
compute_extension:hide_server_addresses: not is_admin:True

# ??
compute_extension:hosts: is_admin:True

# ??
compute_extension:hypervisors: is_admin:True

# ??
compute_extension:image_size: rule:context_is_editor

# ??
compute_extension:instance_actions: rule:context_is_editor

# ??
compute_extension:instance_actions:events: is_admin:True

# ??
compute_extension:instance_usage_audit_log: is_admin:True

# ??
compute_extension:keypairs: rule:context_is_editor

# ??
compute_extension:keypairs:index: rule:context_is_viewer

# ??
compute_extension:keypairs:show: rule:context_is_viewer

# ??
compute_extension:keypairs:create: rule:context_is_editor

# ??
compute_extension:keypairs:delete: rule:context_is_editor

# ??
compute_extension:multinic: rule:context_is_editor

# ??
compute_extension:networks: '!'

# ??
compute_extension:networks:view: '!'

# ??
compute_extension:networks_associate: '!'

# ??
compute_extension:os-tenant-networks: '!'

# ??
compute_extension:quotas:show: rule:context_is_viewer or rule:context_is_quota_admin

# ??
compute_extension:quotas:update: rule:context_is_quota_admin

# ??
compute_extension:quotas:delete: rule:context_is_quota_admin

# ??
compute_extension:quota_classes: is_admin:True or rule:context_is_quota_admin

# ??
compute_extension:rescue: rule:context_is_editor

# ??
compute_extension:security_group_default_rules: is_admin:True

# ??
compute_extension:security_groups: rule:context_is_viewer

# ??
compute_extension:server_diagnostics: is_admin:True

# ??
compute_extension:server_groups: rule:context_is_editor

# ??
compute_extension:server_password: rule:context_is_editor

# ??
compute_extension:server_usage: rule:context_is_editor

# ??
compute_extension:services: is_admin:True

# ??
compute_extension:shelve: rule:context_is_editor

# ??
compute_extension:shelveOffload: is_admin:True

# ??
compute_extension:simple_tenant_usage:show: rule:context_is_editor

# ??
compute_extension:simple_tenant_usage:list: is_admin:True

# ??
compute_extension:unshelve: rule:context_is_editor

# ??
compute_extension:users: is_admin:True

# ??
compute_extension:virtual_interfaces: rule:context_is_editor

# ??
compute_extension:virtual_storage_arrays: rule:context_is_editor

# ??
compute_extension:volumes: rule:context_is_viewer

# ??
compute_extension:volume_attachments:index: rule:context_is_viewer

# ??
compute_extension:volume_attachments:show: rule:context_is_viewer

# ??
compute_extension:volume_attachments:create: rule:context_is_editor

# ??
compute_extension:volume_attachments:update: rule:context_is_editor

# ??
compute_extension:volume_attachments:delete: rule:context_is_editor

# ??
compute_extension:volumetypes: rule:context_is_editor

# ??
compute_extension:availability_zone:list: rule:context_is_viewer

# ??
compute_extension:availability_zone:detail: is_admin:True

# ??
compute_extension:used_limits_for_admin: is_admin:True

# ??
compute_extension:migrations:index: is_admin:True

# ??
compute_extension:os-assisted-volume-snapshots:create: is_admin:True

# ??
compute_extension:os-assisted-volume-snapshots:delete: is_admin:True

# ??
compute_extension:console_auth_tokens: is_admin:True

# ??
compute_extension:os-server-external-events:create: is_admin:True

# Attach an unshared external network to a server
#   POST /servers
#   POST /servers/{server_id}/os-interface
#network:attach_external_network: rule:project_admin_api
network:attach_external_network: is_admin:True

# List all servers with detailed information for  all projects
#   GET /servers/detail
#os_compute_api:servers:detail:get_all_tenants: rule:system_reader_api
os_compute_api:servers:detail:get_all_tenants: is_admin:True

# List all servers for all projects
#   GET /servers
#os_compute_api:servers:index:get_all_tenants: rule:system_reader_api
os_compute_api:servers:index:get_all_tenants: is_admin:True

# Confirm a server resize
#   POST /servers/{server_id}/action (confirmResize)
#os_compute_api:servers:confirm_resize: rule:system_admin_or_owner
os_compute_api:servers:confirm_resize: rule:context_is_editor

# Create a server
#   POST /servers
#os_compute_api:servers:create: rule:project_member_api
os_compute_api:servers:create: rule:context_is_editor

# Create a server with the requested network attached  to it
#   POST /servers
#os_compute_api:servers:create:attach_network: rule:project_member_api
os_compute_api:servers:create:attach_network: rule:context_is_editor

# Create a server with the requested volume attached to it
#   POST /servers
#os_compute_api:servers:create:attach_volume: rule:project_member_api
os_compute_api:servers:create:attach_volume: rule:context_is_editor

# Create a server on the specified host and/or node.
# In this case, the server is forced to launch on the specified
# host and/or node by bypassing the scheduler filters unlike the
# compute:servers:create:requested_destination rule.
#   POST /servers
#os_compute_api:servers:create:forced_host: rule:project_admin_api
os_compute_api:servers:create:forced_host: rule:compute_admin_all

# Delete a server
#   DELETE /servers/{server_id}
#os_compute_api:servers:delete: rule:system_admin_or_owner
os_compute_api:servers:delete: rule:context_is_editor

# Update a server
#   PUT /servers/{server_id}
#os_compute_api:servers:update: rule:system_admin_or_owner
os_compute_api:servers:update: rule:context_is_editor

# List all servers with detailed information
#   GET /servers/detail
#os_compute_api:servers:detail: rule:system_or_project_reader
os_compute_api:servers:detail: rule:context_is_viewer

# List all servers
#   GET /servers
#os_compute_api:servers:index: rule:system_or_project_reader
os_compute_api:servers:index: rule:context_is_viewer

# Reboot a server
#   POST /servers/{server_id}/action (reboot)
#os_compute_api:servers:reboot: rule:system_admin_or_owner
os_compute_api:servers:reboot: rule:context_is_editor

# Rebuild a server
#   POST /servers/{server_id}/action (rebuild)
#os_compute_api:servers:rebuild: rule:system_admin_or_owner
os_compute_api:servers:rebuild: rule:context_is_editor

# Resize a server
#   POST /servers/{server_id}/action (resize)
#os_compute_api:servers:resize: rule:system_admin_or_owner
os_compute_api:servers:resize: rule:context_is_editor

# Revert a server resize
#   POST /servers/{server_id}/action (revertResize)
#os_compute_api:servers:revert_resize: rule:system_admin_or_owner
os_compute_api:servers:revert_resize: rule:context_is_editor

# Show a server
#   GET /servers/{server_id}
#os_compute_api:servers:show: rule:system_or_project_reader
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
#os_compute_api:servers:show:host_status: rule:system_admin_api
os_compute_api:servers:show:host_status: is_admin:True

# Create an image from a server
#   POST /servers/{server_id}/action (createImage)
#os_compute_api:servers:create_image: rule:system_admin_or_owner
os_compute_api:servers:create_image: rule:context_is_editor

# Create an image from a volume backed server
#   POST /servers/{server_id}/action (createImage)
#os_compute_api:servers:create_image:allow_volume_backed: rule:system_admin_or_owner
os_compute_api:servers:create_image:allow_volume_backed: rule:context_is_editor

# Start a server
#   POST /servers/{server_id}/action (os-start)
#os_compute_api:servers:start: rule:system_admin_or_owner
os_compute_api:servers:start: rule:context_is_editor

# Stop a server
#   POST /servers/{server_id}/action (os-stop)
#os_compute_api:servers:stop: rule:system_admin_or_owner
os_compute_api:servers:stop: rule:context_is_editor

# Trigger crash dump in a server
#   POST /servers/{server_id}/action (trigger_crash_dump)
#os_compute_api:servers:trigger_crash_dump: rule:system_admin_or_owner
os_compute_api:servers:trigger_crash_dump: rule:context_is_editor

# Force an in-progress live migration for a given server to complete
#   POST /servers/{server_id}/migrations/{migration_id}/action (force_complete)
#os_compute_api:servers:migrations:force_complete: rule:system_admin_api
os_compute_api:servers:migrations:force_complete: is_admin:True

# Delete(Abort) an in-progress live migration
#   DELETE /servers/{server_id}/migrations/{migration_id}
#os_compute_api:servers:migrations:delete: rule:system_admin_api
os_compute_api:servers:migrations:delete: is_admin:True

# Lists in-progress live migrations for a given server
#   GET /servers/{server_id}/migrations
#os_compute_api:servers:migrations:index: rule:system_reader_api
os_compute_api:servers:migrations:index: is_admin:True

# Show details for an in-progress live migration for a given server
#   GET /servers/{server_id}/migrations/{migration_id}
#os_compute_api:servers:migrations:show: rule:system_reader_api
os_compute_api:servers:migrations:show: is_admin:True

# ??
os_compute_api:os-admin-actions: is_admin:True

# ??
os_compute_api:os-admin-actions:reset_network: is_admin:True

# Inject network information into the server
#   POST /servers/{server_id}/action (injectNetworkInfo)
#os_compute_api:os-admin-actions:inject_network_info: rule:system_admin_api
os_compute_api:os-admin-actions:inject_network_info: is_admin:True

# Reset the state of a given server
#   POST /servers/{server_id}/action (os-resetState)
#os_compute_api:os-admin-actions:reset_state: rule:system_admin_api
os_compute_api:os-admin-actions:reset_state: rule:context_is_compute_admin

# Change the administrative password for a server
#   POST /servers/{server_id}/action (changePassword)
#os_compute_api:os-admin-password: rule:system_admin_or_owner
os_compute_api:os-admin-password: rule:context_is_editor

# List all aggregates
#   GET /os-aggregates
#os_compute_api:os-aggregates:index: rule:system_reader_api
os_compute_api:os-aggregates:index: is_admin:True

# Create an aggregate
#   POST /os-aggregates
#os_compute_api:os-aggregates:create: rule:system_admin_api
os_compute_api:os-aggregates:create: is_admin:True

# Show details for an aggregate
#   GET /os-aggregates/{aggregate_id}
#os_compute_api:os-aggregates:show: rule:system_reader_api
os_compute_api:os-aggregates:show: is_admin:True

# Update name and/or availability zone for an aggregate
#   PUT /os-aggregates/{aggregate_id}
#os_compute_api:os-aggregates:update: rule:system_admin_api
os_compute_api:os-aggregates:update: is_admin:True

# Delete an aggregate
#   DELETE /os-aggregates/{aggregate_id}
#os_compute_api:os-aggregates:delete: rule:system_admin_api
os_compute_api:os-aggregates:delete: is_admin:True

# Add a host to an aggregate
#   POST /os-aggregates/{aggregate_id}/action (add_host)
#os_compute_api:os-aggregates:add_host: rule:system_admin_api
os_compute_api:os-aggregates:add_host: is_admin:True

# Remove a host from an aggregate
#   POST /os-aggregates/{aggregate_id}/action (remove_host)
#os_compute_api:os-aggregates:remove_host: rule:system_admin_api
os_compute_api:os-aggregates:remove_host: is_admin:True

# Create or replace metadata for an aggregate
#   POST /os-aggregates/{aggregate_id}/action (set_metadata)
#os_compute_api:os-aggregates:set_metadata: rule:system_admin_api
os_compute_api:os-aggregates:set_metadata: is_admin:True

# ??
os_compute_api:os-agents: is_admin:True

# ??
os_compute_api:os-attach-interfaces: rule:context_is_editor

# ??
os_compute_api:os-baremetal-nodes: is_admin:True

# ??
os_compute_api:os-cells: is_admin:True

# ??
os_compute_api:os-cells:create: is_admin:True

# ??
os_compute_api:os-cells:delete: is_admin:True

# ??
os_compute_api:os-cells:update: is_admin:True

# ??
os_compute_api:os-cells:sync_instances: is_admin:True

# ??
os_compute_api:os-certificates:create: rule:context_is_editor

# ??
os_compute_api:os-certificates:show: rule:context_is_viewer

# ??
os_compute_api:os-cloudpipe: is_admin:True

# Show console output for a server
#   POST /servers/{server_id}/action (os-getConsoleOutput)
#os_compute_api:os-console-output: rule:system_admin_or_owner
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
#os_compute_api:os-remote-consoles: rule:system_admin_or_owner
os_compute_api:os-remote-consoles: rule:context_is_editor

# Create a back up of a server
#   POST /servers/{server_id}/action (createBackup)
#os_compute_api:os-create-backup: rule:system_admin_or_owner
os_compute_api:os-create-backup: rule:context_is_editor

# ??
os_compute_api:os-deferred-delete: rule:context_is_editor

# Evacuate a server from a failed host to a new host
#   POST /servers/{server_id}/action (evacuate)
#os_compute_api:os-evacuate: rule:system_admin_api
os_compute_api:os-evacuate: is_admin:True

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
#os_compute_api:os-extended-server-attributes: rule:system_admin_api
os_compute_api:os-extended-server-attributes: rule:context_is_viewer

# List available extensions and show information for an extension by alias
#   GET /extensions
#   GET /extensions/{alias}
#os_compute_api:extensions: @
os_compute_api:extensions: rule:context_is_viewer

# ??
os_compute_api:os-fixed-ips: is_admin:True

# List flavor access information
# Allows access to the full list of tenants that have access
# to a flavor via an os-flavor-access API.
#   GET /flavors/{flavor_id}/os-flavor-access
#os_compute_api:os-flavor-access: rule:system_reader_api
os_compute_api:os-flavor-access: rule:context_is_editor

# Remove flavor access from a tenant
#   POST /flavors/{flavor_id}/action (removeTenantAccess)
#os_compute_api:os-flavor-access:remove_tenant_access: rule:system_admin_api
os_compute_api:os-flavor-access:remove_tenant_access: is_admin:True

# Add flavor access to a tenant
#   POST /flavors/{flavor_id}/action (addTenantAccess)
#os_compute_api:os-flavor-access:add_tenant_access: rule:system_admin_api
os_compute_api:os-flavor-access:add_tenant_access: is_admin:True

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
#os_compute_api:os-flavor-extra-specs:index: rule:system_or_project_reader
os_compute_api:os-flavor-extra-specs:index: rule:context_is_viewer

# Show an extra spec for a flavor
#   GET /flavors/{flavor_id}/os-extra_specs/{flavor_extra_spec_key}
#os_compute_api:os-flavor-extra-specs:show: rule:system_or_project_reader
os_compute_api:os-flavor-extra-specs:show: rule:context_is_viewer

# Create extra specs for a flavor
#   POST /flavors/{flavor_id}/os-extra_specs/
#os_compute_api:os-flavor-extra-specs:create: rule:system_admin_api
os_compute_api:os-flavor-extra-specs:create: is_admin:True

# Update an extra spec for a flavor
#   PUT /flavors/{flavor_id}/os-extra_specs/{flavor_extra_spec_key}
#os_compute_api:os-flavor-extra-specs:update: rule:system_admin_api
os_compute_api:os-flavor-extra-specs:update: is_admin:True

# Delete an extra spec for a flavor
#   DELETE /flavors/{flavor_id}/os-extra_specs/{flavor_extra_spec_key}
#os_compute_api:os-flavor-extra-specs:delete: rule:system_admin_api
os_compute_api:os-flavor-extra-specs:delete: is_admin:True

# Create a flavor
#   POST /flavors
#os_compute_api:os-flavor-manage:create: rule:system_admin_api
os_compute_api:os-flavor-manage:create: is_admin:True

# Update a flavor
#   PUT /flavors/{flavor_id}
#os_compute_api:os-flavor-manage:update: rule:system_admin_api
os_compute_api:os-flavor-manage:update: is_admin:True

# Delete a flavor
#   DELETE /flavors/{flavor_id}
#os_compute_api:os-flavor-manage:delete: rule:system_admin_api
os_compute_api:os-flavor-manage:delete: is_admin:True

# ??
os_compute_api:os-floating-ip-dns: rule:context_is_editor

# ??
os_compute_api:os-floating-ip-dns:domain:update: is_admin:True

# ??
os_compute_api:os-floating-ip-dns:domain:delete: is_admin:True

# List floating IP pools. This API is deprecated.
#   GET /os-floating-ip-pools
#os_compute_api:os-floating-ip-pools: @
os_compute_api:os-floating-ip-pools: rule:context_is_editor

# ??
os_compute_api:os-floating-ips: rule:context_is_editor

# ??
os_compute_api:os-floating-ips-bulk: is_admin:True

# ??
os_compute_api:os-fping: rule:context_is_editor

# ??
os_compute_api:os-fping:all_tenants: is_admin:True

# ??
os_compute_api:os-hide-server-addresses: not is_admin:True

# ??
os_compute_api:os-hosts: is_admin:True

# ??
os_compute_api:os-hypervisors: is_admin:True

# ??
os_compute_api:image-size: rule:context_is_editor

# ??
os_compute_api:os-instance-actions: rule:context_is_editor

# Add events details in action details for a server.
# This check is performed only after the check
# os_compute_api:os-instance-actions:show passes. Beginning with Microversion
# 2.51, events details are always included; traceback information is provided
# per event if policy enforcement passes. Beginning with Microversion 2.62,
# each event includes a hashed host identifier and, if policy enforcement
# passes, the name of the host.
#   GET /servers/{server_id}/os-instance-actions/{request_id}
#os_compute_api:os-instance-actions:events: rule:system_reader_api
os_compute_api:os-instance-actions:events: is_admin:True

# ??
os_compute_api:os-instance-usage-audit-log: is_admin:True

# List IP addresses that are assigned to a server
#   GET /servers/{server_id}/ips
#os_compute_api:ips:index: rule:system_or_project_reader
os_compute_api:ips:index: rule:context_is_viewer

# Show IP addresses details for a network label of a  server
#   GET /servers/{server_id}/ips/{network_label}
#os_compute_api:ips:show: rule:system_or_project_reader
os_compute_api:ips:show: rule:context_is_viewer

# List all keypairs
#   GET /os-keypairs
#os_compute_api:os-keypairs:index: (rule:system_reader_api) or user_id:%(user_id)s
os_compute_api:os-keypairs:index: is_admin:True or user_id:%(user_id)s

# Show details of a keypair
#   GET /os-keypairs/{keypair_name}
#os_compute_api:os-keypairs:show: (rule:system_reader_api) or user_id:%(user_id)s
os_compute_api:os-keypairs:show: is_admin:True or user_id:%(user_id)s

# Create a keypair
#   POST /os-keypairs
#os_compute_api:os-keypairs:create: (rule:system_admin_api) or user_id:%(user_id)s
os_compute_api:os-keypairs:create: is_admin:True or user_id:%(user_id)s

# Delete a keypair
#   DELETE /os-keypairs/{keypair_name}
#os_compute_api:os-keypairs:delete: (rule:system_admin_api) or user_id:%(user_id)s
os_compute_api:os-keypairs:delete: is_admin:True or user_id:%(user_id)s

# Show rate and absolute limits for the current user project
#   GET /limits
#os_compute_api:limits: @
os_compute_api:limits: rule:context_is_viewer

# Lock a server
#   POST /servers/{server_id}/action (lock)
#os_compute_api:os-lock-server:lock: rule:system_admin_or_owner
os_compute_api:os-lock-server:lock: rule:context_is_compute_admin

# Unlock a server
#   POST /servers/{server_id}/action (unlock)
#os_compute_api:os-lock-server:unlock: rule:system_admin_or_owner
os_compute_api:os-lock-server:unlock: rule:context_is_compute_admin

# Unlock a server, regardless who locked the server.
# This check is performed only after the check
# os_compute_api:os-lock-server:unlock passes
#   POST /servers/{server_id}/action (unlock)
#os_compute_api:os-lock-server:unlock:unlock_override: rule:system_admin_api
os_compute_api:os-lock-server:unlock:unlock_override: is_admin:True

# Cold migrate a server to a host
#   POST /servers/{server_id}/action (migrate)
#os_compute_api:os-migrate-server:migrate: rule:system_admin_api
os_compute_api:os-migrate-server:migrate: is_admin:True

# Live migrate a server to a new host without a reboot
#   POST /servers/{server_id}/action (os-migrateLive)
#os_compute_api:os-migrate-server:migrate_live: rule:system_admin_api
os_compute_api:os-migrate-server:migrate_live: is_admin:True

# ??
os_compute_api:os-multinic: rule:context_is_editor

# ??
os_compute_api:os-networks:view: '!'

# Pause a server
#   POST /servers/{server_id}/action (pause)
#os_compute_api:os-pause-server:pause: rule:system_admin_or_owner
os_compute_api:os-pause-server:pause: rule:context_is_editor

# Unpause a paused server
#   POST /servers/{server_id}/action (unpause)
#os_compute_api:os-pause-server:unpause: rule:system_admin_or_owner
os_compute_api:os-pause-server:unpause: rule:context_is_editor

# ??
os_compute_api:os-pci:pci_servers: rule:context_is_editor

# ??
os_compute_api:os-pci:index: is_admin:True

# ??
os_compute_api:os-pci:detail: is_admin:True

# ??
os_compute_api:os-pci:show: is_admin:True

# Show a quota
#   GET /os-quota-sets/{tenant_id}
#os_compute_api:os-quota-sets:show: rule:system_or_project_reader
os_compute_api:os-quota-sets:show: rule:context_is_viewer

# List default quotas
#   GET /os-quota-sets/{tenant_id}/defaults
#os_compute_api:os-quota-sets:defaults: @
os_compute_api:os-quota-sets:defaults: rule:context_is_viewer

# Update the quotas
#   PUT /os-quota-sets/{tenant_id}
#os_compute_api:os-quota-sets:update: rule:system_admin_api
os_compute_api:os-quota-sets:update: is_admin:True

# Revert quotas to defaults
#   DELETE /os-quota-sets/{tenant_id}
#os_compute_api:os-quota-sets:delete: rule:system_admin_api
os_compute_api:os-quota-sets:delete: is_admin:True

# Show the detail of quota
#   GET /os-quota-sets/{tenant_id}/detail
#os_compute_api:os-quota-sets:detail: rule:system_or_project_reader
os_compute_api:os-quota-sets:detail: rule:context_is_viewer

# Update quotas for specific quota class
#   PUT /os-quota-class-sets/{quota_class}
#os_compute_api:os-quota-class-sets:update: rule:system_admin_api
os_compute_api:os-quota-class-sets:update: is_admin:True

# List quotas for specific quota classs
#   GET /os-quota-class-sets/{quota_class}
#os_compute_api:os-quota-class-sets:show: rule:system_reader_api
os_compute_api:os-quota-class-sets:show: is_admin:True or quota_class:%(quota_class)s

# Rescue a server
#   POST /servers/{server_id}/action (rescue)
#os_compute_api:os-rescue: rule:system_admin_or_owner
os_compute_api:os-rescue: rule:context_is_editor

# Show the usage data for a server
#   GET /servers/{server_id}/diagnostics
#os_compute_api:os-server-diagnostics: rule:system_admin_api
os_compute_api:os-server-diagnostics: is_admin:True

# ??
os_compute_api:os-server-password: rule:context_is_editor

# Create a new server group
#   POST /os-server-groups
#os_compute_api:os-server-groups:create: rule:project_member_api
os_compute_api:os-server-groups:create: rule:context_is_editor

# Delete a server group
#   DELETE /os-server-groups/{server_group_id}
#os_compute_api:os-server-groups:delete: rule:system_admin_or_owner
os_compute_api:os-server-groups:delete: rule:context_is_editor

# List all server groups
#   GET /os-server-groups
#os_compute_api:os-server-groups:index: rule:system_or_project_reader
os_compute_api:os-server-groups:index: rule:context_is_editor

# List all server groups for all projects
#   GET /os-server-groups
#os_compute_api:os-server-groups:index:all_projects: rule:system_reader_api
os_compute_api:os-server-groups:index:all_projects: is_admin:True

# Show details of a server group
#   GET /os-server-groups/{server_group_id}
#os_compute_api:os-server-groups:show: rule:system_or_project_reader
os_compute_api:os-server-groups:show: rule:context_is_editor

# ??
os_compute_api:os-services: is_admin:True

# ??
os_compute_api:os-services:disable: '!'

# ??
os_compute_api:os-services:enable: is_admin:True

# ??
os_compute_api:os-services:disable-log-reason: is_admin:True

# List all metadata of a server
#   GET /servers/{server_id}/metadata
#os_compute_api:server-metadata:index: rule:system_or_project_reader
os_compute_api:server-metadata:index: rule:context_is_viewer

# Show metadata for a server
#   GET /servers/{server_id}/metadata/{key}
#os_compute_api:server-metadata:show: rule:system_or_project_reader
os_compute_api:server-metadata:show: rule:context_is_viewer

# Delete metadata from a server
#   DELETE /servers/{server_id}/metadata/{key}
#os_compute_api:server-metadata:delete: rule:system_admin_or_owner
os_compute_api:server-metadata:delete: rule:context_is_editor

# Create metadata for a server
#   POST /servers/{server_id}/metadata
#os_compute_api:server-metadata:create: rule:system_admin_or_owner
os_compute_api:server-metadata:create: rule:context_is_editor

# Update metadata from a server
#   PUT /servers/{server_id}/metadata/{key}
#os_compute_api:server-metadata:update: rule:system_admin_or_owner
os_compute_api:server-metadata:update: rule:context_is_editor

# Replace metadata for a server
#   PUT /servers/{server_id}/metadata
#os_compute_api:server-metadata:update_all: rule:system_admin_or_owner
os_compute_api:server-metadata:update_all: rule:context_is_editor

# Shelve server
#   POST /servers/{server_id}/action (shelve)
#os_compute_api:os-shelve:shelve: rule:system_admin_or_owner
os_compute_api:os-shelve:shelve: rule:context_is_editor

# Shelf-offload (remove) server
#   POST /servers/{server_id}/action (shelveOffload)
#os_compute_api:os-shelve:shelve_offload: rule:system_admin_api
os_compute_api:os-shelve:shelve_offload: is_admin:True

# Show usage statistics for a specific tenant
#   GET /os-simple-tenant-usage/{tenant_id}
#os_compute_api:os-simple-tenant-usage:show: rule:system_or_project_reader
os_compute_api:os-simple-tenant-usage:show: rule:context_is_viewer

# List per tenant usage statistics for all tenants
#   GET /os-simple-tenant-usage
#os_compute_api:os-simple-tenant-usage:list: rule:system_reader_api
os_compute_api:os-simple-tenant-usage:list: is_admin:True

# Suspend server
#   POST /servers/{server_id}/action (suspend)
#os_compute_api:os-suspend-server:suspend: rule:system_admin_or_owner
os_compute_api:os-suspend-server:suspend: rule:context_is_editor

# Resume suspended server
#   POST /servers/{server_id}/action (resume)
#os_compute_api:os-suspend-server:resume: rule:system_admin_or_owner
os_compute_api:os-suspend-server:resume: rule:context_is_editor

# ??
os_compute_api:os-tenant-networks: '!'

# Unshelve (restore) shelved server
#   POST /servers/{server_id}/action (unshelve)
#os_compute_api:os-shelve:unshelve: rule:system_admin_or_owner
os_compute_api:os-shelve:unshelve: rule:context_is_editor

# ??
os_compute_api:os-virtual-interfaces: rule:context_is_editor

# List volume attachments for an instance
#   GET /servers/{server_id}/os-volume_attachments
#os_compute_api:os-volumes-attachments:index: rule:system_or_project_reader
os_compute_api:os-volumes-attachments:index: rule:context_is_viewer

# Show details of a volume attachment
#   GET /servers/{server_id}/os-volume_attachments/{volume_id}
#os_compute_api:os-volumes-attachments:show: rule:system_or_project_reader
os_compute_api:os-volumes-attachments:show: rule:context_is_viewer

# Attach a volume to an instance
#   POST /servers/{server_id}/os-volume_attachments
#os_compute_api:os-volumes-attachments:create: rule:system_admin_or_owner
os_compute_api:os-volumes-attachments:create: rule:context_is_editor

# Update a volume attachment.
# New 'update' policy about 'swap + update' request (which is possible
# only >2.85) only <swap policy> is checked. We expect <swap policy> to be
# always superset of this policy permission.
#   PUT /servers/{server_id}/os-volume_attachments/{volume_id}
#os_compute_api:os-volumes-attachments:update: rule:system_admin_or_owner
os_compute_api:os-volumes-attachments:update: rule:context_is_editor

# Detach a volume from an instance
#   DELETE /servers/{server_id}/os-volume_attachments/{volume_id}
#os_compute_api:os-volumes-attachments:delete: rule:system_admin_or_owner
os_compute_api:os-volumes-attachments:delete: rule:context_is_editor

# List availability zone information without host information
#   GET /os-availability-zone
#os_compute_api:os-availability-zone:list: @
os_compute_api:os-availability-zone:list: rule:context_is_viewer

# List detailed availability zone information with host information
#   GET /os-availability-zone/detail
#os_compute_api:os-availability-zone:detail: rule:system_reader_api
os_compute_api:os-availability-zone:detail: is_admin:True

# ??
os_compute_api:os-used-limits: is_admin:True

# List migrations
#   GET /os-migrations
#os_compute_api:os-migrations:index: rule:system_reader_api
os_compute_api:os-migrations:index: is_admin:True

# Create an assisted volume snapshot
#   POST /os-assisted-volume-snapshots
#os_compute_api:os-assisted-volume-snapshots:create: rule:system_admin_api
os_compute_api:os-assisted-volume-snapshots:create: is_admin:True

# Delete an assisted volume snapshot
#   DELETE /os-assisted-volume-snapshots/{snapshot_id}
#os_compute_api:os-assisted-volume-snapshots:delete: rule:system_admin_api
os_compute_api:os-assisted-volume-snapshots:delete: is_admin:True

# Show console connection information for a given console authentication token
#   GET /os-console-auth-tokens/{console_token}
#os_compute_api:os-console-auth-tokens: rule:system_reader_api
os_compute_api:os-console-auth-tokens: is_admin:True

# Create one or more external events
#   POST /os-server-external-events
#os_compute_api:os-server-external-events:create: rule:system_admin_api
os_compute_api:os-server-external-events:create: is_admin:True

# Request image caching for an aggregate
#   POST /os-aggregates/{aggregate_id}/images
#compute:aggregates:images: rule:system_admin_api

# Show the NUMA topology data for a server with host NUMA ID and CPU pinning information
#   GET /servers/{server_id}/topology
#compute:server:topology:host:index: rule:system_reader_api

# Show the NUMA topology data for a server
#   GET /servers/{server_id}/topology
#compute:server:topology:index: rule:system_or_project_reader

# Create a server on the requested compute service host and/or
# hypervisor_hostname.
# In this case, the requested host and/or hypervisor_hostname is
# validated by the scheduler filters unlike the
# os_compute_api:servers:create:forced_host rule.
#   POST /servers
#compute:servers:create:requested_destination: rule:project_admin_api

# Resize a server across cells. By default, this is disabled for all users and
# recommended to be tested in a deployment for admin users before opening it
# up to non-admin users. Resizing within a cell is the default preferred
# behavior even if this is enabled.
#   POST /servers/{server_id}/action (resize)
#compute:servers:resize:cross_cell: '!'

# Show rate and absolute limits of other project.
# This policy only checks if the user has access to the requested
# project limits. And this check is performed only after the check
# os_compute_api:limits passes
#   GET /limits
#os_compute_api:limits:other_project: rule:system_reader_api

# Attach an interface to a server
#   POST /servers/{server_id}/os-interface
#os_compute_api:os-attach-interfaces:create: rule:system_admin_or_owner

# Detach an interface from a server
#   DELETE /servers/{server_id}/os-interface/{port_id}
#os_compute_api:os-attach-interfaces:delete: rule:system_admin_or_owner

# List port interfaces attached to a server
#   GET /servers/{server_id}/os-interface
#os_compute_api:os-attach-interfaces:list: rule:system_or_project_reader

# Show details of a port interface attached to a server
#   GET /servers/{server_id}/os-interface/{port_id}
#os_compute_api:os-attach-interfaces:show: rule:system_or_project_reader

# List and show details of bare metal nodes.
# These APIs are proxy calls to the Ironic service and are deprecated.
#   GET /os-baremetal-nodes
#os_compute_api:os-baremetal-nodes:list: rule:system_reader_api

# Show action details for a server.
#   GET /os-baremetal-nodes/{node_id}
#os_compute_api:os-baremetal-nodes:show: rule:system_reader_api

# Force delete a server before deferred cleanup
#   POST /servers/{server_id}/action (forceDelete)
#os_compute_api:os-deferred-delete:force: rule:system_admin_or_owner

# Restore a soft deleted server
#   POST /servers/{server_id}/action (restore)
#os_compute_api:os-deferred-delete:restore: rule:system_admin_or_owner

# Associate floating IPs to server.  This API is deprecated.
#   POST /servers/{server_id}/action (addFloatingIp)
#os_compute_api:os-floating-ips:add: rule:system_admin_or_owner

# Create floating IPs. This API is deprecated.
#   POST /os-floating-ips
#os_compute_api:os-floating-ips:create: rule:system_admin_or_owner

# Delete floating IPs. This API is deprecated.
#   DELETE /os-floating-ips/{floating_ip_id}
#os_compute_api:os-floating-ips:delete: rule:system_admin_or_owner

# List floating IPs. This API is deprecated.
#   GET /os-floating-ips
#os_compute_api:os-floating-ips:list: rule:system_or_project_reader

# Disassociate floating IPs to server.  This API is deprecated.
#   POST /servers/{server_id}/action (removeFloatingIp)
#os_compute_api:os-floating-ips:remove: rule:system_admin_or_owner

# Show floating IPs. This API is deprecated.
#   GET /os-floating-ips/{floating_ip_id}
#os_compute_api:os-floating-ips:show: rule:system_or_project_reader

# List physical hosts.
# This API is deprecated in favor of os-hypervisors and os-services.
#   GET /os-hosts
#os_compute_api:os-hosts:list: rule:system_reader_api

# Reboot physical host.
# This API is deprecated in favor of os-hypervisors and os-services.
#   GET /os-hosts/{host_name}/reboot
#os_compute_api:os-hosts:reboot: rule:system_admin_api

# Show physical host.
# This API is deprecated in favor of os-hypervisors and os-services.
#   GET /os-hosts/{host_name}
#os_compute_api:os-hosts:show: rule:system_reader_api

# Shutdown physical host.
# This API is deprecated in favor of os-hypervisors and os-services.
#   GET /os-hosts/{host_name}/shutdown
#os_compute_api:os-hosts:shutdown: rule:system_admin_api

# Start physical host.
# This API is deprecated in favor of os-hypervisors and os-services.
#   GET /os-hosts/{host_name}/startup
#os_compute_api:os-hosts:start: rule:system_admin_api

# Update physical host.
# This API is deprecated in favor of os-hypervisors and os-services.
#   PUT /os-hosts/{host_name}
#os_compute_api:os-hosts:update: rule:system_admin_api

# List all hypervisors.
#   GET /os-hypervisors
#os_compute_api:os-hypervisors:list: rule:system_reader_api

# List all hypervisors with details
#   GET /os-hypervisors/details
#os_compute_api:os-hypervisors:list-detail: rule:system_reader_api

# Search hypervisor by hypervisor_hostname pattern.
#   GET /os-hypervisors/{hypervisor_hostname_pattern}/search
#os_compute_api:os-hypervisors:search: rule:system_reader_api

# List all servers on hypervisors that can match the provided hypervisor_hostname pattern.
#   GET /os-hypervisors/{hypervisor_hostname_pattern}/servers
#os_compute_api:os-hypervisors:servers: rule:system_reader_api

# Show details for a hypervisor.
#   GET /os-hypervisors/{hypervisor_id}
#os_compute_api:os-hypervisors:show: rule:system_reader_api

# Show summary statistics for all hypervisors over all compute nodes.
#   GET /os-hypervisors/statistics
#os_compute_api:os-hypervisors:statistics: rule:system_reader_api

# Show the uptime of a hypervisor.
#   GET /os-hypervisors/{hypervisor_id}/uptime
#os_compute_api:os-hypervisors:uptime: rule:system_reader_api

# Add “details” key in action events for a server.
# This check is performed only after the check
# os_compute_api:os-instance-actions:show passes. Beginning with Microversion
# 2.84, new field 'details' is exposed via API which can have more details about
# event failure. That field is controlled by this policy which is system reader
# by default. Making the 'details' field visible to the non-admin user helps to
# understand the nature of the problem (i.e. if the action can be retried),
# but in the other hand it might leak information about the deployment
# (e.g. the type of the hypervisor).
#   GET /servers/{server_id}/os-instance-actions/{request_id}
#os_compute_api:os-instance-actions:events:details: rule:system_reader_api

# List actions for a server.
#   GET /servers/{server_id}/os-instance-actions
#os_compute_api:os-instance-actions:list: rule:system_or_project_reader

# Show action details for a server.
#   GET /servers/{server_id}/os-instance-actions/{request_id}
#os_compute_api:os-instance-actions:show: rule:system_or_project_reader

# List all usage audits.
#   GET /os-instance_usage_audit_log
#os_compute_api:os-instance-usage-audit-log:list: rule:system_reader_api

# List all usage audits occurred before a specified time for all servers on all
# compute hosts where usage auditing is configured
#   GET /os-instance_usage_audit_log/{before_timestamp}
#os_compute_api:os-instance-usage-audit-log:show: rule:system_reader_api

# Add a fixed IP address to a server.
# This API is proxy calls to the Network service. This is
# deprecated.
#   POST /servers/{server_id}/action (addFixedIp)
#os_compute_api:os-multinic:add: rule:system_admin_or_owner

# Remove a fixed IP address from a server.
# This API is proxy calls to the Network service. This is
# deprecated.
#   POST /servers/{server_id}/action (removeFixedIp)
#os_compute_api:os-multinic:remove: rule:system_admin_or_owner

# List networks for the project.
# This API is proxy calls to the Network service. This is deprecated.
#   GET /os-networks
#os_compute_api:os-networks:list: rule:system_or_project_reader

# Show network details.
# This API is proxy calls to the Network service. This is deprecated.
#   GET /os-networks/{network_id}
#os_compute_api:os-networks:show: rule:system_or_project_reader

# Add security groups to server.
#   POST /servers/{server_id}/action (addSecurityGroup)
#os_compute_api:os-security-groups:add: rule:system_admin_or_owner

# Create security group. This API is deprecated.
#   POST /os-security-groups
#os_compute_api:os-security-groups:create: rule:system_admin_or_owner

# Delete security group. This API is deprecated.
#   DELETE /os-security-groups/{security_group_id}
#os_compute_api:os-security-groups:delete: rule:system_admin_or_owner

# List security groups. This API is deprecated.
#   GET /os-security-groups
#os_compute_api:os-security-groups:get: rule:system_or_project_reader

# List security groups of server.
#   GET /servers/{server_id}/os-security-groups
#os_compute_api:os-security-groups:list: rule:system_or_project_reader

# Remove security groups from server.
#   POST /servers/{server_id}/action (removeSecurityGroup)
#os_compute_api:os-security-groups:remove: rule:system_admin_or_owner

# Create security group Rule. This API is deprecated.
#   POST /os-security-group-rules
#os_compute_api:os-security-groups:rule:create: rule:system_admin_or_owner

# Delete security group Rule. This API is deprecated.
#   DELETE /os-security-group-rules/{security_group_id}
#os_compute_api:os-security-groups:rule:delete: rule:system_admin_or_owner

# Show security group. This API is deprecated.
#   GET /os-security-groups/{security_group_id}
#os_compute_api:os-security-groups:show: rule:system_or_project_reader

# Update security group. This API is deprecated.
#   PUT /os-security-groups/{security_group_id}
#os_compute_api:os-security-groups:update: rule:system_admin_or_owner

# Clear the encrypted administrative password of a server
#   DELETE /servers/{server_id}/os-server-password
#os_compute_api:os-server-password:clear: rule:system_admin_or_owner

# Show the encrypted administrative password of a server
#   GET /servers/{server_id}/os-server-password
#os_compute_api:os-server-password:show: rule:system_or_project_reader

# Delete a single tag from the specified server
#   DELETE /servers/{server_id}/tags/{tag}
#os_compute_api:os-server-tags:delete: rule:system_admin_or_owner

# Delete all the server tags
#   DELETE /servers/{server_id}/tags
#os_compute_api:os-server-tags:delete_all: rule:system_admin_or_owner

# List all tags for given server
#   GET /servers/{server_id}/tags
#os_compute_api:os-server-tags:index: rule:system_or_project_reader

# Check tag existence on the server.
#   GET /servers/{server_id}/tags/{tag}
#os_compute_api:os-server-tags:show: rule:system_or_project_reader

# Add a single tag to the server if server has no specified tag
#   PUT /servers/{server_id}/tags/{tag}
#os_compute_api:os-server-tags:update: rule:system_admin_or_owner

# Replace all tags on specified server with the new set of tags.
#   PUT /servers/{server_id}/tags
#os_compute_api:os-server-tags:update_all: rule:system_admin_or_owner

# Delete a Compute service.
#   DELETE /os-services/{service_id}
#os_compute_api:os-services:delete: rule:system_admin_api

# List all running Compute services in a region.
#   GET /os-services
#os_compute_api:os-services:list: rule:system_reader_api

# Update a Compute service.
#   PUT /os-services/{service_id}
#os_compute_api:os-services:update: rule:system_admin_api

# List project networks.
# This API is proxy calls to the Network service. This is deprecated.
#   GET /os-tenant-networks
#os_compute_api:os-tenant-networks:list: rule:system_or_project_reader

# Show project network details.
# This API is proxy calls to the Network service. This is deprecated.
#   GET /os-tenant-networks/{network_id}
#os_compute_api:os-tenant-networks:show: rule:system_or_project_reader

# Unrescue a server
#   POST /servers/{server_id}/action (unrescue)
#os_compute_api:os-unrescue: rule:system_admin_or_owner

# Update a volume attachment with a different volumeId
#   PUT /servers/{server_id}/os-volume_attachments/{volume_id}
#os_compute_api:os-volumes-attachments:swap: rule:system_admin_api

# Create volume.
# This API is a proxy call to the Volume service. It is deprecated.
#   POST /os-volumes
#os_compute_api:os-volumes:create: rule:system_admin_or_owner

# Delete volume.
# This API is a proxy call to the Volume service. It is deprecated.
#   DELETE /os-volumes/{volume_id}
#os_compute_api:os-volumes:delete: rule:system_admin_or_owner

# List volumes detail.
# This API is a proxy call to the Volume service. It is deprecated.
#   GET /os-volumes/detail
#os_compute_api:os-volumes:detail: rule:system_or_project_reader

# List volumes.
# This API is a proxy call to the Volume service. It is deprecated.
#   GET /os-volumes
#os_compute_api:os-volumes:list: rule:system_or_project_reader

# Show volume.
# This API is a proxy call to the Volume service. It is deprecated.
#   GET /os-volumes/{volume_id}
#os_compute_api:os-volumes:show: rule:system_or_project_reader

# Create snapshots.
# This API is a proxy call to the Volume service. It is deprecated.
#   POST /os-snapshots
#os_compute_api:os-volumes:snapshots:create: rule:system_admin_or_owner

# Delete snapshot.
# This API is a proxy call to the Volume service. It is deprecated.
#   DELETE /os-snapshots/{snapshot_id}
#os_compute_api:os-volumes:snapshots:delete: rule:system_admin_or_owner

# List snapshots details.
# This API is a proxy call to the Volume service. It is deprecated.
#   GET /os-snapshots/detail
#os_compute_api:os-volumes:snapshots:detail: rule:system_or_project_reader

# List snapshots.
# This API is a proxy call to the Volume service. It is deprecated.
#   GET /os-snapshots
#os_compute_api:os-volumes:snapshots:list: rule:system_or_project_reader

# Show snapshot.
# This API is a proxy call to the Volume service. It is deprecated.
#   GET /os-snapshots/{snapshot_id}
#os_compute_api:os-volumes:snapshots:show: rule:system_or_project_reader

# Allow all filters when listing servers
#   GET /servers
#   GET /servers/detail
#os_compute_api:servers:allow_all_filters: rule:system_reader_api

# Create a server with trusted image certificate IDs
#   POST /servers
#os_compute_api:servers:create:trusted_certs: rule:project_member_api

# This rule controls the compute API validation behavior of creating a server
# with a flavor that has 0 disk, indicating the server should be volume-backed.
# For a flavor with disk=0, the root disk will be set to exactly the size of the
# image used to deploy the instance. However, in this case the filter_scheduler
# cannot select the compute host based on the virtual image size. Therefore, 0
# should only be used for volume booted instances or for testing purposes.
# WARNING: It is a potential security exposure to enable this policy rule
# if users can upload their own images since repeated attempts to
# create a disk=0 flavor instance with a large image can exhaust
# the local disk of the compute (or shared storage cluster). See bug
# https://bugs.launchpad.net/nova/+bug/1739646 for details.
#   POST /servers
#os_compute_api:servers:create:zero_disk_flavor: rule:project_admin_api

# Rebuild a server with trusted image certificate IDs
#   POST /servers/{server_id}/action (rebuild)
#os_compute_api:servers:rebuild:trusted_certs: rule:system_admin_or_owner

# Show a server with additional host status information, only if host status is
# UNKNOWN.
# This policy rule will only be enforced when the
# os_compute_api:servers:show:host_status policy rule does not pass for the
# request. An example policy configuration could be where the
# os_compute_api:servers:show:host_status rule is set to allow admin-only and
# the os_compute_api:servers:show:host_status:unknown-only rule is set to
# allow everyone.
#   GET /servers/{server_id}
#   GET /servers/detail
#   PUT /servers/{server_id}
#   POST /servers/{server_id}/action (rebuild)
#os_compute_api:servers:show:host_status:unknown-only: rule:system_admin_api
