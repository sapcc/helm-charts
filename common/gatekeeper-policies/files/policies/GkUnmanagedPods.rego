package unmanagedpods

import data.lib.add_support_labels

iro := input.review.object

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    iro.kind == "Pod"
    object.get(iro.metadata, ["ownerReferences"], []) == []
    not is_allowed_by_exception
    msg := "pod is not owned by a managing construct"
}

default is_allowed_by_exception := false

is_allowed_by_exception if {
    iro.metadata.namespace == "default"
    regex.match("^recycler-for-", iro.metadata.name)
}
