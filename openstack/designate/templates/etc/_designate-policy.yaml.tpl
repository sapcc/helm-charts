admin: rule:context_is_cloud_admin or is_admin:True
primary_zone: target.zone_type:SECONDARY

owner: project_id:%(tenant_id)s
target: project_id:%(target_project_id)s
shared: "'True':%(zone_shared)s"

owner_or_zone_shared: rule:owner or rule:shared

admin_or_owner_or_zone_shared: rule:owner_or_zone_shared or rule:admin
dns_admin: role:dns_admin and rule:owner

member: role:member and rule:owner
member_and_shared: role:member and rule:owner_or_zone_shared

viewer: role:dns_viewer and rule:owner
viewer_and_shared: role:dns_viewer and rule:owner_or_zone_shared
cloud_dns_viewer: role:cloud_dns_viewer
cloud_dns_backup: role:cloud_dns_backup

context_is_cloud_admin: role:cloud_dns_admin
context_is_dns_ops: rule:context_is_cloud_admin or role:cloud_dns_ops or rule:admin
context_is_dns_support: rule:context_is_dns_ops or role:cloud_dns_support
context_is_zonemaster: rule:context_is_dns_support or (role:dns_zonemaster and rule:owner_or_zone_shared)
context_is_hostmaster: rule:context_is_dns_support or (role:dns_hostmaster and rule:owner_or_zone_shared)
context_is_mailmaster: rule:context_is_dns_support or (role:dns_mailmaster and rule:owner_or_zone_shared)
context_is_webmaster: rule:context_is_dns_support or rule:context_is_mailmaster or rule:context_is_hostmaster or (role:dns_webmaster and rule:owner_or_zone_shared)
context_is_editor: rule:dns_admin or rule:member or rule:admin
context_is_viewer: rule:viewer_and_shared or rule:member_and_shared or rule:context_is_master or rule:context_is_editor or rule:viewer or rule:member or rule:cloud_dns_viewer or rule:cloud_dns_backup
context_is_master: rule:context_is_dns_support or rule:context_is_zonemaster or rule:context_is_hostmaster or rule:context_is_mailmaster or rule:context_is_webmaster or rule:context_is_editor

zone_primary_or_dns_ops: "('PRIMARY':%(zone_type)s and rule:context_is_dns_ops) or ('SECONDARY':%(zone_type)s and is_admin:True)"

default: rule:admin_or_owner_or_zone_shared
all_tenants: rule:context_is_dns_support or rule:cloud_dns_viewer or rule:cloud_dns_backup
edit_managed_records: rule:context_is_master
use_low_ttl: rule:context_is_dns_support
get_quotas: rule:context_is_viewer
get_quota: rule:context_is_viewer
set_quota: rule:admin
reset_quotas: rule:admin
create_tld: rule:admin
find_tlds: rule:admin
get_tld: rule:admin
update_tld: rule:admin
delete_tld: rule:admin
create_tsigkey: rule:admin
find_tsigkeys: rule:admin or rule:cloud_dns_backup
get_tsigkey: rule:admin or rule:cloud_dns_backup
update_tsigkey: rule:admin
delete_tsigkey: rule:admin
find_tenants: rule:admin or rule:context_is_dns_ops
get_tenant: rule:admin or rule:context_is_dns_ops
count_tenants: rule:admin or rule:context_is_dns_ops
share_zone: rule:context_is_master
unshare_zone: rule:context_is_master
create_zone: rule:context_is_dns_ops
move_zone: rule:context_is_dns_ops
pool_move_zone: rule:context_is_dns_ops
create_sub_zone: rule:context_is_zonemaster
create_sub_zone_other_project: role:cloud_dns_admin
create_super_zone: rule:context_is_cloud_admin
get_zones: rule:context_is_viewer
get_zone: rule:context_is_viewer
get_shared_zone: rule:context_is_viewer
get_zone_share: rule:context_is_viewer
get_zone_servers: rule:context_is_viewer
get_zone_ns_records: rule:context_is_viewer
find_zones: rule:context_is_viewer
find_zone: rule:context_is_viewer
find_shared_zones: rule:context_is_viewer
find_zone_shares: "@"
find_project_zone_share: rule:context_is_viewer
update_zone: rule:context_is_master
update_sub_zone: rule:context_is_master
delete_zone: rule:context_is_master
xfr_zone: rule:context_is_master
abandon_zone: rule:context_is_dns_ops
count_zones: rule:context_is_viewer
count_zones_pending_notify: rule:context_is_viewer
purge_zones: rule:admin
touch_zone: rule:context_is_master

create_A_recordset: rule:context_is_webmaster or rule:context_is_editor
create_AAAA_recordset: rule:context_is_webmaster or rule:context_is_editor
create_CNAME_recordset: rule:context_is_webmaster or rule:context_is_editor
create_CAA_recordset: rule:context_is_webmaster or rule:context_is_editor
create_CERT_recordset: rule:context_is_webmaster or rule:context_is_editor
create_MX_recordset: rule:context_is_mailmaster
create_NS_recordset: rule:context_is_hostmaster
create_PTR_recordset: rule:context_is_webmaster or rule:context_is_editor
create_SOA_recordset: "!"
create_SPF_recordset: rule:context_is_mailmaster
create_SRV_recordset: rule:context_is_webmaster or rule:context_is_editor
create_SSHFP_recordset: rule:admin
create_NAPTR_recordset: rule:admin
create_TXT_recordset: rule:context_is_webmaster or rule:context_is_editor
create_HTTPS_recordset: rule:context_is_webmaster or rule:context_is_editor
create_SVCB_recordset: rule:context_is_webmaster or rule:context_is_editor

