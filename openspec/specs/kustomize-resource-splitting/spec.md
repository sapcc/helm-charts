## Purpose

Defines how kustomize overlays split metal-operator-remote resources between host (seed cluster) and remote (virtual cluster API server), with per-environment overlays for parameterization. Replaces the previous Helm-based pipeline.

## Requirements


### Requirement: Host base overlay produces all seed cluster resources

The `host/base/` kustomize overlay SHALL produce all resources needed in the seed cluster: the Deployment (from upstream base + patches), plus all custom local resources (Services, Ingress, NetworkPolicy, ConfigMaps, Secrets, RBAC).

#### Scenario: Build host base overlay

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the output SHALL contain a Deployment named `controller-manager`
- **THEN** the output SHALL contain a Service named `metal-operator-webhook-service` (port 443→9443)
- **THEN** the output SHALL contain a Service for metal-registry (port 10000)
- **THEN** the output SHALL contain an Ingress for metal-registry
- **THEN** the output SHALL contain a NetworkPolicy
- **THEN** the output SHALL contain a ConfigMap named `webhook-config`
- **THEN** the output SHALL contain a ConfigMap named `remote-kubeconfig`
- **THEN** the output SHALL contain Secrets for remote-serviceaccount, macdb, and rotate-kubeconfig
- **THEN** the output SHALL contain ServiceAccount, Role, and RoleBinding for webhook-injector

#### Scenario: Namespace resource excluded from upstream

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the output SHALL NOT contain a Namespace resource (the upstream `config/manager/manager.yaml` includes one that must be excluded)

#### Scenario: Upstream version pinning

- **WHEN** the kustomization.yaml references `?ref=v0.4.0`
- **THEN** the output SHALL be reproducible across builds (same tag produces same output)

---

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

### Requirement: Remote custom RBAC uses Components for environment-variant values

The remote custom RBAC base SHALL use invalid placeholder values for fields that differ between environment types (e.g., QA vs prod OIDC group names). Kustomize Components SHALL provide the correct values per environment type, and each overlay SHALL include the appropriate component.

#### Scenario: Base uses invalid placeholders for OIDC group names

- **WHEN** examining `remote/custom/base/rbac.yaml`
- **THEN** OIDC group subject names SHALL use obviously-invalid placeholders (e.g., `MUST_BE_SET_IN_OVERLAY`) that cannot be deployed without being overridden

#### Scenario: Prod component patches correct group names

- **WHEN** a prod overlay includes `remote/custom/components/prod`
- **THEN** the rendered ClusterRoleBindings SHALL have subjects with `CC_IAS_CONTROLPLANE_PROD_ADMIN` and `CC_IAS_CONTROLPLANE_PROD_DEVELOPER`

#### Scenario: QA component patches correct group names

- **WHEN** a QA overlay includes `remote/custom/components/qa`
- **THEN** the rendered ClusterRoleBindings SHALL have subjects with `CC_IAS_CONTROLPLANE_QA_ADMIN` and `CC_IAS_CONTROLPLANE_QA_DEVELOPER`

#### Scenario: Overlay without component fails visibly

- **WHEN** an overlay does not include either the `prod` or `qa` component
- **THEN** the rendered output SHALL contain the invalid placeholder values, which will fail at apply time

### Requirement: Remote overlay produces CRDs and RBAC from upstream base

The `remote/crds-and-rbac/` kustomize overlay SHALL produce CRDs and RBAC resources by referencing the upstream `config/crd` and `config/rbac` directories at a pinned git tag.

#### Scenario: Build remote CRDs and RBAC overlay

- **WHEN** `kustomize build remote/crds-and-rbac/` is executed
- **THEN** the output SHALL contain CustomResourceDefinition resources for all metal-operator CRDs
- **THEN** the output SHALL contain ClusterRole and ClusterRoleBinding resources

#### Scenario: Role to ClusterRole conversion

