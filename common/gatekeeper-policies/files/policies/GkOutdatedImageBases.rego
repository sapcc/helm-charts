package outdatedimagebases

import data.lib.add_support_labels
import data.lib.image_check
import data.lib.traversal

iro := input.review.object
pod := traversal.find_pod(iro)
checks := image_check.for_pod_template(pod, input.parameters.doopImageCheckerURL)

violation contains {"msg": check.error} if {
    pod.isFound
    check := checks[_]
    check.error != ""
}

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    pod.isFound
    check := checks[_]
    check.error == ""
    createdAtAsUnixTime := to_number(trim_space(object.get(check.headers, "X-Keppel-Min-Layer-Created-At", "Unclear")))

    # complain if it's older than one year
    nowAsUnixTime := time.now_ns() / 1000000000
    ageInSeconds := nowAsUnixTime - createdAtAsUnixTime
    ageInDays := ageInSeconds / 86400
    ageInDays > 365

    msg := sprintf(
        "image %s for container %q uses a very old base image (oldest layer is %.0f days old)",
        [check.containerImage, check.containerName, ageInDays],
    )
}
