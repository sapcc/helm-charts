{{- define "gatekeeper-sap-policies.lib.validation" -}}
package lib.validation

is_region_name(region) := false if {
	not is_string(region)
}

is_region_name(region) := result if {
	is_string(region)
	result := regex.match("^[a-z][a-z]-[a-z][a-z]-[0-9]$", region)
}
{{- end }}

{{- define "gatekeeper-sap-policies.lib.add_support_labels" -}}
package lib.add_support_labels

# `obj` must be a full Kubernetes object.
from_k8s_object(obj, msg) := result if {
	owned_by := object.get(obj, ["metadata", "labels", "greenhouse.sap/owned-by"], "none")
	result := sprintf("{\"owned_by\":%s} >> %s", [json.marshal(owned_by), msg])
}

# `body` must be the response body from helm-manifest-parser
from_helm_release(body, msg) := result if {
	owned_by := object.get(body, ["owner_info", "owned-by"], "none")
	result := sprintf("{\"owned_by\":%s} >> %s", [json.marshal(owned_by), msg])
}

# Adds an additional label to a message that already had support labels added with one of the above methods.
extra(key, value, msg) := result if {
	result := sprintf("{%s:%s,%s", [json.marshal(key), json.marshal(value), trim_prefix(msg, "{")])
}
{{- end }}

{{- define "gatekeeper-sap-policies.lib.helm_release" -}}
package lib.helm_release

# Returns {"error": ""} for non-Helm Secrets so callers can short-circuit without
# emitting violations. The Constraint should use match.labelSelector to filter
# down to Helm release Secrets in the first place; this guard is a defence in
# depth.
parse_k8s_object(obj, baseURL) := result if {
	not __is_helm_release(obj)
	result := {"error": "", "items": [], "owner_info": {}}
}

parse_k8s_object(obj, baseURL) := result if {
	__is_helm_release(obj)
	url := sprintf("%s/v3", [baseURL])
	resp := http.send({"url": url, "method": "POST", "raise_error": false, "raw_body": obj.data.release, "timeout": "15s"})
	result := __parse_response(resp)
}

is_helm_release(obj) if __is_helm_release(obj)

__is_helm_release(obj) if {
	obj.kind == "Secret"
	obj.type == "helm.sh/release.v1"
}

__is_helm_release(obj) := false if {
	obj.kind != "Secret"
}

__is_helm_release(obj) := false if {
	obj.type != "helm.sh/release.v1"
}

__parse_response(resp) := result if {
	resp.status_code == 200
	result := object.union(resp.body, {"error": ""})
}

__parse_response(resp) := result if {
	resp.status_code != 200
	object.get(resp, ["error", "message"], "") == ""
	result := {"error": sprintf("helm-manifest-parser returned HTTP status %d, but we expected 200. Please retry in ~5 minutes.", [resp.status_code])}
}

__parse_response(resp) := result if {
	resp.status_code != 200
	msg := object.get(resp, ["error", "message"], "")
	msg != ""
	result := {"error": sprintf("Could not reach helm-manifest-parser (%q). Please retry in ~5 minutes.", [msg])}
}
{{- end }}

{{- define "gatekeeper-sap-policies.lib.traversal" -}}
package lib.traversal

default find_pod(obj) := {"isFound": false}

find_pod(obj) := result if {
	obj.kind == "Pod"
	result := __return_pod_unless_suppressed(obj, __list_suppressing_owners(obj))
}

find_pod(obj) := result if {
	obj.kind != "Pod"
	location := object.get(__pod_template_locations, [obj.kind], [])
	location != []
	pod := object.get(obj, location, {})
	result := __return_pod_unless_suppressed(pod, __list_suppressing_owners(obj))
}

find_container_specs(obj) := result if {
	result := __extract_container_specs(find_pod(obj))
}

__pod_template_locations := {
	"CronJob": ["spec", "jobTemplate", "spec", "template"],
	"DaemonSet": ["spec", "template"],
	"Deployment": ["spec", "template"],
	"Job": ["spec", "template"],
	"ReplicaSet": ["spec", "template"],
	"StatefulSet": ["spec", "template"],
}

__suppressing_owner_kinds := {
	"Job": ["CronJob"],
	"Pod": ["DaemonSet", "Job", "ReplicaSet", "StatefulSet"],
	"ReplicaSet": ["Deployment"],
}

__list_suppressing_owners(obj) := result if {
	possible_owners := object.get(__suppressing_owner_kinds, [obj.kind], [])
	result := [ref.kind |
		ref := obj.metadata.ownerReferences[_]
		ref.kind == possible_owners[_]
	]
}

__return_pod_unless_suppressed(obj, owners) := result if {
	count(owners) > 0
	result := {"isFound": false}
}

__return_pod_unless_suppressed(obj, owners) := result if {
	count(owners) == 0
	result := object.union(obj, {"isFound": true})
}

__extract_container_specs(pod) := [] if {
	not pod.isFound
}

__extract_container_specs(pod) := result if {
	pod.isFound
	result := array.concat(
		object.get(pod.spec, "containers", []),
		object.get(pod.spec, "initContainers", []),
	)
}
{{- end }}
