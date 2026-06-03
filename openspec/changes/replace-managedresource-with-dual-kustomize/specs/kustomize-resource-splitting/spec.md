## ADDED Requirements

### Requirement: Two cluster-targeted kustomize roots produce direct-apply YAML

The `system/kustomize/metal-operator-remote/` tree SHALL provide two cluster-targeted kustomize roots, `host/` and `remote/`, each producing plain Kubernetes YAML applicable directly via `kubectl apply -k` (or a Flux `Kustomization` CR) WITHOUT any `ManagedResource` or `Secret`-wrapping transformation. Neither root SHALL produce `ManagedResource` resources or base64-encoded `Secret`-wrapped resource payloads.

#### Scenario: Build host root produces plain manifests

- **WHEN** `kustomize build system/kustomize/metal-operator-remote/host/base/` is executed
- **THEN** the output SHALL NOT contain any resource of `kind: ManagedResource`
- **AND** the output SHALL NOT contain any `Secret` whose `data.objects.yaml` field is a base64-encoded Kubernetes manifest

#### Scenario: Build remote root produces plain manifests

- **WHEN** `kustomize build system/kustomize/metal-operator-remote/remote/` is executed
- **THEN** the output SHALL NOT contain any resource of `kind: ManagedResource`
- **AND** the output SHALL contain plain `CustomResourceDefinition`, `ClusterRole`, `ClusterRoleBinding`, `ServiceAccount`, `Namespace`, `ValidatingWebhookConfiguration`, and `Service` resources directly

---

### Requirement: Apply pipeline targets kube-secrets per-cluster overlays

