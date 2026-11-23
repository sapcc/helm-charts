# Image digest regression

From the repository root:

```sh
helm dependency build global/bots4devsupport
python3 global/bots4devsupport/ci/test-image-digests.py
```

Or, from this chart: `python3 ci/test-image-digests.py` after building dependencies.
Requires Helm, Mike Farah yq v4, Python 3 and access to the dependency registry.
The test compares full ordinary manifests against original templates from commit
`04f4dbf7da48feb93e052fe1e2597f8415cae1e1` (override with
`IMAGE_DIGEST_BASE_REF`), aligning only the chart version to avoid expected
version-label/checksum changes from the release bump. No dependency is mocked.
