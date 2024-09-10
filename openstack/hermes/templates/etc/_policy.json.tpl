{
  "project_scope": "project_id:%(project_id)s",
  "domain_scope": "domain_id:%(domain_id)s",

  "cluster_viewer": "project_domain_name:ccadmin and project_name:cloud_admin",
  "domain_viewer":  "rule:domain_scope and role:audit_viewer",
  "project_viewer": "rule:project_scope and role:audit_viewer",

  "event:list":     "rule:project_viewer or rule:domain_viewer or rule:cluster_viewer",
  "event:show":     "rule:project_viewer or rule:domain_viewer or rule:cluster_viewer"
}
