package lib.traversal

### find_pod(obj)
#
# Find a Pod object or template within the given k8s object. For Pods, `obj`
# itself is returned; but e.g. for Deployments, `.spec.template` is returned.
#
# On success, the returned object will have {"isFound": true} added to it.
# If no Pod is found, an object with just {"isFound": false} is returned.
#
# Pods that are owned by a ReplicaSet etc. are suppressed to avoid
# double-reporting. (We report on the highest level possible to reduce the
# number of total violations that are generated; there is no use in generating
# 30 violations for 30 replicas of the same Deployment.)
#
default find_pod(obj) := {"isFound": false}

find_pod(obj) := result if {
	# case 1: `obj` is a Pod itself
	obj.kind == "Pod"
	result := __return_pod_unless_suppressed(obj, __list_suppressing_owners(obj))
}

find_pod(obj) := result if {
	# case 2: `obj` is not a Pod -> look for a Pod template
	obj.kind != "Pod"
	location := object.get(__pod_template_locations, [obj.kind], [])
	location != []
	pod := object.get(obj, location, {})
	result := __return_pod_unless_suppressed(pod, __list_suppressing_owners(obj))
}

### find_container_specs(obj)
#
# Find all ContainerSpecs within the given k8s object. This looks for a
# Pod using find_pod() and considers its containers as well as init containers.
#
find_container_specs(obj) := result if {
	result := __extract_container_specs(find_pod(obj))
}

################################################################################
# private helper functions for find_pod()

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
	# If a pod has ownerReferences to a pod owner that we recognize, we suppress
	# the pod and report violations only on the topmost owner.
	count(owners) > 0
	result := {"isFound": false}
}

__return_pod_unless_suppressed(obj, owners) := result if {
	count(owners) == 0
	result := object.union(obj, {"isFound": true})
}

################################################################################
# private helper functions for find_container_specs()

__extract_container_specs(pod) := [] if {
	not pod.isFound
}

__extract_container_specs(pod) := result if {
	pod.isFound

	# We have to use object.get() to get a zero value in case the key doesn't exist
	# because array.concat() only works if both of its arguments are non-nil (i.e.
	# an array, even if it's empty).
	result := array.concat(
		object.get(pod.spec, "containers", []),
		object.get(pod.spec, "initContainers", []),
	)
}
