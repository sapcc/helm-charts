{
    "project_scope": "project_id:%(project_id)s",
    "domain_scope": "domain_id:%(domain_id)s",
  
    "domain_viewer":  "rule:domain_scope and ( role:monitoring_viewer or role:monitoring_admin )",
    "project_viewer": "rule:project_scope and ( role:monitoring_viewer or role:monitoring_admin )",
    "project_or_domain_viewer": "rule:domain_viewer or rule:project_viewer",
  
    "metric:list":     "rule:project_or_domain_viewer",
    "metric:show":     "rule:project_or_domain_viewer"
  }