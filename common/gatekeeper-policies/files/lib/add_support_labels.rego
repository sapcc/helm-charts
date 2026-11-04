package lib.add_support_labels

# `obj` must be a full Kubernetes object.
from_k8s_object(obj, msg) := result if {
	support_group := object.get(obj, ["metadata", "labels", "ccloud/support-group"], "none")
	service := object.get(obj, ["metadata", "labels", "ccloud/service"], "none")
	result := sprintf("{\"support_group\":%s,\"service\":%s} >> %s", [json.marshal(support_group), json.marshal(service), msg])
}

# `body` must be the response body from helm-manifest-parser
from_helm_release(body, msg) := result if {
	support_group := object.get(body, ["owner_info", "support-group"], "none")
	service := object.get(body, ["owner_info", "service"], "none")
	result := sprintf("{\"support_group\":%s,\"service\":%s} >> %s", [json.marshal(support_group), json.marshal(service), msg])
}

# Adds an additional label to a message that already had support labels added with one of the above methods.
# For example:
#
# ```rego
# msgWithLabels := add_support_labels.extra("severity", "warning", add_support_labels.from_k8s_object(iro, msg))
# ```
#
# Test coverage for this function is obtained in the policies using it.
extra(key, value, msg) := result if {
	result := sprintf("{%s:%s,%s", [json.marshal(key), json.marshal(value), trim_prefix(msg, "{")])
}
