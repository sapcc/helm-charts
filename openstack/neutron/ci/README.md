# Image digest regression

From the repository root:

```sh
helm dependency build openstack/neutron --skip-refresh
python3 openstack/neutron/ci/test-image-digests.py
helm lint openstack/neutron -f openstack/neutron/ci/image-digests-values.yaml
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
sidecars, both uWSGI/RPC paths, component image overrides, digest rotation,
53-character releases, long mixed-case tags, DNS-safe bounded migration names,
exact dependency values, metadata labels and retained image pins.
