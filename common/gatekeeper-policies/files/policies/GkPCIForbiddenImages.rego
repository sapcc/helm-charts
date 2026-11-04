package pciforbiddenimages

import data.lib.add_support_labels
import data.lib.traversal

iro := input.review.object
containers := traversal.find_container_specs(iro)

violation contains {"msg": add_support_labels.from_k8s_object(iro, msg)} if {
    container := iro.spec.containers[_]

    pattern := input.parameters.patterns[_]
    regex.match(pattern, container.image)

    msg := sprintf("container %q uses forbidden image: %s", [container.name, container.image])
}
