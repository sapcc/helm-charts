# observability-seeds

Helm chart that provisions OpenStack projects in the `monsoon3` domain for the
SCI observability stack via `OpenstackSeed` resources.

For every entry in `.Values.projects` the chart emits one `OpenstackSeed`
resource named `<project.name>-seed`. Each seed creates:

- a project in the `monsoon3` domain
- a `default` network with a `<project.name>_private` subnet
- a `default` router attached to that subnet, wired to the monsoon3 external
  network
- a role assignment granting `objectstore_admin` on the project to the
  configured technical user

## Example — external values file

Typical usage from the concourse pipeline where the technical user comes from
`secrets.git`:

```yaml
projects:
- name: sci-observability-metrics
  technicalUser: <user-from-secrets>
```

The `description` and `cidr` will resolve from `defaults`. Any additional
project can be added by appending another list entry.

## Values - explanation

### `projects`

List of projects to seed. One `OpenstackSeed` is rendered per entry.

| Field           | Required | Default (from `defaults:`) | Notes                                                                     |
|-----------------|:--------:|----------------------------|---------------------------------------------------------------------------|
| `name`          | yes      | —                          | Project name. Also used for the seed name (`<name>-seed`) and subnet name. |
| `technicalUser` | yes      | —                          | Keystone user that receives the `objectstore_admin` role on the project. Injected from `secrets.git` via the concourse pipeline. |
| `description`   | no       | `defaults.description`     | Free-form project description.                                            |
| `cidr`          | no       | `defaults.cidr`            | CIDR of the `<name>_private` subnet.                                      |


### `defaults`

Chart-wide fallbacks used by any project entry that omits the field.

| Field                  | Default                                                                        |
|------------------------|--------------------------------------------------------------------------------|
| `description`          | `SCI observability infrastructure related components. Check project name for scope.` |
| `cidr`                 | `10.180.0.0/16`                                                                |
| `routerExternalSubnet` | `FloatingIP-external-monsoon3-01-03@monsoon3-shared-infra@monsoon3`            |

### `routerExternalSubnet` (top-level, optional)

Region-wide override for the external subnet used by every router the chart
emits. Falls back to `defaults.routerExternalSubnet`.

## Cost object

Cost object metadata is **not** managed by this chart. Per SCI convention,
cost objects live in the regional `sapcc-billing` masterdata service and are
maintained manually via the Elektra `masterdata-cockpit` plugin at
`https://dashboard.<region>.cloud.sap/monsoon3/<project>/masterdata-cockpit/project`.

## CI

`ci/test-values.yaml` supplies a stub `technicalUser` so that
`helm lint --strict` and downstream chart-testing renders pass.
