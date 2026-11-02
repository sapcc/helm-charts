# CAPI core CRDs (remote, SHA-pinned)

Upstream: [kubernetes-sigs/cluster-api](https://github.com/kubernetes-sigs/cluster-api),
commit `5f7d58c9ad647f31bd342bf8de33092c27f7fc38` (v1.14.2),
directory `core/config/crd/bases/`. Upstream license:
[Apache-2.0](https://github.com/kubernetes-sigs/cluster-api/blob/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/LICENSE).

These three CRDs are **not vendored**. `kustomization.yaml` references each one
individually as a SHA-pinned raw file URL, so the exact upstream bytes are
fetched at render time rather than copied into this repository:

| File | Resource URL |
| --- | --- |
| `cluster.x-k8s.io_clusters.yaml` | `https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/cluster.x-k8s.io_clusters.yaml` |
| `ipam.cluster.x-k8s.io_ipaddresses.yaml` | `https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/ipam.cluster.x-k8s.io_ipaddresses.yaml` |
| `ipam.cluster.x-k8s.io_ipaddressclaims.yaml` | `https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/ipam.cluster.x-k8s.io_ipaddressclaims.yaml` |

The ref segment MUST be a full 40-character commit SHA (immutable), never a
mutable tag/branch. `tests/remote_sources_test.sh` asserts the exact three URLs
and that the ref is a full SHA, and rejects a mutable tag, the full CAPI
directory, or any vendored `*.yaml` reappearing here. CAPI's
`core/config/crd/bases` bundles 13 CRDs, so only these three are referenced
individually — never the whole directory.

Only `kustomization.yaml` adds the explicit `conversion.strategy: None` default
at render time (upstream omits `conversion`). The four provider pool CRDs use a
separate pinned public Git directory base.
