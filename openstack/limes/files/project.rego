package limes

# policy: only allow Keppel quota when the user also has Swift quota (a Swift account is required for Keppel accounts to work correctly)
violations[{"msg": msg, "service": "keppel", "resource": "images"}] {
  srv1 := input.targetprojectreport.services[_]
  srv1.type == "keppel"
  res1 := srv.resources[_]
  res1.name == "images"
  res1.quota != 0

  srv2 := input.targetprojectreport.services[_]
  srv2.type == "object-store"
  res2 := srv.resources[_]
  res2.name == "capacity"
  res2.quota == 0

  msg := "quota for keppel/images is only allowed when object-store/capacity quota is non-zero"
}
