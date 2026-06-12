## ADDED Requirements

### Requirement: Per-cluster overlay placement delegated to kube-secrets capability

Per-cluster overlay placement, naming, and lifecycle SHALL be governed by the `cluster-overlay-layout` capability in `cc/kube-secrets`. Implementations using `system/kustomize/metal-operator-remote/` bases MUST consume them from per-cluster overlays in `cc/kube-secrets` via kustomize Git URL refs (`https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/<base-path>?ref=master`). This repository SHALL NOT host per-cluster overlays under `system/kustomize/metal-operator-remote/{host,remote/custom}/overlays/<cluster>/` or `system/kustomize/metal-operator-remote/overlays/<cluster>/`.

#### Scenario: Per-cluster overlay creation goes to kube-secrets

- **WHEN** a per-cluster overlay needs to be created or modified for `metal-operator-remote`
- **THEN** the work SHALL happen in `cc/kube-secrets` under `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/` per the `cluster-overlay-layout` capability
- **AND** SHALL NOT be added to this repository

#### Scenario: No per-cluster overlay directories exist in this repo

- **WHEN** examining `system/kustomize/metal-operator-remote/` in this repository at any commit on or after this change
- **THEN** there SHALL be no directories matching `host/overlays/<cluster>/`, `remote/custom/overlays/<cluster>/`, or `overlays/<cluster>/`
- **AND** the bases (`host/base/`, `remote/custom/base/`, `remote/upstream/`) and components (`remote/custom/components/{prod,qa}/`, `components/webhook-injector/`) SHALL remain present and consumable via kustomize Git URL refs

---

## MODIFIED Requirements

### Requirement: Host and remote produce equivalent output to current Helm chart

The kustomize overlays (located in `cc/kube-secrets` per the `cluster-overlay-layout` capability) SHALL produce resource sets functionally equivalent to the current `metal-operator-remote` Helm chart rendered output, when both are rendered with equivalent cluster-specific values.

#### Scenario: Host resources equivalence

- **WHEN** comparing `kustomize build` of a kube-secrets overlay (e.g., `cc/kube-secrets/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`) with `helm template metal-operator-remote <this-repo>/system/metal-operator-remote --values <kube-secrets-helm-values-for-the-same-cluster>`
- **THEN** the resource set SHALL be functionally equivalent (same kinds, names, specs) modulo expected chart-structural differences (e.g., resource ordering, generated label keys)

#### Scenario: Remote CRDs and RBAC equivalence

- **WHEN** comparing `kustomize build remote/crds-and-rbac/` output with the current `metal-operator-remote/managedresources/crds-and-rbac.yaml`
- **THEN** the resource set SHALL contain the same CRDs, ClusterRoles, ClusterRoleBindings, and ServiceAccount

---

## REMOVED Requirements

### Requirement: Host overlays parameterize per-environment values

**Reason**: Per-cluster host overlays no longer live in this repository. They have moved to `cc/kube-secrets` under `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/host/`. The capability that governs them is now `cluster-overlay-layout` in kube-secrets.

**Migration**: Use the kube-secrets `cluster-overlay-layout` capability for all per-cluster overlay requirements. The kube-secrets overlays reference helm-charts `host/base/` via `https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/host/base?ref=master` and apply the same per-cluster patches the in-tree overlays previously applied (Ingress domain, remote-kubeconfig apiserver URL, macdb Secret, rotate-kubeconfig Secret, image tags, webhook-config name, webhook-injector args, volume mounts).

---

### Requirement: Top-level per-environment kustomization renders all resources

**Reason**: The top-level `overlays/<cluster-name>/kustomization.yaml` files no longer live in this repository. They have moved to `cc/kube-secrets` under `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/kustomization.yaml` (the leaf-level "compose" entry point). The capability that governs them is now `cluster-overlay-layout` in kube-secrets.

**Migration**: Build per-cluster outputs from kube-secrets: `kustomize build cc/kube-secrets/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`. The kube-secrets overlay's top-level `kustomization.yaml` composes `host/` and `remote/` subdirectories, which in turn reference helm-charts bases via Git URL refs. Single-command deploy via `kubectl apply -k` is preserved at the kube-secrets path.