The deployment pipeline (Concourse short-term, Flux mid-term) SHALL apply per-cluster overlays from `cc/kube-secrets` (which reference this repository's `host/` and `remote/` kustomize trees as bases via Git URL ref), NOT this repository's `host/` or `remote/` directories directly. The pipeline SHALL invoke separate `kubectl apply -k` runs (or separate Flux `Kustomization` CRs) against the host kubeconfig and the workerless kubeconfig respectively. **Strict apply ordering is NOT required for correctness** — components are designed to retry on missing dependencies and converge to a working state regardless of apply order. The pipeline MAY enforce a remote-then-host ordering as an operational optimization to reduce alert noise during bootstrap.

#### Scenario: Pipeline applies host kustomize via kube-secrets overlay

- **WHEN** the deployment pipeline applies host-cluster resources
- **THEN** the apply target SHALL be `<kube-secrets-checkout>/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/host/` (NOT this repository's `system/kustomize/metal-operator-remote/host/` directly)
- **AND** the kubeconfig SHALL be the host cluster's kubeconfig

#### Scenario: Pipeline applies remote kustomize via kube-secrets overlay

- **WHEN** the deployment pipeline applies workerless-cluster resources
- **THEN** the apply target SHALL be `<kube-secrets-checkout>/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/remote/` (NOT this repository's `system/kustomize/metal-operator-remote/remote/` directly)
- **AND** the kubeconfig SHALL be the workerless cluster's kubeconfig

#### Scenario: helm-charts directories are bases not deploy targets

- **WHEN** examining the deployment pipeline definition
- **THEN** the apply target SHALL NOT be `system/kustomize/metal-operator-remote/host/` or `system/kustomize/metal-operator-remote/remote/` from this repository directly
- **AND** the helm-charts kustomize trees SHALL be consumed only as bases referenced by per-cluster kube-secrets overlays via Git URL ref (`https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/<base-path>?ref=master`)

---

### Requirement: System converges to working admission validation regardless of apply order

The combination of `host/` and `remote/` kustomize roots SHALL deploy a system that converges to working webhook admission validation once both have been applied (in any order, possibly concurrently). The components SHALL rely on Kubernetes-native retry behavior (controller restart on missing CRDs, sidecar reconcile loop for caBundle patching, API server webhook retry on connection failure) to handle transient inconsistencies during bootstrap. The kustomize tree SHALL NOT introduce hard dependencies that require strict apply ordering for correctness — Flux mid-term migration depends on independent reconciliation of the two `Kustomization` CRs.

#### Scenario: Controller pod recovers when remote applied after host

- **WHEN** the host kustomize root is applied first and the controller pod starts before CRDs exist on the workerless cluster
- **THEN** the controller pod SHALL crashloop or back off
- **AND** SHALL recover automatically once the remote kustomize root is applied and CRDs become available
- **AND** SHALL NOT require manual intervention or pod restart

#### Scenario: Webhook callback fails open during bootstrap window

- **WHEN** the remote kustomize root is applied first and a metal-operator CR is written to the workerless cluster before the host kustomize root is applied (i.e., before `metal-operator-webhook-service` exists on the host cluster)
- **THEN** the webhook callback SHALL fail (TCP connection failure or DNS resolution failure)
- **AND** the workerless API server SHALL reject the write per `failurePolicy: Fail`
- **AND** SHALL NOT cause permanent damage (the rejection is transient; the write succeeds on retry once the host cluster's webhook service is up)

#### Scenario: Sidecar populates caBundle once both kustomize roots are applied

- **WHEN** both kustomize roots have been applied (in any order) and the webhook-injector sidecar pod is running
- **THEN** the workerless `ValidatingWebhookConfiguration`'s `webhooks[*].clientConfig.caBundle` field SHALL eventually contain a valid CA bundle matching the TLS cert served by the host cluster's webhook service
- **AND** the time-to-converge SHALL be bounded by the binary's reconcile interval (binary-internal; out of scope for this spec)

#### Scenario: Two independent Flux Kustomization CRs reconcile without ordering dependencies

- **WHEN** Flux is configured with two `Kustomization` CRs — one targeting the kube-secrets overlay's `host/` subpath, one targeting the `remote/` subpath
- **THEN** neither CR SHALL require a `dependsOn:` reference to the other
- **AND** independent reconciliation SHALL converge to working admission validation without manual coordination

---

### Requirement: Build via kustomize Git URL ref consumes upstream live

The kustomize roots SHALL consume upstream metal-operator content (`config/manager`, `config/crd`, `config/rbac`, `config/webhook`) via kustomize Git URL references at build time, NOT via committed pre-rendered files. Upstream version bumps SHALL propagate by updating the `?ref=<tag>` query parameter; no manual `regen + commit` cycle SHALL be required for upstream version updates.

#### Scenario: Host base references upstream config/manager via Git URL

- **WHEN** examining `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`
- **THEN** the `resources:` field SHALL contain an entry of the form `https://github.com/ironcore-dev/metal-operator//config/manager?ref=<tag>`

#### Scenario: Remote upstream/crds-and-rbac references upstream via Git URL

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml`
- **THEN** the `resources:` field SHALL contain Git URL refs to upstream `config/crd` and `config/rbac` directories at a pinned tag

#### Scenario: No committed pre-rendered files in the repo

- **WHEN** examining `system/kustomize/metal-operator-remote/`
- **THEN** there SHALL be no file named `managedresources.yaml`
- **AND** there SHALL be no file named `manifests-url-based.yaml`
- **AND** there SHALL be no file named `wrap-managedresources.sh` under `scripts/`

---

### Requirement: Upstream RBAC applied verbatim

The `remote/upstream/crds-and-rbac/` kustomization SHALL apply upstream RBAC resources verbatim, preserving the upstream `kind` of each Role/RoleBinding. Roles SHALL NOT be converted to ClusterRoles, and RoleBindings SHALL NOT be converted to ClusterRoleBindings, by this kustomization tree.

#### Scenario: No Role-to-ClusterRole conversion patch

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml`
- **THEN** the `patches:` field SHALL NOT contain any patch with target `kind: Role` that converts to `kind: ClusterRole`
- **AND** the `patches:` field SHALL NOT contain any patch with target `kind: RoleBinding` that converts to `kind: ClusterRoleBinding`

#### Scenario: Upstream Role and RoleBinding preserved in build output

- **WHEN** `kustomize build remote/upstream/crds-and-rbac/` is executed and upstream `config/rbac/` contains resources of `kind: Role`
- **THEN** the build output SHALL contain those resources with their original `kind: Role`
- **AND** the build output SHALL contain corresponding `kind: RoleBinding` resources unchanged

---

### Requirement: Workerless webhooks consume only upstream's VWC manifest

The `remote/upstream/webhooks/` kustomize tree SHALL consume **only** upstream metal-operator's `config/webhook/manifests.yaml` file (the `ValidatingWebhookConfiguration`), NOT the whole `config/webhook/` directory. Upstream's `service.yaml` (a regular ClusterIP Service in the `system` namespace) SHALL NOT be applied to the workerless cluster — it is endpointless on workerless (the manager Pod runs in the host cluster) and is never used for webhook callbacks in steady state, because the webhook-injector admission webhook rewrites `clientConfig.Service` → `clientConfig.URL` synchronously at admission time. The VWC's `clientConfig.service.namespace: system` field reference is harmless: K8s does not validate Service existence at VWC apply time; the namespace string is only resolved when the apiserver actually invokes the webhook, and that path is replaced by the URL form via admission rewrite before any callback fires.

NO ExternalName Service SHALL be added (k3s/Gardener default `--enable-aggregator-routing=true` rejects ExternalName for webhook clientConfig per [k3s-io/k3s#6659](https://github.com/k3s-io/k3s/issues/6659)). NO `system` Namespace SHALL be produced — without an upstream Service applied, no resource on the workerless cluster needs that namespace to exist. The kustomize tree SHALL apply the management label patch on the VWC (defined in `kustomize-sidecar-injection`) but otherwise consume the upstream VWC verbatim.

#### Scenario: Webhooks tree references manifests.yaml directly, not the directory

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml`
- **THEN** the `resources:` field SHALL contain `https://github.com/ironcore-dev/metal-operator//config/webhook/manifests.yaml?ref=<tag>` (a file URL, not a directory URL)
- **AND** SHALL NOT contain `https://github.com/ironcore-dev/metal-operator//config/webhook?ref=<tag>` (the directory URL would pull in `service.yaml` as well)

#### Scenario: No upstream Service on workerless, no system namespace

- **WHEN** `kustomize build system/kustomize/metal-operator-remote/remote/` is executed
- **THEN** the output SHALL NOT contain a `Service` named `webhook-service` (in any namespace)
- **AND** the output SHALL NOT contain a `Namespace` named `system`
- **AND** the output SHALL NOT contain a `Service` of `spec.type: ExternalName`

#### Scenario: Webhooks subtree is minimal

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/upstream/webhooks/`
- **THEN** there SHALL be no file named `webhook-service-stub.yaml`
- **AND** there SHALL be no file named `system-namespace.yaml`
- **AND** there SHALL be no `upstream-no-svc/` subdirectory (the inner-layer Service-strip workaround)
- **AND** the directory SHALL contain only `kustomization.yaml` (the upstream URL ref, the management label patch on the VWC, and nothing else)

---

### Requirement: Webhook delivery via Service→URL rewrite at admission time

Webhook callbacks from the workerless API server to the host cluster's webhook server SHALL be routed via `clientConfig.URL = https://metal-operator-webhook-service:443/<path>` after the webhook-injector admission webhook (bootstrapped on the workerless cluster — see `kustomize-sidecar-injection` capability) intercepts every CREATE/UPDATE on labeled `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` resources and rewrites Service-form `clientConfig` to URL form. The kustomize-built manifest in `remote/` SHALL ship the VWC in upstream's verbatim Service form; the URL form is materialized in etcd at admission time, not at build time. The workerless API server's actual webhook callback SHALL connect to `metal-operator-webhook-service` in the host cluster (resolved via the workerless API server pod's `/etc/resolv.conf` search paths to the host cluster's CoreDNS).

NO `clientConfig.url` substitution SHALL be performed at build time or deploy time. NO local `webhook-config` ConfigMap SHALL be deployed on the host cluster.

#### Scenario: Workerless VWC ships in Service form (build-time)

- **WHEN** examining the `ValidatingWebhookConfiguration` produced by `kustomize build remote/`
- **THEN** every `webhooks[*].clientConfig` SHALL contain a `service: { name, namespace, path }` field
- **AND** no `webhooks[*].clientConfig` SHALL contain a `url` field
- **AND** no caBundle SHALL be present (per the existing "Kustomize tree must not emit caBundle" requirement)

#### Scenario: Steady-state stored VWC has clientConfig.URL (runtime)

- **WHEN** examining the workerless cluster's stored `ValidatingWebhookConfiguration` after the webhook-injector admission webhook has been bootstrapped and at least one Flux/Concourse apply has occurred
- **THEN** every `webhooks[*].clientConfig` SHALL contain a `url` field of the form `https://metal-operator-webhook-service:443/<path>`
- **AND** no `webhooks[*].clientConfig` SHALL contain a `service` field
- **AND** every `webhooks[*].clientConfig.caBundle` SHALL be a valid CA bundle matching the TLS cert served by the host cluster's webhook service

#### Scenario: Reapplying the manifest is idempotent (the GitOps invariant)

- **WHEN** Concourse/Flux reapplies `kustomize build remote/` (manifest is Service form, unchanged from previous apply)
- **THEN** the workerless API server's mutating-admission phase SHALL invoke `metal-operator-webhook-injector-mutator` which rewrites `clientConfig.Service` → `clientConfig.URL`
- **AND** the validating-admission phase SHALL accept the resulting URL-form (only `url` set, not `service`)
- **AND** the apply SHALL NOT error with `exactly one of url or service is required` (the K8s admissionregistration validation gate)
- **AND** the apply SHALL succeed regardless of how many times it is retried

#### Scenario: No local webhook-config ConfigMap on host

- **WHEN** examining the output of `kustomize build host/base/`
- **THEN** the output SHALL NOT contain a `ConfigMap` named `webhook-config`

---

### Requirement: Host webhook Service exposes admission webhook server port

The host cluster's `metal-operator-webhook-service` Service SHALL expose two named ports: (a) the existing `webhook` port forwarding to the manager container's webhook server, and (b) a new `admission` port forwarding to the webhook-injector sidecar's in-pod admission server. The admission port SHALL match the `--admission-external-port` flag value configured on the sidecar (default `9444`), so the workerless cluster's bootstrapped `metal-operator-webhook-injector-mutator` MWC reaches the sidecar at `https://metal-operator-webhook-service:<admission-external-port>/mutate-{mwc,vwc,crd}` resolvable from the workerless API server pod via host-cluster CoreDNS.

#### Scenario: Service exposes admission port

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the `Service` named `metal-operator-webhook-service` SHALL contain a port entry with `name: admission, port: 9444, protocol: TCP, targetPort: 9444` (in addition to the existing `name: webhook, port: 443, targetPort: 9443` entry for the manager's webhook server)

#### Scenario: Existing webhook port unchanged

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the `Service` `metal-operator-webhook-service` SHALL still contain a port entry with `port: 443, protocol: TCP, targetPort: 9443` and `name: webhook`
- **AND** the Service's `selector` SHALL still match `control-plane: controller-manager, app.kubernetes.io/name: metal-operator` (Pod hosts both manager container and webhook-injector sidecar)

---

### Requirement: Per-environment component composition delegated to kube-secrets per-cluster overlays

The `remote/` kustomize root SHALL aggregate **structural sources only** (`upstream/crds-and-rbac/`, `upstream/webhooks/`, `custom/base/`) and SHALL NOT bind to a specific environment tier (PROD vs QA). Per-environment customizations — currently the OIDC group name substitutions in `cc:oidc-ias-*` ClusterRoleBinding subjects — SHALL be exposed as kustomize Components at `custom/components/<env>/`. Selection and application of the appropriate Component SHALL happen at the kube-secrets per-cluster overlay level, based on the cluster's environment tier. This separates **structural ownership** (helm-charts) from **per-cluster environment selection** (kube-secrets), consistent with the broader Scope 2 pattern that placed per-cluster overlays in kube-secrets.

#### Scenario: Build remote/ alone leaves environment-tier placeholders unresolved

- **WHEN** `kustomize build remote/` is executed without applying any environment Component
- **THEN** the output's OIDC ClusterRoleBindings (`cc:oidc-ias-admin`, `cc:oidc-ias-viewer`, `cc:oidc-ias-metal-viewer`, `cc:oidc-ias-servermaintenance-editor`) SHALL have `subjects[0].name` equal to `MUST_BE_SET_IN_OVERLAY`
- **AND** no environment-specific value (e.g., `CC_IAS_CONTROLPLANE_PROD_*` or `CC_IAS_CONTROLPLANE_QA_*`) SHALL appear in the build output

#### Scenario: kube-secrets per-cluster overlay applies the appropriate Component

- **WHEN** a kube-secrets per-cluster overlay composes `system/kustomize/metal-operator-remote/remote/` as a base AND lists `system/kustomize/metal-operator-remote/remote/custom/components/prod/` (or `qa/`) in its `components:` field
- **THEN** the build output's OIDC ClusterRoleBindings SHALL have `subjects[0].name` matching the environment tier (`CC_IAS_CONTROLPLANE_PROD_*` for `prod`, `CC_IAS_CONTROLPLANE_QA_*` for `qa`)
- **AND** no `MUST_BE_SET_IN_OVERLAY` markers SHALL remain in the final build

#### Scenario: Components are environment-tier-scoped, not cluster-specific

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/custom/components/`
- **THEN** the directory SHALL contain entries for environment tiers only (`prod`, `qa`, …), NOT individual cluster names
- **AND** each Component SHALL patch only OIDC group name fields (no other cluster-specific values)

---

### Requirement: Host base manager and macdb absorb SAP-CC deployment-wide defaults

The `host/base/manager-patch.yaml` and `host/base/macdb-secret.yaml` SHALL contain the SAP-CC deployment-wide defaults that are uniform across all consumers. Empirical verification: across all 6 currently-deployed SAP-CC clusters (`a-qa-de-200`, `rt-eu-de-1`, `rt-eu-de-2`, `rt-eu-de-3`, `rt-na-us-2`, `rt-qa-de-1`), 7 of 8 manager `args` are byte-identical, and the macdb fleet structure (4 macPrefixes — Dell c4cbe1b1, Dell d08e79, Lenovo 0894ef, HPE 5ced8c, all Redfish/443/bmc) is identical. Per-cluster overlays in kube-secrets SHALL only need to substitute deployment-specific values (currently: registry URL host/region, region token in vault refs) via the existing `*_PLACEHOLDER` placeholder convention.

#### Scenario: Manager args contain the 7 uniform SAP-CC defaults

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the controller-manager container's `args` SHALL contain (in any order):
  - `--mac-prefixes-file=/etc/macdb/macdb.yaml`
  - `--probe-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metalprobe:v0.5.0`
  - `--probe-os-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/gardenlinux/gardenlinux:1770.0`
  - `--manager-namespace=metal-servers`
  - `--insecure=false`
  - `--enforce-first-boot`
  - `--enforce-power-off`

#### Scenario: Manager `--registry-url` uses placeholder syntax

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the controller-manager container's `args` SHALL contain `--registry-url=REGISTRY_URL_PLACEHOLDER`
- **AND** SHALL NOT contain a hardcoded URL like `http://[2a10:afc0:e013:d002::]:30010`
- **AND** per-cluster overlays in kube-secrets SHALL substitute the placeholder with `https://metal-operator-remote.<clusterType>.<region>.<tld>` (e.g., `https://metal-operator-remote.runtime.eu-de-1.cloud.sap` for runtime clusters; `https://metal-operator-remote.garden2.qa-de-1.cloud.sap` for `a-qa-de-200`)

#### Scenario: Manager args do not contain stale upstream/POC defaults

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the controller-manager container's `args` SHALL NOT contain:
  - `--probe-image=...metalprobe:latest` (was POC default; now `:v0.5.0` per fleet evidence)
  - `--probe-os-image=...gardenlinux:1443.3` (was POC default; now `gardenlinux:1770.0`)
  - `--manager-namespace=metal-operator-system` (was POC default; now `metal-servers`)
  - any `--registry-url=http://[...]` IPv6-literal value (was POC default; now `REGISTRY_URL_PLACEHOLDER`)

#### Scenario: macdb Secret contains the SAP-CC fleet vendor list

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the `Secret` named `macdb` SHALL have `stringData.macdb.yaml` containing 4 macPrefix entries with `manufacturer` values `Dell` (twice — for prefixes `c4cbe1b1` and `d08e79`), `Lenovo` (for `0894ef`), and `HPE` (for `5ced8c`)
- **AND** every macPrefix SHALL have `protocol: Redfish`, `port: 443`, `type: bmc`
- **AND** every macPrefix's `defaultCredentials` SHALL reference vault paths of the form `vault+kvv2:///secrets/REGION_PLACEHOLDER/ironic/ipmi-user/ironic/<username|password>`

#### Scenario: macdb Secret is no longer the empty placeholder

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the `Secret` named `macdb`'s `stringData.macdb.yaml` SHALL NOT be the empty value `{}`

---

## MODIFIED Requirements

### Requirement: Host base overlay produces all seed cluster resources

The `host/base/` kustomize overlay SHALL produce all resources needed in the seed cluster (= host cluster, = workload cluster): the Deployment (from upstream `config/manager` base + the consolidated `manager-patch.yaml`), plus all custom local resources (Services, Ingress, NetworkPolicy, ConfigMaps, Secrets, RBAC). The local `webhook-config` ConfigMap is no longer produced (the webhook content is delivered directly to the workerless cluster via the `remote/` kustomize root with ExternalName routing).

#### Scenario: Build host base overlay

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the output SHALL contain a Deployment named `controller-manager`
- **THEN** the output SHALL contain a Service named `metal-operator-webhook-service` (port 443→9443)
- **THEN** the output SHALL contain a Service for metal-registry (port 10000)
- **THEN** the output SHALL contain an Ingress for metal-registry
- **THEN** the output SHALL contain a NetworkPolicy
- **THEN** the output SHALL contain a ConfigMap named `remote-kubeconfig`
- **THEN** the output SHALL contain Secrets for remote-serviceaccount, macdb, and rotate-kubeconfig
- **THEN** the output SHALL contain ServiceAccount, Role, and RoleBinding for webhook-injector
- **THEN** the output SHALL NOT contain a ConfigMap named `webhook-config`

#### Scenario: Namespace resource excluded from upstream

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the output SHALL NOT contain a Namespace resource (the upstream `config/manager/manager.yaml` includes one that must be excluded)

#### Scenario: Upstream version pinning

- **WHEN** the kustomization.yaml references `?ref=<tag>` for any upstream Git URL
- **THEN** the output SHALL be reproducible across builds (same tag produces same output)

#### Scenario: Manager Deployment customizations consolidated

- **WHEN** examining `host/base/`
- **THEN** the SAP-specific manager `args` (`--mac-prefixes-file`, `--probe-image`, `--probe-os-image`, `--insecure`, `--registry-url`, `--manager-namespace`) SHALL be present in the rendered Deployment
- **AND** all controller-manager Deployment customizations (env vars, args, volumes, volumeMounts, ports, securityContext, network labels, serviceAccountName, hostNetwork, resources) SHALL live in a single patch file `host/base/manager-patch.yaml`

---

### Requirement: Remote overlay produces CRDs and RBAC from upstream base

The `remote/upstream/crds-and-rbac/` kustomize overlay SHALL produce CRDs and RBAC resources by referencing the upstream `config/crd` and `config/rbac` directories at a pinned git tag. The output SHALL be consumed by per-cluster overlays in `cc/kube-secrets` via Git URL ref and applied directly to the workerless cluster via `kubectl apply -k <kube-secrets-overlay>/remote/` (NOT wrapped in `ManagedResource`).

#### Scenario: Build remote CRDs and RBAC overlay

- **WHEN** `kustomize build remote/upstream/crds-and-rbac/` is executed
- **THEN** the output SHALL contain CustomResourceDefinition resources for all metal-operator CRDs
- **THEN** the output SHALL contain ClusterRole and ClusterRoleBinding resources from upstream `config/rbac/`

#### Scenario: All RBAC included

- **WHEN** `kustomize build remote/upstream/crds-and-rbac/` is executed
- **THEN** the output SHALL include all RBAC resources from upstream `config/rbac/` (leader election, metrics, manager role, per-resource roles)
- **THEN** no RBAC resources SHALL be excluded

#### Scenario: Service resources excluded

- **WHEN** `kustomize build remote/upstream/crds-and-rbac/` is executed
- **THEN** the output SHALL NOT contain any Service resources (the metrics Service from upstream is not needed on the workerless cluster)

#### Scenario: No ManagedResource wrapping

- **WHEN** `kustomize build remote/upstream/crds-and-rbac/` is executed
- **THEN** the output SHALL NOT contain any resource of `kind: ManagedResource`
- **AND** the output SHALL NOT contain any `Secret` wrapping the CRDs/RBAC as base64-encoded payloads

---

### Requirement: Host and remote produce equivalent output to current Helm chart

The kustomize overlays (located in `cc/kube-secrets` per the `cluster-overlay-layout` capability) SHALL produce resource sets functionally equivalent to the current `metal-operator-remote` Helm chart rendered output, when both are rendered with equivalent cluster-specific values, with the explicit exception that the kustomize tree produces plain Kubernetes resources directly applied to host and workerless clusters whereas the helm chart produces `ManagedResource`-wrapped resources for workerless delivery.

#### Scenario: Host resources equivalence

- **WHEN** comparing `kustomize build` of a kube-secrets overlay's `host/` subpath (e.g., `cc/kube-secrets/values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/host/`) with `helm template metal-operator-remote <this-repo>/system/metal-operator-remote --values <kube-secrets-helm-values-for-the-same-cluster>` filtered to host-cluster resources only
- **THEN** the resource set SHALL be functionally equivalent (same kinds, names, specs) modulo expected chart-structural differences (e.g., resource ordering, generated label keys, Deployment name `controller-manager` vs `metal-operator-controller-manager`)

#### Scenario: Remote resources equivalence

- **WHEN** comparing `kustomize build` of a kube-secrets overlay's `remote/` subpath with the unwrapped contents of the helm chart's `managedresources/` directory (CRDs, RBAC, Namespace) plus the helm chart's pushed `ValidatingWebhookConfiguration`
- **THEN** the resource set SHALL contain the same CRDs, ClusterRoles, ClusterRoleBindings, ServiceAccount, custom RBAC, and Namespace
- **AND** the kustomize-produced `ValidatingWebhookConfiguration` SHALL match the upstream definition with `clientConfig.service` (whereas the helm-deployed version uses `clientConfig.url`)

---

### Requirement: Directory structure separates host and remote

The kustomize overlay directory structure SHALL explicitly separate resources by their deployment target. Each top-level directory SHALL be a self-contained kustomize root consumable by exactly one `kubectl apply -k` invocation (or one Flux `Kustomization` CR).

#### Scenario: Host directory contains workload-cluster resources only

- **WHEN** examining `system/kustomize/metal-operator-remote/host/`
- **THEN** it SHALL contain only resources deployed to the host cluster (= workload cluster, where the controller pod runs)

#### Scenario: Remote directory contains workerless-cluster resources only

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/`
- **THEN** it SHALL contain only resources deployed to the workerless cluster (CRDs, RBAC, ServiceAccount, Namespace, custom RBAC, `system` Namespace, `webhook-service` ExternalName Service, `ValidatingWebhookConfiguration`)

#### Scenario: Each top-level directory is a kustomize root

- **WHEN** examining `host/base/kustomization.yaml` and `remote/kustomization.yaml`
- **THEN** each SHALL be a valid kustomize root (containing all needed `resources:`, `patches:`, etc. without depending on a sibling root)
- **AND** `kustomize build host/base/` and `kustomize build remote/` SHALL each succeed independently

---

### Requirement: No Flux blockers introduced

The kustomize overlays SHALL NOT introduce any blockers for Flux integration. Each leaf kustomize root SHALL be consumable by a Flux `Kustomization` CR without restructuring or external preprocessing.

#### Scenario: No custom KRM function plugins

- **WHEN** examining all `kustomization.yaml` files in the overlay
- **THEN** none SHALL reference custom KRM function plugins (generators or transformers requiring external binaries)

#### Scenario: Host root buildable by Flux kustomize-controller

- **WHEN** Flux's `kustomize-controller` points at `host/` (consuming a kube-secrets overlay's host subpath)
- **THEN** `kustomize build` SHALL succeed without requiring external tools

#### Scenario: Remote root buildable by Flux kustomize-controller

- **WHEN** Flux's `kustomize-controller` points at `remote/` (consuming a kube-secrets overlay's remote subpath)
- **THEN** `kustomize build` SHALL succeed without requiring external tools

---

## REMOVED Requirements

### Requirement: Remote resources pre-rendered as ManagedResource wrappers

**Reason**: This change replaces the `ManagedResource` delivery pipeline with direct `kubectl apply -k` against the workerless cluster. Pre-rendered `ManagedResource` + `Secret` files (`remote/upstream/crds-and-rbac/managedresources.yaml`, `remote/upstream/webhooks/managedresources.yaml`) and the `wrap-managedresources.sh` wrapping script are deleted; the `regen-metal-operator-remote-{crds,webhooks}` Makefile targets are removed. Workerless-cluster resources are produced as plain Kubernetes manifests by `kustomize build remote/` consuming upstream content via Git URL refs at build time.

**Migration**: Per-cluster overlays in `cc/kube-secrets` adopt the new dual-subpath layout (`host/` + `remote/` under `metal-operator-remote/`). The Concourse pipeline (and mid-term Flux Kustomization CRs) executes two independent applies — `kubectl apply -k …/remote/` against the workerless kubeconfig, and `kubectl apply -k …/host/` against the host kubeconfig. Apply ordering is NOT required for correctness; the pipeline MAY apply concurrently or in either order, with components retrying on transient inconsistencies. Remote-then-host ordering is RECOMMENDED as an operational optimization to reduce alert noise during bootstrap. The webhook-injector sidecar narrows to caBundle-rotation-only mode (governed by the `kustomize-sidecar-injection` capability spec). All resources that previously shipped via `ManagedResource` now arrive on the workerless cluster as plain `kubectl apply` output.