- **WHEN** the upstream `config/rbac/` contains resources with `kind: Role`
- **THEN** the output SHALL convert them to `kind: ClusterRole`
- **THEN** the output SHALL convert corresponding `kind: RoleBinding` to `kind: ClusterRoleBinding`

#### Scenario: All RBAC included

- **WHEN** `kustomize build remote/crds-and-rbac/` is executed
- **THEN** the output SHALL include all RBAC resources from `config/rbac/` (leader election, metrics, manager role, per-resource roles)
- **THEN** no RBAC resources SHALL be excluded (matching current Makefile behavior)

#### Scenario: Service resources excluded

- **WHEN** `kustomize build remote/crds-and-rbac/` is executed
- **THEN** the output SHALL NOT contain any Service resources

---

### Requirement: Remote resources pre-rendered as ManagedResource wrappers

The remote resources SHALL be pre-rendered and wrapped into Gardener ManagedResource+Secret pairs, committed to git, and deployable without running kustomize at deploy time.

#### Scenario: ManagedResource wrapping format

- **WHEN** examining `remote/crds-and-rbac/managedresources.yaml`
- **THEN** each resource SHALL be wrapped in a `ManagedResource` (apiVersion: `resources.gardener.cloud/v1alpha1`) paired with a `Secret` containing the base64-encoded resource in `data.objects.yaml`

#### Scenario: Pre-rendered output deployable without kustomize

- **WHEN** the pre-rendered `managedresources.yaml` files are applied to a seed cluster
- **THEN** they SHALL be valid Kubernetes resources deployable via `kubectl apply` or Flux without running `kustomize build`

---

### Requirement: Host and remote produce equivalent output to current Helm chart

The kustomize overlays (located in `cc/kube-secrets` per the `cluster-overlay-layout` capability) SHALL produce resource sets functionally equivalent to the current `metal-operator-remote` Helm chart rendered output, when both are rendered with equivalent cluster-specific values.

#### Scenario: Host resources equivalence

- **WHEN** comparing `kustomize build` of a kube-secrets overlay (e.g., `cc/kube-secrets/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`) with `helm template metal-operator-remote <this-repo>/system/metal-operator-remote --values <kube-secrets-helm-values-for-the-same-cluster>`
- **THEN** the resource set SHALL be functionally equivalent (same kinds, names, specs) modulo expected chart-structural differences (e.g., resource ordering, generated label keys)

#### Scenario: Remote CRDs and RBAC equivalence

- **WHEN** comparing `kustomize build remote/crds-and-rbac/` output with the current `metal-operator-remote/managedresources/crds-and-rbac.yaml`
- **THEN** the resource set SHALL contain the same CRDs, ClusterRoles, ClusterRoleBindings, and ServiceAccount

---

### Requirement: Directory structure separates host and remote

The kustomize overlay directory structure SHALL explicitly separate resources by their deployment target.

#### Scenario: Host directory contains seed resources

- **WHEN** examining `system/kustomize/metal-operator-remote/host/`
- **THEN** it SHALL contain only resources deployed to the seed cluster

#### Scenario: Remote directory contains shoot resources

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/`
- **THEN** it SHALL contain only resources deployed to the shoot cluster (via ManagedResource)

---

### Requirement: No Flux blockers introduced

The kustomize overlays SHALL NOT introduce any blockers for future Flux integration.

#### Scenario: No custom KRM function plugins

- **WHEN** examining all `kustomization.yaml` files in the overlay
- **THEN** none SHALL reference custom KRM function plugins (generators or transformers requiring external binaries)

#### Scenario: Host overlays buildable by Flux

- **WHEN** Flux's kustomize-controller points at `host/overlays/<cluster>/`
- **THEN** `kustomize build` SHALL succeed without requiring external tools

#### Scenario: Remote pre-rendered files deployable by Flux

- **WHEN** Flux points at the pre-rendered `managedresources.yaml` files
- **THEN** they SHALL be deployable as plain YAML without any kustomize processing
