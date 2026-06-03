## ADDED Requirements

### Requirement: Webhook-injector sidecar configured for patch mode with admission-webhook bootstrap

The kustomize tree SHALL configure the webhook-injector sidecar container to run in **patch mode** with **admission-webhook bootstrap enabled**, as defined by the SAP-internal binary's PR-10-v2 API. The sidecar's runtime responsibilities are:

1. Bootstrapping a `MutatingWebhookConfiguration` named `metal-operator-webhook-injector-mutator` on the workerless cluster (via remote-kubeconfig) whose `objectSelector` matches the management label.
2. Periodically refreshing `caBundle` and rewriting `clientConfig.Service` → `clientConfig.URL` on labeled `ValidatingWebhookConfiguration` (and `MutatingWebhookConfiguration`) resources on the workerless cluster.
3. Serving the bootstrapped admission webhook in-pod (registered handlers `/mutate-mwc`, `/mutate-vwc`, `/mutate-crd`) so that every CREATE/UPDATE on labeled resources receives the rewrite synchronously at admission time.

The exact reconciliation semantics, mutator handler implementation, and certificate management are the responsibility of the SAP-internal binary itself and out of scope for this kustomize-tree spec; this requirement governs only that the kustomize tree configures the sidecar's flags correctly.

#### Scenario: Patch mode signaled via `--webhook-label` (no `--webhook-config-name`)

- **WHEN** examining the rendered Deployment from `kustomize build host/base/`
- **THEN** the webhook-injector initContainer's `args` SHALL contain a `--webhook-label=<key>=<value>` entry (label selector identifying which webhook configurations on the target cluster to patch)
- **AND** the `args` SHALL NOT contain `--webhook-config-name` (that flag selects ConfigMap mode, which is mutually exclusive with patch mode)

#### Scenario: `--cert-sans` provided explicitly (required in patch mode)

