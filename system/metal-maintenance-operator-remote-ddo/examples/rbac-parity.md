# Shoot RBAC parity

Rendered with:

```bash
helm template metal-maintenance-operator-remote system/metal-maintenance-operator-remote-ddo \
  --namespace kube-system \
  --set mode=shoot \
  --set mmo-core.rbac.namespaced=true \
  --set mmo-core.rbac.helpers.enable=true \
  --set mmo-core.serviceAccount.enable=true
```

`--namespace kube-system` mirrors the `DualDeploymentOperator.spec.shootNamespace`
used for this operand. The upstream templates use `.Release.Namespace` for the
ServiceAccount and all namespaced RBAC subjects. `values.yaml` sets
`mmo-core.fullnameOverride: metal-maintenance-operator`.

## Inventory diff

<!-- Task 6 fills this table with the legacy baseline vs render comparison. -->
<!-- Legacy baseline: system/metal-maintenance-operator-remote/... (TBD by Task 6) -->

| Resource | Names |
| --- | --- |
| ServiceAccount | _(to be filled by Task 6)_ |
| ClusterRole | _(to be filled by Task 6)_ |
| ClusterRoleBinding | _(to be filled by Task 6)_ |
| Role | _(to be filled by Task 6)_ |
| RoleBinding | _(to be filled by Task 6)_ |
| CRD | _(to be filled by Task 6)_ |

## Accepted deviations

<!-- Task 6 fills this section with any divergences from the legacy manifest that are intentional. -->

_(to be filled by Task 6)_

## Carried additions

The shoot render includes the following SAP-authored additions (not present in
the upstream subchart):

| Resource | Name | Purpose |
| --- | --- | --- |
| ServiceAccount | `metal-maintenance-token-rotate` in `kube-system` | Token rotation for cross-operator access |
| ClusterRole | `metal-maintenance-token-rotate` | Allows `tokenreviews` create |
| ClusterRoleBinding | `metal-maintenance-token-rotate` | Binds token-rotate SA |
| Role | `metal-maintenance-token-rotate` in `kube-system` | Allows `serviceaccounts/token` create for controller-manager SA |
| RoleBinding | `metal-maintenance-token-rotate` in `kube-system` | Binds token-rotate SA |
| ClusterRole | `metal-maintenance-operator-viewer` | Read access to serverwirings + consoles |
| ClusterRole | `servermaintenance-editor-role` | CRUD on servermaintenances |
| ClusterRoleBinding | `cc:oidc-ias-maintenance-viewer` | Binds IAS group to viewer role |
| ClusterRoleBinding | `cc:oidc-ias-maintenance-editor` | Binds IAS group to editor role |
