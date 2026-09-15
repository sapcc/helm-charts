package libtestaddsupportlabels

import data.lib.add_support_labels
import data.lib.helm_release

iro := input.review.object

violation contains {"msg": add_support_labels.from_helm_release(release, msg)} if {
    # from_helm_release() is tested with Secret objects containing Helm releases
    iro.kind == "Secret"
    release := helm_release.parse_k8s_object(iro, input.parameters.helmManifestParserURL)
    release.error == ""
    msg := "test for from_helm_release()"
}

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    # from_k8s_object() is tested with Pod objects
    iro.kind == "Pod"
    msg := "test for from_k8s_object()"
}
