package restrictmonsoon3namespace

iro := input.review.object
n := iro.metadata.namespace

violation contains {"msg": msg} if {
    iro.kind == "Secret"
    pattern := input.parameters.patterns[n]

    matches := regex.find_all_string_submatch_n("^sh\\.helm\\.release\\.v1\\.(.*?)\\.v\\d+$", iro.metadata.name, 2)
    release_name = matches[0][1]

    not regex.match(pattern, release_name)

    msg := sprintf("helm release %q is not allowed in namespace %q", [release_name, n])
}
