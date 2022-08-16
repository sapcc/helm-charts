package lib.validation

is_region_name(region) = false {
  not is_string(region)
}

is_region_name(region) = result {
  is_string(region)
  result := regex.match("^[a-z][a-z]-[a-z][a-z]-[0-9]$", region)
}
