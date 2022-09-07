package lib.traversal

### find_pod(obj)
#
# Find a Pod object or template  within the given k8s object. For Pods, `obj`
# itself is returned; but e.g. for Deployments, `.spec.template` is returned.
#
# On success, the returned object will have {"found": true} added to it.
# If no Pod is found, an object with just {"found": false} is returned.
#
# Pods that are owned by a ReplicaSet etc. are ignored to avoid
# double-reporting. (We report on the highest level possible to reduce the
# number of total violations that are generated; there is no use in generating
# 30 violations for 30 replicas of the same Deployment.)
#
find_pod(obj) = result {
  # case 1: `obj` is a Pod itself
  obj.kind == "Pod"
  owners := [ref.kind | ref := obj.metadata.ownerReferences[_]; ref.kind == __pod_owners[_]]
  result := __return_pod_unless_ignored(obj, owners)
}
find_pod(obj) = result {
  # case 2: `obj` contains a PodSpec
  obj.kind == __violation_owners[_]
  result := object.union(obj.spec.template, { "found": true })
}
find_pod(obj) = result {
  # case 3: neither Pod nor PodSpec
  obj.kind != "Pod"
  count([kind | kind := __violation_owners[_]; obj.kind == kind ]) == 0
  result := { "found": false }
}

### find_container_specs(obj)
#
# Find all ContainerSpecs within the given k8s object. This looks for a
# Pod using find_pod() and considers its containers as well as init containers.
#
find_container_specs(obj) = result {
  result := __extract_container_specs(find_pod(obj))
}

################################################################################
# private helper functions for find_pod_spec()

__violation_owners = {"Deployment", "DaemonSet", "StatefulSet", "Job"}
__pod_owners       = {"ReplicaSet", "DaemonSet", "StatefulSet", "Job"}

__return_pod_unless_ignored(obj, owners) = result {
  # If a pod has ownerReferences to a pod owner that we recognize, we ignore
  # the pod and report violations only on the topmost owner.
  count(owners) > 0
  result := { "found": false }
}
__return_pod_unless_ignored(obj, owners) = result {
  count(owners) == 0
  result := object.union(obj, { "found": true })
}

################################################################################
# private helper functions for find_container_specs()

__extract_container_specs(pod) = [] {
  not pod.found
}
__extract_container_specs(pod) = result {
  pod.found
  # We have to use object.get() to get a zero value in case the key doesn't exist
  # because array.concat() only works if both of its arguments are non-nil (i.e.
  # an array, even if it's empty).
  result := array.concat(
    object.get(pod.spec, "containers", []),
    object.get(pod.spec, "initContainers", []),
  )
}
