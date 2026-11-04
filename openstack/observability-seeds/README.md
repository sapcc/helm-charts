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

## EC2 creds provisioning

1. Generate EC2 credentials using openstack CLI and technicalUser credentials

```
export OS_IDENTITY_API_VERSION=3
export OS_USERNAME=<technicalUser>
export OS_USER_DOMAIN_NAME=monsoon3
export OS_PASSWORD=<password>
export OS_PROJECT_NAME=sci-observability-metrics
export OS_PROJECT_DOMAIN_NAME=monsoon3
export OS_AUTH_URL=https://identity-3.<region>.cloud.sap/v3
export OS_REGION_NAME=<region>

openstack ec2 credentials create
eval "$(openstack ec2 credentials list -f json | jq -r '
  .[0] |
  "export EC2_ACCESS=\"\(.Access)\"",
  "export EC2_SECRET=\"\(.Secret)\""
')"
```

2. Create secret in vault <br>
`vault login` <br>
`vault kv put -mount=observability-secrets <region>/sci-metrics/ec2  access_key=$EC2_ACCESS secret_key=$EC2_SECRET`

3. Add metadata to secret
```
vault kv metadata put -mount=observability-secrets \
  -custom-metadata=accessed_resource=observability \
  -custom-metadata=application_criticality=HIGH \
  -custom-metadata=expiry_date=<expiry_date> \
  -custom-metadata=is_privileged=yes \
  -custom-metadata=is_single_factor=yes \
  -custom-metadata=owner=<owner>@sap.com \
  -custom-metadata=replica_dest_secret=secrets,<region>/observability/sci-metrics/ec2 \
  -custom-metadata=review_date=<current_date> \
  -custom-metadata=support_group=observability \
  -custom-metadata=type=secret \
  -custom-metadata=secret_keys=access_key,secret_key \
  <region>/sci-metrics/ec2
```

4. Replicate secret to common engine <br>
`mutavault kv replicate --mount observability-secrets <region>/sci-metrics/ec2`
