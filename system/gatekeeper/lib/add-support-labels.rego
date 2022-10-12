package lib.add_support_labels

# `obj` must be a full Kubernetes object.
from_k8s_object(obj, msg) = result {
  support_group := object.get(obj, ["metadata", "labels", "ccloud/support-group"], "none")
  service := object.get(obj, ["metadata", "labels", "ccloud/service"], "none")
  result := sprintf("support-group=%s,service=%s: %s", [support_group, service, msg])
}

# `body` must be the response body from helm-manifest-parser
from_helm_release(body, msg) = result {
  support_group := object.get(body, ["owner_info", "support-group"], "none")
  service := object.get(body, ["owner_info", "service"], "none")
  result := sprintf("support-group=%s,service=%s: %s", [support_group, service, msg])
}
