# pxc-operator

Helm chart to deploy percona-xtradb-cluster-operator in  `pxc-operator` namespace.

Compared [percona/pxc-operator](https://github.com/percona/percona-helm-charts/tree/main/charts/pxc-operator) provides simplified custom way to install pxc-operator in Converged Cloud.

Main differences:
- CRDs moved to pxc-crds chart
- Configures only cluster-wide mode
- Added pre-defined ccloud labels
- Added prometheus and linkerd labels
- Added ccloud nodeAffinity configuration
