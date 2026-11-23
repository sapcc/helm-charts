# Image digest regression

From the repository root:

```sh
helm dependency build openstack/octavia --skip-refresh
python3 openstack/octavia/ci/test-image-digests.py
helm lint openstack/octavia -f openstack/octavia/ci/image-digests-values.yaml
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
sidecars, an enabled F5 worker and watcher/statsd, statsd image overrides,
external AS3, digest rotation, 53-character releases, long mixed-case tags,
DNS-safe bounded migration names, all three dependency consumers, metadata
labels and retained image pins.