update_A_recordset: rule:context_is_webmaster or rule:context_is_editor
update_AAAA_recordset: rule:context_is_webmaster or rule:context_is_editor
update_CNAME_recordset: rule:context_is_webmaster or rule:context_is_editor
update_CAA_recordset: rule:context_is_webmaster or rule:context_is_editor
update_CERT_recordset: rule:context_is_webmaster or rule:context_is_editor
update_MX_recordset: rule:context_is_mailmaster
update_NS_recordset: rule:context_is_hostmaster
update_PTR_recordset: rule:context_is_webmaster or rule:context_is_editor
update_SOA_recordset: "!"
update_SPF_recordset: rule:context_is_mailmaster
update_SRV_recordset: rule:context_is_webmaster or rule:context_is_editor
update_SSHFP_recordset: rule:admin
update_NAPTR_recordset: rule:admin
update_TXT_recordset: rule:context_is_webmaster or rule:context_is_editor
update_HTTPS_recordset: rule:context_is_webmaster or rule:context_is_editor
update_SVCB_recordset: rule:context_is_webmaster or rule:context_is_editor

delete_A_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_AAAA_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_CNAME_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_CAA_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_CERT_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_MX_recordset: (role:dns_mailmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_NS_recordset: (role:dns_hostmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_PTR_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_SOA_recordset: "!"
delete_SPF_recordset: (role:dns_mailmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_SRV_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_SSHFP_recordset: rule:admin
delete_NAPTR_recordset: rule:admin
delete_TXT_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_HTTPS_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support
delete_SVCB_recordset: (role:dns_webmaster and (project_id:%(recordset_project_id)s)) or rule:context_is_editor or rule:context_is_dns_support

get_recordsets: rule:context_is_viewer
get_recordset: rule:context_is_viewer
find_recordsets: rule:context_is_viewer
find_recordset: rule:context_is_viewer
count_recordset: rule:context_is_viewer
create_record: rule:context_is_master
get_records: rule:context_is_viewer
get_record: rule:context_is_viewer
find_records: rule:context_is_viewer
find_record: rule:context_is_viewer
update_record: rule:context_is_master
delete_record: rule:context_is_master
count_records: rule:context_is_viewer
use_sudo: rule:context_is_dns_ops
hard_delete: rule:context_is_dns_ops
create_blacklist: rule:context_is_dns_ops
find_blacklist: rule:context_is_dns_support
find_blacklists: rule:context_is_dns_support
get_blacklist: rule:context_is_dns_support
update_blacklist: rule:context_is_dns_ops
delete_blacklist: rule:context_is_dns_ops
use_blacklisted_zone: rule:context_is_cloud_admin

create_pool: rule:admin
find_pools: rule:admin or rule:context_is_dns_ops
find_pool: rule:admin or rule:context_is_dns_ops
get_pool: rule:admin or rule:context_is_dns_ops
update_pool: rule:admin
delete_pool: rule:admin
zone_create_forced_pool: rule:admin or role:cloud_dns_support or role:cloud_dns_ops or role:dns_zonemaster

diagnostics_ping: rule:admin
diagnostics_sync_zones: rule:admin
diagnostics_sync_zone: rule:admin
diagnostics_sync_record: rule:admin

create_zone_transfer_request: rule:context_is_dns_support
create_sub_zone_transfer_request: rule:context_is_zonemaster

get_zone_transfer_request: rule:context_is_master or project_id:%(target_project_id)s or None:%(target_project_id)s
get_zone_transfer_request_detailed: rule:context_is_master
find_zone_transfer_requests: "@"
find_zone_transfer_request: "@"
update_zone_transfer_request: rule:context_is_zonemaster
delete_zone_transfer_request: rule:context_is_zonemaster
create_zone_transfer_accept: rule:context_is_master or project_id:%(target_project_id)s or None:%(target_project_id)s
get_zone_transfer_accept: rule:context_is_master
find_zone_transfer_accepts: rule:admin
find_zone_transfer_accept: rule:admin
update_zone_transfer_accept: rule:admin
delete_zone_transfer_accept: rule:admin

create_zone_import: rule:context_is_dns_ops
create_force_zone_import: rule:context_is_zonemaster
find_zone_imports: rule:context_is_dns_ops
get_zone_import: rule:context_is_zonemaster
update_zone_import: rule:context_is_dns_ops
delete_zone_import: rule:context_is_dns_ops

zone_export: rule:context_is_master
create_zone_export: rule:context_is_master
find_zone_exports: rule:context_is_master
get_zone_export: rule:context_is_master
update_zone_export: rule:context_is_master
delete_zone_export: rule:context_is_master

find_service_status: rule:admin
find_service_statuses: rule:admin
update_service_status: rule:admin
delete_service_status: rule:admin
