# Image digest regressions

Requires Helm, Mike Farah `yq` v4 and Python 3.9+ (standard library only). No Helm
plugin or chart dependencies are needed; the real chart is rendered in every case.

From the repository root:

```sh
common/mariadb-galera/helm/tests/image-digests.py
```

From `common/mariadb-galera/helm`:

```sh
tests/image-digests.py
```

The runner compares complete ordinary manifests against the original chart at
`04f4dbf7da48feb93e052fe1e2597f8415cae1e1`, including numeric build defaults and
the existing `default_values.yaml`. Only the bumped `helm.sh/chart` label and the
chart's existing random Job/CronJob name suffixes are normalized. It then checks
that pins change only images, enables ProxySQL/HAProxy, monitoring, FS-permission
init containers, Kopia backup/restore, and checks all six components, matching and
conflicting pins, digest rotation, long labels, plain `MARIADB_VERSION` values,
repository overrides and disabled optional workloads.

If the baseline commit is absent from a shallow clone, make it available first
or supply `--baseline-chart /path/to/original/common/mariadb-galera/helm`. A different
original revision can be selected with `--baseline-ref <commit>`.

The existing `08-containerimages_test.yaml` and `09-labels_test.yaml` also contain
digest assertions for environments that already have the Helm unittest plugin.
