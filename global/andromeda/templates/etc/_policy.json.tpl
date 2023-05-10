{
  "cloud_admin": "project_domain_name:ccadmin and project_name:cloud_admin",
  "member": "role:member",
  "viewer": "role:gtm_viewer",
  "admin": "role:gtm_admin",

  "context_is_admin": "rule:cloud_admin or rule:admin",
  "context_is_editor": "rule:context_is_admin or rule:member",
  "context_is_viewer": "rule:context_is_editor or rule:viewer",

  "andromeda:domain:get_all": "rule:context_is_viewer",
  "andromeda:domain:get_all-global": "rule:cloud_admin",
  "andromeda:domain:post": "rule:context_is_editor",
  "andromeda:domain:put": "rule:context_is_editor",
  "andromeda:domain:get_one": "rule:context_is_viewer",
  "andromeda:domain:delete": "rule:context_is_editor",

  "andromeda:pool:get_all": "rule:context_is_viewer",
  "andromeda:pool:get_all-global": "rule:cloud_admin",
  "andromeda:pool:post": "rule:context_is_editor",
  "andromeda:pool:put": "rule:context_is_editor",
  "andromeda:pool:get_one": "rule:context_is_viewer",
  "andromeda:pool:delete": "rule:context_is_editor",

  "andromeda:member:get_all": "rule:context_is_viewer",
  "andromeda:member:get_all-global": "rule:cloud_admin",
  "andromeda:member:post": "rule:context_is_editor",
  "andromeda:member:put": "rule:context_is_editor",
  "andromeda:member:get_one": "rule:context_is_viewer",
  "andromeda:member:delete": "rule:context_is_editor",

  "andromeda:monitor:get_all": "rule:context_is_viewer",
  "andromeda:monitor:get_all-global": "rule:cloud_admin",
  "andromeda:monitor:post": "rule:context_is_editor",
  "andromeda:monitor:put": "rule:context_is_editor",
  "andromeda:monitor:get_one": "rule:context_is_viewer",
  "andromeda:monitor:delete": "rule:context_is_editor",

  "andromeda:datacenter:get_all": "rule:context_is_viewer",
  "andromeda:datacenter:get_all-global": "rule:cloud_admin",
  "andromeda:datacenter:post": "rule:context_is_editor",
  "andromeda:datacenter:put": "rule:context_is_editor",
  "andromeda:datacenter:get_one": "rule:context_is_viewer",
  "andromeda:datacenter:delete": "rule:context_is_editor",

  "andromeda:service:get_all": "rule:context_is_admin",
  "andromeda:sync:post": "rule:context_is_admin",

  "andromeda:quota:get_all": "rule:context_is_viewer",
  "andromeda:quota:get_one": "rule:context_is_viewer",
  "andromeda:quota:put": "rule:context_is_admin",
  "andromeda:quota:delete": "rule:context_is_admin"
}