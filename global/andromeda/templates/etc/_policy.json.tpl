{
  "cloud_admin": "(project_domain_name:ccadmin and project_name:cloud_admin) or user_domain_id:default",
  "project_scope": "project_id:%(project_id)s",
  "public_scope": "'public':%(scope)s",
  "shared_scope": "'shared':%(scope)s",
  "member": "role:member and rule:project_scope",
  "viewer": "role:gtm_viewer and rule:project_scope",
  "admin": "role:gtm_admin and rule:project_scope",

  "context_is_admin": "rule:cloud_admin or rule:admin",
  "context_is_editor": "rule:context_is_admin or rule:member",
  "context_is_viewer": "rule:context_is_editor or rule:viewer",

  "andromeda:domain:get_all": "rule:context_is_viewer",
  "andromeda:domain:post": "rule:context_is_editor",
  "andromeda:domain:put": "rule:context_is_editor",
  "andromeda:domain:get_one": "rule:context_is_viewer",
  "andromeda:domain:delete": "rule:context_is_editor",

  "andromeda:pool:get_all": "rule:context_is_viewer",
  "andromeda:pool:post": "rule:context_is_editor",
  "andromeda:pool:put": "rule:context_is_editor",
  "andromeda:pool:get_one": "rule:context_is_viewer",
  "andromeda:pool:delete": "rule:context_is_editor",

  "andromeda:member:get_all": "rule:context_is_viewer",
  "andromeda:member:post": "rule:context_is_editor",
  "andromeda:member:put": "rule:context_is_editor",
  "andromeda:member:get_one": "rule:context_is_viewer",
  "andromeda:member:delete": "rule:context_is_editor",

  "andromeda:monitor:get_all": "rule:context_is_viewer",
  "andromeda:monitor:post": "rule:context_is_editor",
  "andromeda:monitor:put": "rule:context_is_editor",
  "andromeda:monitor:get_one": "rule:context_is_viewer",
  "andromeda:monitor:delete": "rule:context_is_editor",

  "andromeda:datacenter:get_all": "rule:context_is_viewer or rule:public_scope",
  "andromeda:datacenter:post": "rule:context_is_editor",
  "andromeda:datacenter:put": "rule:context_is_editor",
  "andromeda:datacenter:get_one": "rule:context_is_viewer or rule:public_scope",
  "andromeda:datacenter:delete": "rule:context_is_editor",

  "andromeda:geomap:get_all": "rule:context_is_viewer or rule:shared_scope",
  "andromeda:geomap:post": "rule:context_is_editor",
  "andromeda:geomap:put": "rule:context_is_editor",
  "andromeda:geomap:get_one": "rule:context_is_viewer or rule:shared_scope",
  "andromeda:geomap:delete": "rule:context_is_editor",

  "andromeda:service:get_all": "rule:cloud_admin",
  "andromeda:sync:post": "rule:cloud_admin",
  "andromeda:cidr-blocks:get": "rule:context_is_viewer",

  "andromeda:quota:get_all": "rule:context_is_viewer",
  "andromeda:quota:get_all-global": "rule:cloud_admin",
  "andromeda:quota:get_one": "rule:context_is_viewer",
  "andromeda:quota:get_one-global": "rule:cloud_admin",
  "andromeda:quota:put": "rule:cloud_admin",
  "andromeda:quota:delete": "rule:cloud_admin"
}
