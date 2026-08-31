package ownerinfoonhelmreleases

import data.lib.add_support_labels
import data.lib.helm_release

iro := input.review.object
release := helm_release.parse_k8s_object(iro, input.parameters.helmManifestParserURL)

violation contains {"msg": release.error} if {
    release.error != ""
}

configmap_name := sprintf("owner-of-%s", [iro.metadata.labels.name])

configmaps contains obj if {
    release.error == ""

    obj := release.items[_]
    obj.kind == "ConfigMap"
    obj.metadata.name == configmap_name
}

violation contains {"msg": add_support_labels.from_helm_release(release, msg)} if {
    release.error == ""

    # Complain if no 'owner-of-<release-name>' ConfigMap exists for this release.
    count(configmaps) == 0

    # Do not complain if this release is part of the knownBrokenReleases.
    key := sprintf("%s/%s", [iro.metadata.namespace, iro.metadata.labels.name])
    count({k | k := input.parameters.knownBrokenReleases[_]; k == key}) == 0

    msg := "Chart does not contain owner info. Please add the common/owner-info chart as a direct dependency."
}

violation contains {"msg": add_support_labels.from_helm_release(release, msg)} if {
    release.error == ""

    count(configmaps) > 0

    # Check if the owner-info chart is not outdated
    upToDateVersion := "0.2.0"
    obj := configmaps[_]
    version := object.get(obj.metadata, ["labels", "owner-info-version"], "")
    semver.compare(version, upToDateVersion) < 0

    msg := sprintf(
        "Chart uses outdated owner-info version %q. Please update to at least %q.",
        [version, upToDateVersion],
    )
}
