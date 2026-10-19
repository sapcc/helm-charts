# System Charts

This folder contains charts required by the control plane.

## Building charts

Use `make build-<chart>` to regenerate a chart from upstream sources and bump its patch version.

### metal-operator-remote: dev releases

To roll out a change only to the dev cluster without going through the full release train, build a pre-release chart version:

```
make build-metal-operator-remote DEV=1  # produces e.g. 0.6.50-dev
make build-metal-operator-remote        # produces e.g. 0.6.50 (stable)
```

Pre-release versions (semver `-dev` suffix) are ignored by all Concourse pipelines except the dev cluster pipeline, which passes `--devel` to helm and therefore picks them up.
