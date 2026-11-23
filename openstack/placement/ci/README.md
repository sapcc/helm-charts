# Image digest regression

From the repository root:

```sh
helm dependency build openstack/placement --skip-refresh
python3 openstack/placement/ci/test-image-digests.py
helm lint openstack/placement -f openstack/placement/ci/image-digests-values.yaml
```

From this chart: `python3 ci/test-image-digests.py` (or the executable script).
Requires Helm, Mike Farah yq v4 and Python 3; dependency registry access is
required for the first command. Do not commit downloaded dependency archives.

The test reuses `test-values.yaml` and overlays the standalone pinned fixture
with a DNS-safe plain tag. Ordinary cases override only `imageVersion` with
that tag. `original-job-name.tpl` preserves the pre-change naming helper.
Tests restore it in a temporary copy of the real chart and compare complete
ordinary manifests, with the current chart version on both sides. Pinned
comparison normalizes only image pins and generated Job names/references.

Checks cover disabled/host-alias/unix-socket ProxySQL, native and ordinary
sidecars, MariaDB enabled/disabled and database overrides, both migration Jobs,
digest rotation, 53-character releases, long mixed-case tags, DNS-safe bounded
Job names, exact dependency values, metadata labels and retained image pins.
