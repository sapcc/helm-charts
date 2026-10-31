# Verbatim CAPI core CRDs

Upstream: [kubernetes-sigs/cluster-api](https://github.com/kubernetes-sigs/cluster-api),
commit `5f7d58c9ad647f31bd342bf8de33092c27f7fc38` (v1.14.2),
directory `core/config/crd/bases/`. These three files are byte-for-byte upstream;
no headers, schemas, versions or formatting have been modified. Upstream license:
[Apache-2.0](https://github.com/kubernetes-sigs/cluster-api/blob/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/LICENSE).

| File | SHA-256 |
| --- | --- |
| `cluster.x-k8s.io_clusters.yaml` | `39768d1dbe14c7932e4fc4aacd90fcc08395f5922f74886e1a3d87868ce8d997` |
| `ipam.cluster.x-k8s.io_ipaddresses.yaml` | `d5068e3d0031f0cca9514492712384d4325b2481d3e6854da1192dc6d88c28cd` |
| `ipam.cluster.x-k8s.io_ipaddressclaims.yaml` | `28b61b0fc4c4a66ed2d9ca70c488eae210251662a7d2bcb5cc3ad93c46e6fa19` |

Download provenance (maintenance only, not a Kustomize resource):
`https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/<file>`.
`tests/remote_sources_test.sh` requires these exact bytes and exactly three files.
Only `kustomization.yaml` adds the explicit `conversion.strategy: None` default
at render time. Do not vendor the full CAPI directory or the provider CRDs;
the latter still use the pinned public Git base.
