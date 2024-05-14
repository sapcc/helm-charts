package lib.image_check

# The public interface is the function for_pod(pod, baseURL). `pod` must be a
# Pod object. `baseURL` is where doop-image-checker is running. This usually
# comes from the policy's `input.parameters`.
#
# This function inspects the ContainerStatus of all containers and init
# containers in this Pod by calling doop-image-checker. The response is a list
# of check results.
#
# A failing check returns an object with only the field "error". This error
# message must be converted into a violation by the calling policy. (This step
# is something that we cannot do in a library module.)
#
# A successful check returns an object with the following fields:
# - "containerName", "containerImage" (values copied from `container`)
# - "error" (empty string; having this simplifies error checks in the calling policy)
# - "headers" (the parsed response body from doop-image-checker)
#
# There is also the variant function for_pod_template(pod_template, baseURL),
# which can be used if only a pod template is available.
# This uses the image reference from the container spec instead of from the
# container status, which may not reflect the container's state if the tag was
# repushed after the pod was started.

for_pod(pod, baseURL) = result {
  pod.kind != "Pod"
  result = [{"error": "not a pod"}]
}
for_pod(pod, baseURL) = result {
  pod.kind == "Pod"

  containerStatuses := array.concat(
    object.get(pod, ["status", "containerStatuses"], []),
    object.get(pod, ["status", "initContainerStatuses"], []),
  )
  result = [ __run_check(c, baseURL, true) | c := containerStatuses[_] ]
}

for_pod_template(podTemplate, baseURL) = result {
  containerSpecs := array.concat(
    object.get(podTemplate, ["spec", "containers"], []),
    object.get(podTemplate, ["spec", "initContainers"], []),
  )
  result = [ __run_check(c, baseURL, false) | c := containerSpecs[_] ]
}

################################################################################
# private helper functions

__run_check(container, baseURL, hasImageID) = result {
  not regex.match("^keppel\\.", container.image)

  # For images not in Keppel, we return a synthetic result that does not generate
  # any additional violations. Elsewhere, we have policies that complain about
  # non-Keppel images in general, so we don't need to double-report this.
  nowAsUnixTime := time.now_ns() / 1000000000
  result = {
    "error": "",
    "containerName": container.name,
    "containerImage": container.image,
    "headers": {
      "X-Keppel-Min-Layer-Created-At": format_int(nowAsUnixTime, 10),
      "X-Keppel-Vulnerability-Status": "Clean",
    },
  }
}
__run_check(container, baseURL, hasImageID) = result {
  regex.match("^keppel\\.", container.image)

  imageRef := __get_image_ref(container, hasImageID)
  url := sprintf("%s/v1/headers?image=%s", [baseURL, imageRef])
  resp := http.send({"url": url, "method": "GET", "raise_error": false, "timeout": "15s"})
  result = __parse_response(container, resp)
}

__get_image_ref(container, hasImageID) = result {
  hasImageID
  result := trim_prefix(container.imageID, "docker-pullable://")
}
__get_image_ref(container, hasImageID) = result {
  not hasImageID
  result := container.image
}

__parse_response(container, resp) = result {
  resp.status_code == 200
  result := {
    "error": "",
    "containerName": container.name,
    "containerImage": container.image,
    "headers": resp.body,
  }
}
__parse_response(container, resp) = result {
  resp.status_code != 200
  object.get(resp, ["error", "message"], "") == ""
  result := { "error": sprintf("doop-image-checker returned HTTP status %d, but we expected 200. Please retry in ~5 minutes.", [resp.status_code]) }
}
__parse_response(container, resp) = result {
  resp.status_code != 200
  msg := object.get(resp, ["error", "message"], "")
  msg != ""
  result := { "error": sprintf("Could not reach doop-image-checker (%q). Please retry in ~5 minutes.", [msg]) }
}
