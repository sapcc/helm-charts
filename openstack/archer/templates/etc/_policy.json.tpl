{
  "cloud_admin": "project_domain_name:ccadmin and project_name:cloud_admin",
  "owner": "project_id:%(project_id)s",
  "member": "role:member and rule:owner",
  "viewer": "role:archer_viewer and rule:owner",
  "admin": "role:archer_admin and rule:owner",

  "context_is_admin": "rule:cloud_admin or rule:admin",
  "context_is_editor": "rule:context_is_admin or rule:member",
  "context_is_viewer": "rule:context_is_editor or rule:viewer",

  "service:read": "rule:context_is_viewer",
  "service:read-global": "rule:context_is_admin",
  "service:create": "rule:context_is_editor",
  "service:update": "rule:context_is_editor",
  "service:delete": "rule:context_is_editor",

  "service-endpoint:read": "rule:context_is_viewer",
  "service-endpoint:accept": "rule:context_is_editor",
  "service-endpoint:reject": "rule:context_is_editor",

  "endpoint:read": "rule:context_is_viewer",
  "endpoint:read-global": "rule:context_is_admin",
  "endpoint:create": "rule:context_is_editor",
  "endpoint:delete": "rule:context_is_editor",

  "rbac-policy:read": "rule:context_is_viewer",
  "rbac-policy:create": "rule:context_is_editor",
  "rbac-policy:update": "rule:context_is_editor",
  "rbac-policy:delete": "rule:context_is_editor",

  "quota:read": "rule:context_is_admin",
  "quota:read-defaults": "rule:context_is_viewer",
  "quota:update": "rule:context_is_admin",
  "quota:delete": "rule:context_is_admin"
}