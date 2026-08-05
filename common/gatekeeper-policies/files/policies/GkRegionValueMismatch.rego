package gkregionvaluemissing

import data.lib.add_support_labels
import data.lib.helm_release
import data.lib.validation

iro := input.review.object
release := helm_release.parse_k8s_object(iro, input.parameters.helmManifestParserURL)

violation contains {"msg": release.error} if {
    release.error != ""
}

violation contains {"msg": add_support_labels.from_helm_release(release, msg)} if {
    release.error == ""

    region := object.get(release, ["values", "global", "region"], "")
    not region == "global"
    validation.is_region_name(region)
    input.parameters.region != region

    msg := sprintf(".Values.global.region does not match the deployed region: expected %s, but found \"%s\"", [input.parameters.region, region])
}

violation contains {"msg": add_support_labels.from_helm_release(release, msg)} if {
    release.error == ""

    region := object.get(release, ["values", "global", "region"], "")
    region == "global"
    db_region := object.get(release, ["values", "global", "db_region"], "")
    validation.is_region_name(db_region)
    input.parameters.region != db_region

    msg := sprintf(".Values.global.db_region does not match the deployed region: expected %s, but found \"%s\"", [input.parameters.region, db_region])
}
