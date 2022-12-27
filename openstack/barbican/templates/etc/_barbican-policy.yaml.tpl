"admin": "role:cloud_keymanager_admin"
"context_is_admin": "rule:admin"
"service_admin": "rule:admin or role:resource_service"
"service_user": "role:service"
"viewer": "role:keymanager_viewer"
"key_admin": "role:keymanager_admin"

"context_is_key_admin": "rule:context_is_admin or rule:key_admin"
"context_is_editor": "rule:context_is_key_admin"
"context_is_viewer": "rule:context_is_editor or rule:viewer"

"secret_non_private_read": "rule:context_is_viewer and rule:secret_project_match and not rule:secret_private_read"
"secret_decrypt_non_private_read": "rule:context_is_viewer and rule:secret_project_match and not rule:secret_private_read"
"container_non_private_read": "rule:context_is_viewer and rule:container_project_match and not rule:container_private_read"

"secret_project_admin": "rule:context_is_key_admin and rule:secret_project_match"
"secret_project_creator": "rule:context_is_editor and rule:secret_project_match and rule:secret_creator_user"
"container_project_admin": "rule:context_is_key_admin and rule:container_project_match"
"container_project_creator": "rule:context_is_editor and rule:container_project_match and rule:container_creator_user"

"version:get": "@"
"secret:decrypt": "rule:service_user or rule:secret_decrypt_non_private_read or rule:secret_project_creator or rule:secret_project_admin or rule:secret_acl_read"
"secret:get": "rule:service_user or rule:secret_non_private_read or rule:secret_project_creator or rule:secret_project_admin or rule:secret_acl_read"
"secret:put": "rule:context_is_editor and rule:secret_project_match"
"secret:delete": "rule:secret_project_admin or rule:secret_project_creator"

"secrets:post": "rule:context_is_editor"
"secrets:get": "rule:context_is_viewer"

"orders:post": "rule:context_is_editor"
"orders:get": "rule:context_is_viewer"
"order:get": "rule:context_is_viewer"
"orders:put": "rule:context_is_editor"
"order:delete": "rule:context_is_key_admin"

"consumer:get": "rule:service_user or rule:context_is_viewer or rule:container_non_private_read or rule:container_project_admin or rule:container_acl_read"
"container_consumers:get": "rule:context_is_viewer or rule:container_non_private_read or rule:container_project_admin or rule:container_acl_read"
"container_consumers:post": "rule:context_is_key_admin or rule:container_non_private_read or rule:container_project_creator or rule:container_project_admin or rule:container_acl_read"
"container_consumers:delete": "rule:service_user or rule:context_is_key_admin or rule:container_non_private_read or rule:container_project_creator or rule:container_project_admin or rule:container_acl_read"

"containers:post": "rule:context_is_editor"
"containers:get": "rule:context_is_viewer"
"container:get": "rule:service_user or rule:container_non_private_read or rule:container_project_creator or rule:container_project_admin or rule:container_acl_read"
"container:delete": "rule:container_project_admin or rule:container_project_creator"

"container_secret:post": "rule:context_is_key_admin"
"container_secret:delete": "rule:context_is_key_admin"

"transport_key:get": "rule:context_is_viewer"
"transport_key:delete": "rule:context_is_key_admin"
"transport_keys:get": "rule:context_is_viewer"
"transport_keys:post": "rule:context_is_key_admin"

"certificate_authorities:get_limited": "rule:context_is_viewer"
"certificate_authorities:get_all": "rule:context_is_key_admin"
"certificate_authorities:post": "rule:context_is_key_admin"
"certificate_authorities:get_preferred_ca": "rule:context_is_viewer"
"certificate_authorities:get_global_preferred_ca": "rule:context_is_admin"
"certificate_authorities:unset_global_preferred": "rule:context_is_admin"

"certificate_authority:delete": "rule:context_is_key_admin"
"certificate_authority:get": "rule:context_is_viewer"
"certificate_authority:get_cacert": "rule:context_is_viewer"
"certificate_authority:get_ca_cert_chain": "rule:context_is_viewer"
"certificate_authority:get_projects": "rule:context_is_admin"
"certificate_authority:add_to_project": "rule:context_is_key_admin"
"certificate_authority:remove_from_project": "rule:context_is_key_admin"
"certificate_authority:set_preferred": "rule:context_is_key_admin"
"certificate_authority:set_global_preferred": "rule:context_is_admin"

"secret_acls:put_patch": "rule:secret_project_admin or rule:secret_project_creator"
"secret_acls:delete": "rule:secret_project_admin or rule:secret_project_creator"
"secret_acls:get": "rule:context_is_viewer and rule:secret_project_match"

"container_acls:put_patch": "rule:container_project_admin or rule:container_project_creator"
"container_acls:delete": "rule:container_project_admin or rule:container_project_creator"
"container_acls:get": "rule:context_is_viewer and rule:container_project_match"

"quotas:get": "rule:context_is_viewer"

"project_quotas:get": "rule:service_admin"
"project_quotas:put": "rule:service_admin"
"project_quotas:delete": "rule:service_admin"

"secret_meta:get": "rule:context_is_viewer"
"secret_meta:post": "rule:context_is_editor"
"secret_meta:put": "rule:context_is_editor"
"secret_meta:delete": "rule:context_is_editor"

"secretstores:get": "rule:context_is_key_admin"
"secretstores:get_global_default": "rule:context_is_key_admin"
"secretstores:get_preferred": "rule:context_is_key_admin"

"secretstore_preferred:post": "rule:context_is_key_admin"
"secretstore_preferred:delete": "rule:context_is_key_admin"
"secretstore:get": "rule:context_is_key_admin"
