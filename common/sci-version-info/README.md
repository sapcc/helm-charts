# sci-version-info

This chart deploys a ConfigMap that names the release's application image. `sci-label-injector`
reads that image reference to stamp `cloud.sap/sci-version` and `cloud.sap/sci-product` onto the
release's objects.

This chart **should not** be deployed stand-alone, it is meant to be used as a dependency
by other charts.

**Caveat:** Only use `sci-version-info` for the top-level chart (i.e. the chart that you're
deploying). If you use it for any dependencies of your top-level chart then you will get
multiple ConfigMaps with name clash.

## Usage

Add `sci-version-info` as a dependency to your chart's `Chart.yaml` file:

```yaml
dependencies:
  - name: sci-version-info
    repository: oci://keppel.eu-de-1.cloud.sap/ccloud-helm
    version: # use sci-version-info's current version from Chart.yaml
```

Run `helm dep up` to regenerate your chart's `Chart.lock` file.

The `image` value is supplied at deploy time by the deploy pipeline via `--set`, the same way the
app image tag is set, so you do not hand-edit it into `values.yaml`:

```sh
helm upgrade ... --set sci-version-info.image="${APP_IMAGE}"
```

The following fields can appear within the `sci-version-info` section of your chart's `values.yaml` file:

| Parameter | Required? | Description |
| --------- | --------- | ----------- |
| `image` | **yes** | The release's full application image reference -- a whole path like `keppel.eu-de-1.cloud.sap/ccloud/example:1.2.3` or `keppel.eu-de-1.cloud.sap/ccloud/example@sha256:...`, not a tag the chart composes. `sci-label-injector` reads the sci labels off this image's OCI config. Supplied by the deploy pipeline via `--set`. |
| `info` | no | An optional map of extra per-release data. Each entry becomes a data key on both rendered ConfigMaps. A value may itself be a JSON string, e.g. an `images` key holding all release images: `images: '{"api":"registry/example-api:1.2.3","worker":"registry/example-worker:1.2.3"}'`. The injector ignores these keys today; they are for consumers taught to read them. |

> **Passing JSON through `--set`:** `helm --set` splits values on commas, so a JSON string like
> `{"api":"...","worker":"..."}` is mangled. Use `--set-string` with the commas escaped (`\,`), a
> values file, or `--set-file` to pass the raw JSON intact.

The chart renders two ConfigMaps: `sci-version-of-<release>` (a regular release member) and
`early-sci-version-of-<release>` (a `pre-install,pre-upgrade` hook twin that covers the window before
the regular ConfigMap is live). Both carry the same `data.image` plus any `info` keys. The injector prefers
`sci-version-of-<release>` and consults the `early-` twin only when the regular one is absent.
