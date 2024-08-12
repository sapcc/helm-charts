{
    "project_scope": "project_id:%(project_id)s",
    "domain_scope": "domain_id:%(domain_id)s",
  
    "domain_viewer":  "rule:domain_scope",
    "project_viewer": "rule:project_scope",
    "project_or_domain_viewer": "rule:domain_viewer or rule:project_viewer",
  
    "metric:list":     "rule:project_or_domain_viewer",
    "metric:show":     "rule:project_or_domain_viewer"
  }