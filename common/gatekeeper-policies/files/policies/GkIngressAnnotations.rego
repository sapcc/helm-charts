package ingressannotations

import data.lib.add_support_labels

iro := input.review.object
annotations := object.get(iro, ["metadata", "annotations"], {})

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    iro.kind == "Ingress"
    annotations[key]
    pattern := input.parameters.regexes[_]
    regex.match(pattern, key)
    msg := sprintf("has disabled annotation: %q (%s)", [key, input.parameters.hint])
}
