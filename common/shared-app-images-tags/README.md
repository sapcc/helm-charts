# shared-app-images-tags

This helper chart always contains the most recent versions of our `shared-app-images`, as built by
the internal CI pipeline of the same name. The pipeline will take care of updating this chart's
`values.yaml` whenever new images are published, so you can receive image updates with a simple
`helm dep up`.

## Correct approach: Use provided template functions

To look up a tag for one of the `shared-app-images`, use the `shared-app-images.tag` function:

```
image: "{{ .Values.global.registry }}/shared-app-images/alpine-busybox:{{ include "shared-app-images.tag" (tuple $ "alpine-busybox" "3.22") }}"
```

The function call at the end will expand into an appropriate tag like `3.22-20251209181023`.
There is an alternative helper function, `shared-app-images.ref`, that also takes care of writing
the correct image repository. The following example is equivalent to the one above:

```
image: {{ include "shared-app-images.ref" (tuple $ "alpine-busybox" "3.22") }}
```

There are two different such functions:

- `shared-app-images.ref` generates a reference to the regional Keppel instance, using
  `.Values.global.registry` from the global `globals.yaml`. Most users will want to use this.
- `shared-app-images.ref_using_alternate` refers to Keppel in the alternate region instead, using
  `.Values.global.registryAlternateRegion` from the global `globals.yaml`. Only use this if you
  cannot depend on the local Keppel to avoid circular dependencies.

## Discouraged: Do not use values directly

Consider this example:

```
image: {{ .Values.global.registry }}/shared-app-images/alpine-busybox:{{ index .Values "shared-app-images-tags" "alpine-busybox" "3.22" }}
```

If Alpine 3.22 falls out of support and no matching image is provided anymore, the `index` call will
return an empty string, which will be accepted by Helm, but then cause errors on Kubernetes level.
Please avoid this and use the provided template functions, which will provide a more explicit error
at Helm template evaluation time.