- **WHEN** examining the sidecar's `args`
- **THEN** the `args` SHALL contain `--cert-sans=metal-operator-webhook-service` (the host-side Service short name; resolves identically across all clusters via host-cluster CoreDNS from the workerless API server pod's `/etc/resolv.conf` search paths)
- **AND** the `args` SHALL NOT contain workerless-side service DNS variants (`webhook-service.system.svc`, `webhook-service.system.svc.cluster.local`) — the admission webhook rewrites the workerless VWC's `clientConfig.Service` to URL form pointing at the host-side Service before any callback is attempted

#### Scenario: `--external-host` and `--external-port` configured (required in patch mode)

- **WHEN** examining the sidecar's `args`
- **THEN** the `args` SHALL contain `--external-host=metal-operator-webhook-service` (target host for the Service→URL rewrite)
- **AND** the `args` SHALL contain `--external-port=443` (target port matching the host-side webhook-service port, which forwards to the manager container's `containerPort: 9443`)

#### Scenario: Admission-webhook bootstrap configured

- **WHEN** examining the sidecar's `args`
- **THEN** the `args` SHALL contain `--admission-webhook-name=metal-operator-webhook-injector-mutator` (per-consumer prefixed name to avoid collision with other webhook-injector consumers on the same workerless cluster in the future)
- **AND** the `args` SHALL contain `--admission-external-port=9444` (port the workerless API server uses to reach the in-pod admission server, matching the `admission` port on the host-side Service)
- **AND** the `args` MAY contain `--admission-webhook-port=9444` explicitly, or rely on the binary's default of `9444`

#### Scenario: Sidecar args match production cluster customizations

- **WHEN** examining the sidecar's `args`
- **THEN** the `args` SHALL contain `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig`
- **AND** SHALL contain `--leader-election-id=metal-operator-remote-webhook-injector-leader` (matches helm chart's hardcoded value verified on rt-eu-de-1)
- **AND** SHALL contain `--cert-secret-name=metal-operator-remote-cert-secret-name` (matches helm chart's hardcoded value verified on rt-eu-de-1)

#### Scenario: Sidecar exposes admission containerPort

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the webhook-injector initContainer SHALL declare `containerPort: 9444` with `name: admission` (in addition to the existing `metrics: 8082` and `health: 8083` ports), matching the in-pod admission server bind port

---

### Requirement: Webhook-injector admission webhook bootstrapped on workerless cluster

In steady state, the workerless cluster SHALL contain a `MutatingWebhookConfiguration` named `metal-operator-webhook-injector-mutator`, bootstrapped by the webhook-injector sidecar (via remote-kubeconfig). This MWC's role is to make the periodic Service→URL rewrite **idempotent across re-applies** — without it, every Concourse / Flux reapply of the workerless VWC manifest would re-introduce the Service field (the `kubectl apply` 3-way merge re-injects fields from the unchanged source manifest), causing the apiserver's admission validation to reject the resulting state with `exactly one of url or service is required`. With the admission webhook present, the mutating phase rewrites Service→URL **before** validation, so the validating phase only ever sees URL form and the apply succeeds idempotently.

The MWC SHALL be created by the sidecar; the kustomize tree SHALL NOT pre-render this MWC (it is bootstrapped at runtime). The kustomize tree's responsibility is limited to providing the sidecar with the flags needed to bootstrap correctly.

#### Scenario: Admission MWC exists on workerless after first reconcile

- **WHEN** the host kustomize root has been applied (webhook-injector sidecar running) AND the sidecar has completed at least one successful reconcile
- **THEN** the workerless cluster SHALL contain a `MutatingWebhookConfiguration` named `metal-operator-webhook-injector-mutator`
- **AND** the MWC SHALL have three webhook entries pointing at `/mutate-mwc`, `/mutate-vwc`, `/mutate-crd` paths
- **AND** every entry's `clientConfig.url` SHALL be of the form `https://metal-operator-webhook-service:9444/mutate-{mwc,vwc,crd}`
- **AND** every entry's `clientConfig.caBundle` SHALL be a valid CA bundle matching the sidecar's TLS cert
- **AND** the MWC's `webhooks[*].objectSelector` SHALL match the management label (`webhook-injector.cloud.sap/managed=true`)

#### Scenario: Admission MWC name follows per-consumer naming

- **WHEN** examining the bootstrapped MWC on the workerless cluster
- **THEN** the MWC name SHALL be `metal-operator-webhook-injector-mutator` (NOT the binary's default `webhook-injector-mutator`)
- **AND** the prefix `metal-operator-` SHALL distinguish this MWC from any future webhook-injector consumer on the same workerless cluster

#### Scenario: Admission MWC is empty-labeled (self-bootstrap exclusion)

- **WHEN** examining the bootstrapped MWC on the workerless cluster
- **THEN** `metadata.labels` SHALL be empty (or absent)
- **AND** SHALL NOT contain `webhook-injector.cloud.sap/managed: "true"` — the sidecar handler short-circuits any MWC whose name equals `--admission-webhook-name`, but the empty-labels invariant is belt-and-suspenders

---

### Requirement: Workerless ValidatingWebhookConfiguration labeled for webhook-injector patch-mode selection

The `remote/upstream/metal-operator-webhooks/` kustomize tree SHALL apply a label to the workerless `ValidatingWebhookConfiguration` (and any `MutatingWebhookConfiguration` if added in the future) so that the webhook-injector sidecar's `--webhook-label` selector finds it. The label key SHALL be `webhook-injector.cloud.sap/managed` and the value SHALL be `"true"`. This label is applied via a kustomize patch on the upstream-shipped resource — the upstream resource's `metadata.name` (currently `validating-webhook-configuration` per `config/webhook/manifests.yaml@v0.4.0`) SHALL NOT be renamed; selection is by label, not by name.

#### Scenario: Workerless VWC carries the management label

- **WHEN** `kustomize build remote/` is executed
- **THEN** every `ValidatingWebhookConfiguration` (and any `MutatingWebhookConfiguration`) in the build output SHALL have `metadata.labels."webhook-injector.cloud.sap/managed": "true"`

#### Scenario: Sidecar's `--webhook-label` and the VWC label match

- **WHEN** comparing the workerless VWC's labels (from `kustomize build remote/`) to the sidecar's `--webhook-label` arg (from `kustomize build host/base/`)
- **THEN** the label key=value pair on the VWC SHALL be exactly the key=value selector in the sidecar arg (`webhook-injector.cloud.sap/managed=true`)

#### Scenario: VWC name unchanged from upstream

- **WHEN** `kustomize build remote/` is executed
- **THEN** the `ValidatingWebhookConfiguration` SHALL have `metadata.name` equal to upstream's name (`validating-webhook-configuration` for metal-operator v0.4.0)
- **AND** SHALL NOT be renamed to `metal-operator-validating-webhook-configuration` or any other prefixed name (the kustomize tree consumes upstream verbatim except for the label addition)

---

### Requirement: Webhook-injector target-cluster RBAC pulled verbatim from upstream

The `remote/upstream/webhook-injector-rbac/` kustomize subtree SHALL pull upstream `webhook-injector`'s canonical target-cluster RBAC (the `ClusterRole` and `ClusterRoleBinding` both named `webhook-injector-target`) into the workerless `remote/` apply target. The pull SHALL consume upstream's `config/` directory verbatim via the kustomize Git-ref form, then prune everything except the target-cluster RBAC and override the binding's `subjects` list to point at our remote-kubeconfig identity.

This delivery model intentionally **lives in this repository**, NOT in `cc/kube-secrets`. The remote-kubeconfig identity that authenticates to the workerless cluster (the workerless `metal-operator-controller-manager` ServiceAccount in `kube-system`, created by upstream metal-operator and authenticated via token rotation) is stable across the fleet, so binding it to the upstream ClusterRole can be expressed as a fleet-uniform invariant in this base. `cc/kube-secrets` continues to deliver only the remote-kubeconfig token + per-cluster value substitutions; it has no parallel hand-rolled RBAC list to maintain.

The exact verb set is the responsibility of the SAP-internal `webhook-injector` binary and is consumed via the upstream ClusterRole — this kustomize-tree spec governs only the upstream pull, the prune set, and the binding subject.

#### Scenario: Webhook-injector RBAC subtree exists and references upstream

- **WHEN** examining `system/kustomize/metal-operator-remote/remote/upstream/webhook-injector-rbac/kustomization.yaml`
- **THEN** the `resources:` field SHALL contain a Git URL ref of the form `https://github.com/SAP-cloud-infrastructure/webhook-injector//config?ref=<tag-or-branch>` (the directory URL — kustomize's Git-ref form treats single-file paths as Git repository references and fails)
- **AND** the file SHALL include a `patches:` block that prunes upstream's host-side resources via `$patch: delete` (the `ServiceAccount/webhook-injector`, `Role/webhook-injector`, `RoleBinding/webhook-injector`) and upstream's stand-alone deployment artifacts (`Deployment/webhook-server`, `Service/webhook-service`, `ConfigMap/webhook-config`, `PodDisruptionBudget/webhook-server`)
- **AND** the file SHALL include a `patches:` entry that JSON-patches `ClusterRoleBinding/webhook-injector-target` to set `.subjects` to a single-element list `[{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}]` (overriding upstream's default subject)

#### Scenario: Build output contains target ClusterRole + ClusterRoleBinding only

- **WHEN** `kustomize build remote/` is executed
- **THEN** the output SHALL contain a `ClusterRole` named `webhook-injector-target` with the rules upstream defines (at minimum: `admissionregistration.k8s.io/{mutatingwebhookconfigurations,validatingwebhookconfigurations}` with verbs `get,list,watch,create,update,patch`; once webhook-injector#10 merges, also `apiextensions.k8s.io/customresourcedefinitions` verbs)
- **AND** the output SHALL contain a `ClusterRoleBinding` named `webhook-injector-target` whose `subjects[0]` is `{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}`
- **AND** the output SHALL NOT contain any `ServiceAccount`, `Role`, `RoleBinding`, `Deployment`, `Service`, `ConfigMap`, or `PodDisruptionBudget` originating from upstream `webhook-injector`'s `config/` directory (all pruned)

#### Scenario: cc/kube-secrets carries no parallel webhook-injector RBAC

- **WHEN** examining the per-cluster overlay structure in `cc/kube-secrets` for `metal-operator-remote`
- **THEN** the overlay SHALL NOT include hand-rolled `ClusterRole` / `ClusterRoleBinding` resources granting `mutatingwebhookconfigurations` / `validatingwebhookconfigurations` verbs to the remote-kubeconfig identity
- **AND** the overlay SHALL NOT consume `https://github.com/SAP-cloud-infrastructure/webhook-injector//config/rbac.yaml` itself (that responsibility is owned by `helm-charts:remote/upstream/webhook-injector-rbac/`)

---

### Requirement: Webhook-injector ServiceAccount granted target-cluster RBAC for patch mode + admission bootstrap

The kustomize tree SHALL deliver, on the workerless cluster, the Kubernetes RBAC the webhook-injector sidecar's remote-kubeconfig identity needs to (a) periodically refresh `caBundle` and rewrite `clientConfig` on labeled `ValidatingWebhookConfiguration` (and `MutatingWebhookConfiguration`) resources, AND (b) bootstrap the `metal-operator-webhook-injector-mutator` MutatingWebhookConfiguration on first reconcile.

This RBAC is delivered by the `remote/upstream/webhook-injector-rbac/` kustomize subtree (governed by the "Webhook-injector target-cluster RBAC pulled verbatim from upstream" requirement above), which pulls upstream's canonical `webhook-injector-target` ClusterRole + ClusterRoleBinding and overrides the binding's subject to point at the workerless cluster's `metal-operator-controller-manager` ServiceAccount in `kube-system` (the remote-kubeconfig identity).

The exact list of resource types and verbs the binary needs is the responsibility of the SAP-internal `webhook-injector` binary and propagates via consumption of upstream's ClusterRole; this kustomize-tree spec governs only the verb floor (what the sidecar MUST be able to do for patch mode + bootstrap to function).

#### Scenario: webhook-injector-target ClusterRole grants MWC verbs including create

- **WHEN** examining the workerless-cluster `ClusterRole` named `webhook-injector-target` (delivered by `remote/upstream/webhook-injector-rbac/`)
- **THEN** the granted verbs on `mutatingwebhookconfigurations.admissionregistration.k8s.io` SHALL include `create` (required for bootstrapping `metal-operator-webhook-injector-mutator`), `get`, `list`, `watch`, `update`, `patch`
- **AND** the granted verbs on `validatingwebhookconfigurations.admissionregistration.k8s.io` SHALL include `get`, `list`, `watch`, `update`, `patch` (the existing periodic-rewrite path)
- **AND** the granted verbs on `customresourcedefinitions.apiextensions.k8s.io` MAY include `get`, `list`, `watch`, `update`, `patch` (added by upstream once webhook-injector#10 merges; the binary uses these if any CRD carries the management label, harmless for our use case where no CRDs are labeled)

#### Scenario: webhook-injector-target ClusterRole does not grant write access to other workerless resources

- **WHEN** examining the same ClusterRole
- **THEN** it SHALL NOT grant any verbs on resources outside `admissionregistration.k8s.io/v1` and `apiextensions.k8s.io/v1`
- **AND** SHALL NOT grant access to Secrets, ConfigMaps, Pods, or any other resource categories on the workerless cluster

#### Scenario: webhook-injector-target ClusterRoleBinding subject is the remote-kubeconfig identity

- **WHEN** examining the workerless-cluster `ClusterRoleBinding` named `webhook-injector-target` (delivered by `remote/upstream/webhook-injector-rbac/`)
- **THEN** the binding's `subjects` field SHALL contain exactly one entry of `{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}`
- **AND** SHALL NOT contain upstream's default subject `{kind: ServiceAccount, name: webhook-injector}` (that subject was specific to upstream's stand-alone Deployment topology, not our split sidecar+remote-kubeconfig topology)

---

### Requirement: Local webhook-config ConfigMap on host is not deployed

The host cluster SHALL NOT carry a local `webhook-config` ConfigMap whose purpose was to feed the sidecar's previous push role. The webhook content lives directly on the workerless cluster as a `ValidatingWebhookConfiguration` resource managed by the `remote/` kustomize root.

#### Scenario: ConfigMap absent from host build output

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the output SHALL NOT contain a ConfigMap named `webhook-config`

#### Scenario: No webhook-config file in host/base

- **WHEN** examining `system/kustomize/metal-operator-remote/host/base/`
- **THEN** there SHALL be no file named `webhook-config.yaml`

---

### Requirement: Kustomize tree must not emit caBundle in webhook configs

The kustomize-build output of the `remote/` root SHALL NOT include any `caBundle` field in any webhook entry of any `ValidatingWebhookConfiguration` (or `MutatingWebhookConfiguration`). This invariant is critical because `kubectl apply` three-way merge (and Flux server-side apply) preserves the sidecar's runtime-patched `caBundle` only when the applied manifest never sets it; otherwise every apply would clobber the sidecar's value, creating a webhook-failure window.

#### Scenario: Build output contains no caBundle field

- **WHEN** `kustomize build system/kustomize/metal-operator-remote/remote/` is executed
- **THEN** the output SHALL NOT contain any occurrence of `caBundle:` (whether empty string, placeholder, or otherwise) in any webhook entry of any `ValidatingWebhookConfiguration` or `MutatingWebhookConfiguration`

#### Scenario: Future patches must not introduce caBundle

- **WHEN** any future change adds a `patches:` block or new `resources:` entry under `remote/upstream/metal-operator-webhooks/` (inner or outer layer)
- **THEN** the modification SHALL NOT introduce a `caBundle` field in any webhook entry
- **AND** the modification SHALL be testable via `kustomize build remote/upstream/metal-operator-webhooks/ | yq '.. | select(.caBundle? // "missing")'` returning empty

---

### Requirement: Webhook-injector Component encapsulates all sidecar-introduced resources

The kustomize Component `components/webhook-injector/` SHALL own ALL host-side resources whose existence originated with the webhook-injector sidecar feature. Specifically, the Component SHALL contain:

1. The sidecar container injection patch (existing — `sidecar.yaml`).
2. The host-side `metal-operator-webhook-injector` ServiceAccount, its host-side Role (events, secrets, leases at namespace scope), and the corresponding RoleBinding.
3. The `serviceAccountName: metal-operator-webhook-injector` override on the controller-manager Deployment (folded into the Component's existing Deployment patch, since the override only exists because the Pod hosts the sidecar — the upstream manager-only Deployment uses upstream's `controller-manager` SA).

Including the Component SHALL atomically introduce all of the above into the build output. Excluding the Component SHALL atomically remove all of the above from the build output. No host-side file outside `components/webhook-injector/` SHALL define or reference the `metal-operator-webhook-injector` SA name.

This Component is effectively mandatory for the metal-operator-remote topology (vanilla metal-operator without webhook-injector is a separate use case served by the upstream chart). Consumers excluding the Component would need to additionally provide upstream's `controller-manager` ServiceAccount via `config/rbac/service_account.yaml`; this trade-off is documented in `design.md` and is out of scope for this requirement.

#### Scenario: Component-included build contains all sidecar-coupled resources

- **WHEN** `kustomize build host/base/` is executed with the Component included via `components: [../../components/webhook-injector]`
- **THEN** the output SHALL contain a ServiceAccount named `metal-operator-webhook-injector`
- **AND** the output SHALL contain a Role named `metal-operator-webhook-injector` granting events (`create,patch,update`), secrets (`get,list,watch,create,update,patch`), and leases (`get,create,update`)
- **AND** the output SHALL contain a RoleBinding named `metal-operator-webhook-injector` binding the Role to the SA
- **AND** the controller-manager Deployment SHALL have `spec.template.spec.serviceAccountName: metal-operator-webhook-injector`
- **AND** the controller-manager Deployment SHALL contain a webhook-injector initContainer with `restartPolicy: Always`

#### Scenario: Component-excluded build atomically removes all sidecar resources

- **WHEN** a hypothetical kustomization composes `host/base/` resources but omits the `components: [../../components/webhook-injector]` line
- **THEN** the output SHALL NOT contain any ServiceAccount, Role, or RoleBinding named `metal-operator-webhook-injector`
- **AND** the controller-manager Deployment SHALL NOT contain a webhook-injector initContainer
- **AND** the controller-manager Deployment SHALL NOT carry a `spec.template.spec.serviceAccountName` override (the upstream Deployment's default `controller-manager` SA reference is preserved)

#### Scenario: No host-side file outside the Component references the SA name

- **WHEN** examining all files under `system/kustomize/metal-operator-remote/host/`
- **THEN** the string `metal-operator-webhook-injector` SHALL NOT appear in any file
- **AND** the file `host/base/webhook-injector-rbac.yaml` SHALL NOT exist (it has been moved into `components/webhook-injector/webhook-injector-rbac.yaml`)
- **AND** `host/base/manager-patch.yaml` SHALL NOT contain a `serviceAccountName:` line under `spec.template.spec` (the override has been moved into the Component's `sidecar.yaml` patch)

---

## MODIFIED Requirements

### Requirement: Webhook-injector sidecar injected via kustomize Component

The webhook-injector sidecar SHALL be injected into the controller Deployment as a native sidecar (initContainer with `restartPolicy: Always`) using a kustomize Component. In the new design the sidecar runs in PR-10-v2 patch mode with admission-webhook bootstrap (governed by separate Requirements above) — its image, volume mounts, health probes, and resource limits are unchanged from the previous design, but its args and ports reflect the new mode.

#### Scenario: Sidecar present in host base output

- **WHEN** `kustomize build host/base/` is executed (with the webhook-injector component included)
- **THEN** the Deployment output SHALL contain an initContainer named `webhook-injector`
- **THEN** the initContainer SHALL have `restartPolicy: Always` (native sidecar)

#### Scenario: Sidecar image is correct

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the webhook-injector initContainer image SHALL be `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector`

#### Scenario: Sidecar args reflect patch mode with admission bootstrap

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the webhook-injector initContainer's `args` SHALL contain `--webhook-label=webhook-injector.cloud.sap/managed=true` (label-based selection of webhook configs to patch)
- **AND** the `args` SHALL contain `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig` (workerless cluster auth)
- **AND** the `args` SHALL contain `--external-host=metal-operator-webhook-service` and `--external-port=443` (Service→URL rewrite target)
- **AND** the `args` SHALL contain `--admission-webhook-name=metal-operator-webhook-injector-mutator` and `--admission-external-port=9444` (admission-webhook bootstrap parameters)
- **AND** the `args` SHALL NOT contain `--webhook-config-name` (selects the legacy ConfigMap mode, mutually exclusive with patch mode)
- **AND** the initContainer SHALL NOT have an env var `WEBHOOK_INJECTOR_MODE` (the old caBundle-rotation mode signal is no longer used; mode is inferred from flag presence)

#### Scenario: Sidecar args overridable per environment

- **WHEN** an overlay patches the webhook-injector initContainer args
- **THEN** the rendered output SHALL use the overridden args (e.g., a different `--webhook-label` value if a per-cluster overlay needs to manage a differently-labeled set of webhook configurations)

#### Scenario: Sidecar volume mounts correct

- **WHEN** `kustomize build host/` is executed
- **THEN** the webhook-injector initContainer SHALL mount `webhook-certs` at `/tmp/webhook-certs`
- **THEN** the webhook-injector initContainer SHALL mount `remote-serviceaccount` at `/var/run/secrets/kubernetes.io/remote-serviceaccount` (readOnly)
- **THEN** the webhook-injector initContainer SHALL mount `remote-kubeconfig` at `/var/run/remote-kubeconfig` (readOnly)

#### Scenario: Sidecar has health probes

- **WHEN** `kustomize build host/` is executed
- **THEN** the webhook-injector initContainer SHALL have a livenessProbe on port 8083 path `/healthz`
- **THEN** the webhook-injector initContainer SHALL have a readinessProbe on port 8083 path `/readyz`

#### Scenario: Sidecar has resource limits

- **WHEN** `kustomize build host/` is executed
- **THEN** the webhook-injector initContainer SHALL have resource requests (cpu: 50m, memory: 64Mi) and limits (cpu: 200m, memory: 256Mi)
