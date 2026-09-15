package deprecatedapiversion

import data.lib.add_support_labels
import data.lib.helm_release

iro := input.review.object

release := helm_release.parse_k8s_object(iro, input.parameters.helmManifestParserURL)

violation contains {"msg": release.error} if {
    release.error != ""
}

violation contains {"msg": add_support_labels.from_helm_release(release, msg)} if {
    release.error == ""

    # find objects in the manifest that use deprecated API versions
    obj := release.items[_]
    input.parameters.apiVersions[_] == obj.apiVersion

    msg := sprintf(
        "%s %s declared with deprecated API version: %s (will break in k8s v%s)",
        [obj.kind, obj.metadata.name, obj.apiVersion, input.parameters.kubernetesVersion],
    )
}
