# Image digest regression

From the repository root:

```sh
helm dependency build openstack/nova --skip-refresh
python3 openstack/nova/ci/test-image-digests.py
helm lint openstack/nova -f openstack/nova/ci/image-digests-values.yaml
```

From this chart: `python3 ci/test-image-digests.py` (or the executable script).
Requires Helm, Mike Farah yq v4 and Python 3; dependency registry access is
required for the first command. Do not commit downloaded dependency archives.

The test reuses `test-values.yaml` and overlays the standalone pinned fixture.
Ordinary cases override only `imageVersion` with the fixture's plain tag.
`original-job-name.tpl` preserves the pre-change naming helper. Tests restore
it in a temporary copy of the real chart and compare complete ordinary
manifests, with the current chart version on both sides. Pinned comparison
normalizes only image pins and generated Job names/references.

Checks cover disabled/host-alias/unix-socket ProxySQL, native and ordinary
sidecars, optional cells and real dependency aliases, component image overrides,
both migration Jobs, digest rotation, 53-character releases, long mixed-case
tags, exact dependency values and retained image pins.

The pinned migration Job labels must always be valid. With a 53-character
release, older MariaDB aliases already produce overlong instance labels;
the test explicitly compares those labels to the original chart and reports
them, instead of changing unrelated dependency versions or accepting new
invalid labels. All metadata labels are validated in ordinary-length cases.
