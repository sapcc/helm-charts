package lib.validation

import rego.v1

is_region_name(region) := false if {
	not is_string(region)
}

is_region_name(region) := result if {
	is_string(region)
	result := regex.match("^[a-z][a-z]-[a-z][a-z]-[0-9]$", region)
}
