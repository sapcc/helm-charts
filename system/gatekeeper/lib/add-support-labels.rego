package lib.add_support_labels

# `obj` must be a full Kubernetes object.
from_k8s_object(obj, msg) = result {
  support_group := object.get(obj, ["metadata", "labels", "cc/support-group"], "none")
  service := object.get(obj, ["metadata", "labels", "cc/service"], "none")
  result := sprintf("support-group=%s,service=%s: %s", [support_group, service, msg])
}

# `body` must be the response body from helm-manifest-parser
from_helm_release(body, msg) = result {
  support_group := object.get(body, ["values", "owner-info", "support-group"], "none")
  service := object.get(body, ["values", "owner-info", "service"], "none")
  result := sprintf("support-group=%s,service=%s: %s", [support_group, service, msg])
}
