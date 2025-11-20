{
  "readwrite": "role:cloud_resource_admin or (user_name:limes and user_domain_name:Default)",
  "readonly": "role:cloud_resource_viewer or rule:readwrite",
  "liquid:get_info": "rule:readonly",
  "liquid:get_capacity": "rule:readonly",
  "liquid:get_usage": "rule:readonly",
  "liquid:set_quota": "rule:readwrite",
  "liquid:change_commitments": "rule:readwrite"
}
