package lib.helm_release

# The public interface is the function parse_k8s_object(obj, baseURL). `obj`
# must be a full Kubernetes object. A Secret containing a Helm release must be
# given, otherwise an error will be returned. `baseURL` is where
# helm-manifest-parser is running. This usually comes from the policy's
# `input.parameters`.
#
# If parsing fails, an object with only the field "error" is returned.
# This error message must be converted into a violation by the calling policy.
# (This step is something that we cannot do in a library module.)
#
# If parsing succeeds, the parsed response body from helm-manifest-parser is
# returned. Additionally, the returned object will have the field "error" set
# to the empty string, in order to simplify error checks in the calling policy.

parse_k8s_object(obj, baseURL) := result if {
	# NOTE: This branch is defense in depth. Constraints using this function
	# should already be limited to suitable objects via their selectors.
	not __is_helm_release(obj)
	result := {"error": "Input to helm_manifest_parser.parse_release() is not a Helm release. This is an error in the policy implementation."}
}

parse_k8s_object(obj, baseURL) := result if {
	# This code is structured to ensure that http.send() is never executed more
	# than once.
	__is_helm_release(obj)
	url := sprintf("%s/v3", [baseURL])
	resp := http.send({"url": url, "method": "POST", "raise_error": false, "raw_body": obj.data.release, "timeout": "15s"})
	result := __parse_response(resp)
}

################################################################################
# private helper functions

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
