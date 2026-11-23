# Image digest regression

From the repository root:

```sh
helm dependency build global/ccloud-hedgedoc
python3 global/ccloud-hedgedoc/vendor/codimd/ci/test-image-digests.py
```

Or, from this chart: `python3 ci/test-image-digests.py` after building the parent's
dependencies. Requires Helm, Mike Farah yq v4, Python 3 and dependency-registry access.

Checks full standalone and parent manifests, metadata/Pod labels, Service
selectors, optional Ingress/PVC/Secrets, image defaults and digest retention.
Ordinary output is compared to actual original templates from commit
`04f4dbf7da48feb93e052fe1e2597f8415cae1e1` (override with
`IMAGE_DIGEST_BASE_REF`). Only the vendored chart version is aligned to exclude
expected version-label/checksum differences. The baseline parent uses the
original CodiMD source and the same real external dependencies, without mocks.

The parent uses `file://vendor/codimd` with a permissive version constraint.
Only its lockfile's CodiMD version and digest change; other dependency versions
and the parent chart version remain unchanged. Fetched archives are not committed.
