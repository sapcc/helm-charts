# ---- Roles → convenience rules ----
"key_admin": "role:keymanager_admin"
"viewer": "role:keymanager_viewer"

"context_is_admin": "rule:key_admin"
"context_is_editor": "rule:context_is_admin"
"context_is_viewer": "rule:context_is_admin or rule:viewer"

# ---- Common object-scoping and ownership ----
"secret_project_match": "project_id:%(target.secret.project_id)s"
"container_project_match": "project_id:%(target.container.project_id)s"
"order_project_match": "project_id:%(target.order.project_id)s"

"secret_creator_user": "user_id:%(target.secret.creator_id)s"
"container_creator_user": "user_id:%(target.container.creator_id)s"

# ---- Privacy / ACL flags ----
"secret_private_read": "'False':%(target.secret.read_project_access)s"
"container_private_read": "'False':%(target.container.read_project_access)s"
"secret_acl_read": "'read':%(target.secret.read)s"
"container_acl_read": "'read':%(target.container.read)s"

# ---- Derived non-private read guards (project-scoped) ----
"secret_non_private_read": "rule:context_is_viewer and rule:secret_project_match and not rule:secret_private_read"
"secret_decrypt_non_private_read": "rule:context_is_viewer and rule:secret_project_match and not rule:secret_private_read"
"container_non_private_read": "rule:context_is_viewer and rule:container_project_match and not rule:container_private_read"

# ---- Project-scoped admin/creator (creator still requires admin for writes) ----
"secret_project_admin": "rule:context_is_admin and rule:secret_project_match"
"secret_project_creator": "rule:context_is_admin and rule:secret_project_match and rule:secret_creator_user"

"container_project_admin": "rule:context_is_admin and rule:container_project_match"
"container_project_creator": "rule:context_is_admin and rule:container_project_match and rule:container_creator_user"

# ---- Version ----
"version:get": "@"

# ---- Secrets ----
"secret:get": "rule:secret_project_admin or rule:secret_project_creator or rule:secret_non_private_read or rule:secret_acl_read"
"secret:decrypt": "rule:secret_project_admin or rule:secret_project_creator or rule:secret_decrypt_non_private_read or rule:secret_acl_read"

"secrets:post": "rule:context_is_editor"
"secret:put": "rule:context_is_editor and rule:secret_project_match"
"secret:delete": "rule:secret_project_admin or rule:secret_project_creator"

"secrets:get": "rule:context_is_viewer"

# ---- Secret metadata ----
"secret_meta:get": "rule:secret_project_admin or rule:secret_project_creator or rule:secret_non_private_read or rule:secret_acl_read"
"secret_meta:post": "rule:context_is_editor and rule:secret_project_match"
"secret_meta:put":  "rule:context_is_editor and rule:secret_project_match"
"secret_meta:delete": "rule:context_is_editor and rule:secret_project_match"

# ---- Secret ACLs ----
"secret_acls:get": "rule:context_is_viewer and rule:secret_project_match"
"secret_acls:put_patch": "rule:secret_project_admin or rule:secret_project_creator"
"secret_acls:delete": "rule:secret_project_admin or rule:secret_project_creator"

# ---- Containers ----
"containers:post": "rule:context_is_editor"
"containers:get": "rule:context_is_viewer"

"container:get": "rule:container_project_admin or rule:container_project_creator or rule:container_non_private_read or rule:container_acl_read"
"container:delete": "rule:container_project_admin or rule:container_project_creator"

# Attach/detach secrets to existing container → require project match
"container_secret:post": "rule:context_is_admin and rule:container_project_match"
"container_secret:delete": "rule:context_is_admin and rule:container_project_match"

# ---- Container ACLs ----
"container_acls:get": "rule:context_is_viewer and rule:container_project_match"
"container_acls:put_patch": "rule:container_project_admin or rule:container_project_creator"
"container_acls:delete": "rule:container_project_admin or rule:container_project_creator"

# ---- Consumers ----
# View consumers (viewer must be in same project or use non-private/ACL/admin)
"consumer:get": "(rule:context_is_viewer and rule:container_project_match) or rule:container_non_private_read or rule:container_project_admin or rule:container_acl_read"
"container_consumers:get": "(rule:context_is_viewer and rule:container_project_match) or rule:container_non_private_read or rule:container_project_admin or rule:container_acl_read"

# Modify consumers on an existing container → require project match on admin/ACL paths
"container_consumers:post": "(rule:context_is_admin and rule:container_project_match) or rule:container_project_creator or rule:container_project_admin or (rule:container_acl_read and rule:container_project_match)"
"container_consumers:delete": "(rule:context_is_admin and rule:container_project_match) or rule:container_project_creator or rule:container_project_admin or (rule:container_acl_read and rule:container_project_match)"

# ---- Secret consumers ----
"secret_consumers:get": "rule:context_is_viewer and rule:secret_project_match"
"secret_consumers:post": "rule:context_is_editor and rule:secret_project_match"
"secret_consumers:delete": "rule:context_is_editor and rule:secret_project_match"

# ---- Orders ----
"orders:get": "rule:context_is_viewer"
"orders:post": "rule:context_is_editor"
"orders:put": "rule:context_is_editor"

"order_project_member": "rule:context_is_viewer and rule:order_project_match"
"order:get": "rule:order_project_member"
"order:delete": "rule:context_is_admin and rule:order_project_member"

# ---- Quotas ----
"quotas:get": "rule:context_is_viewer"
"project_quotas:get": "rule:context_is_admin"
"project_quotas:put": "rule:context_is_admin"
"project_quotas:delete": "rule:context_is_admin"

# ---- Transport keys ----
"transport_keys:get": "rule:context_is_viewer"
"transport_key:get": "rule:context_is_viewer"
"transport_keys:post": "rule:context_is_admin"
"transport_key:delete": "rule:context_is_admin"

# ---- Secret stores ----
"secretstores:get": "rule:context_is_admin"
"secretstores:get_global_default": "rule:context_is_admin"
"secretstores:get_preferred": "rule:context_is_admin"
"secretstore_preferred:post": "rule:context_is_admin"
"secretstore_preferred:delete": "rule:context_is_admin"
"secretstore:get": "rule:context_is_admin"

# ---- Certificate Authorities ----
"certificate_authorities:get_limited": "rule:context_is_viewer"
"certificate_authorities:get_preferred_ca": "rule:context_is_viewer"

"certificate_authorities:get_all": "rule:context_is_admin"
"certificate_authorities:post": "rule:context_is_admin"
"certificate_authorities:unset_global_preferred": "rule:context_is_admin"
"certificate_authorities:get_global_preferred_ca": "rule:context_is_admin"

"certificate_authority:get": "rule:context_is_viewer"
"certificate_authority:get_cacert": "rule:context_is_viewer"
"certificate_authority:get_ca_cert_chain": "rule:context_is_viewer"

"certificate_authority:delete": "rule:context_is_admin"
"certificate_authority:get_projects": "rule:context_is_admin"
"certificate_authority:add_to_project": "rule:context_is_admin"
"certificate_authority:remove_from_project": "rule:context_is_admin"
"certificate_authority:set_preferred": "rule:context_is_admin"
"certificate_authority:set_global_preferred": "rule:context_is_admin"
