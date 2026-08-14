package podlabels

import data.lib.add_support_labels
import data.lib.traversal

iro := input.review.object
pod := traversal.find_pod(iro)
support_group := object.get(iro, ["metadata", "labels", "ccloud/support-group"], "none")

# ^ NOTE: It would make more semantic sense to check for labels on the
# Pod (instead of the owning object). However, the owner-label-injector
# is rightfully hesitant to inject labels into a pod template to avoid
# unexpected pod restarts. Instead, we only check that the owning
# object is labelled correctly. After that, we have to trust the
# owner-label-injector to carry over those labels into the pod correctly.

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    pod.isFound
    support_group == "none"
    msg := "pod does not have the required label: ccloud/support-group"
}

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    pod.isFound
    support_group != "none"
    found := {true | support_group == input.parameters.known_support_groups[_]}
    count(found) == 0
    msg := sprintf("pod has an unacceptable label value: ccloud/support-group=%q", [support_group])
}
