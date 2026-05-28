## ADDED Requirements

### Requirement: Webhook-injector sidecar configured for caBundle-rotation mode

The kustomize tree SHALL configure the webhook-injector sidecar container to run in caBundle-rotation mode by setting the appropriate mode signal (env var `WEBHOOK_INJECTOR_MODE=ca-rotation` or equivalent flag exposed by the SAP-internal binary). The exact behavior of the binary in this mode (filtering rules, update strategy, reconcile loop semantics) is the responsibility of the binary itself and is out of scope for this kustomize-tree spec; this requirement governs only that the kustomize tree signals the mode correctly.

#### Scenario: Mode signal set on the sidecar container

- **WHEN** examining the rendered Deployment from `kustomize build host/base/`
- **THEN** the webhook-injector initContainer SHALL have an env var `WEBHOOK_INJECTOR_MODE` with value `ca-rotation` (or an equivalent mode flag/env per the SAP-internal binary's API as agreed in the coordinated webhook-injector binary issue)

#### Scenario: --webhook-config-name argument names the workerless WebhookConfiguration

- **WHEN** examining the sidecar's `--webhook-config-name` argument in the rendered Deployment
- **THEN** the value SHALL be the name of a workerless `ValidatingWebhookConfiguration` resource (typically `validating-webhook-configuration` matching upstream's webhook configuration name)
- **AND** the kustomize tree SHALL NOT deploy a host-cluster ConfigMap of the same name (since in this mode the binary references the workerless resource, not a local ConfigMap)

---

### Requirement: Webhook-injector ServiceAccount granted narrowed RBAC for caBundle rotation

The kustomize tree SHALL configure a ServiceAccount on the host cluster (used by the webhook-injector sidecar to authenticate to the workerless cluster via remote-kubeconfig) that, on the workerless cluster, is granted Kubernetes RBAC limited to `get` and `patch` verbs on `validatingwebhookconfigurations.admissionregistration.k8s.io` (and `mutatingwebhookconfigurations.admissionregistration.k8s.io` if applicable). The exact filtering and update behavior of the binary (which WebhookConfigurations it selects, which fields it updates, retry semantics) is the responsibility of the SAP-internal `webhook-injector` binary and is out of scope for this kustomize-tree spec.

#### Scenario: ClusterRole on workerless has narrowed verbs

- **WHEN** examining the workerless-cluster ClusterRole bound (via ClusterRoleBinding) to the ServiceAccount the sidecar authenticates as via remote-kubeconfig
- **THEN** the granted verbs SHALL be limited to `get` and `patch` (and optionally `list`, `watch` if the binary requires them)
- **AND** the granted resources SHALL be limited to `validatingwebhookconfigurations.admissionregistration.k8s.io` (and optionally `mutatingwebhookconfigurations.admissionregistration.k8s.io`)
- **AND** the granted verbs SHALL NOT include `create`, `delete`, or `*` (broad wildcards)

#### Scenario: ClusterRole does not grant write access to other workerless resources

- **WHEN** examining the same ClusterRole
- **THEN** it SHALL NOT grant any verbs on resources outside `admissionregistration.k8s.io/v1`
- **AND** SHALL NOT grant access to Secrets, ConfigMaps, CRDs, or any other resource categories on the workerless cluster

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

- **WHEN** any future change adds a `patches:` block or new `resources:` entry under `remote/upstream/webhooks/` (inner or outer layer)
- **THEN** the modification SHALL NOT introduce a `caBundle` field in any webhook entry
- **AND** the modification SHALL be testable via `kustomize build remote/upstream/webhooks/ | yq '.. | select(.caBundle? // "missing")'` returning empty

---

## MODIFIED Requirements

### Requirement: Webhook-injector sidecar injected via kustomize Component

The webhook-injector sidecar SHALL be injected into the controller Deployment as a native sidecar (initContainer with `restartPolicy: Always`) using a kustomize Component. In the new design the sidecar runs in caBundle-rotation mode (governed by separate Requirements above) — its image, volume mounts, health probes, and resource limits are unchanged from the previous design, but its args reflect the new mode.

#### Scenario: Sidecar present in host base output

- **WHEN** `kustomize build host/base/` is executed (with the webhook-injector component included)
- **THEN** the Deployment output SHALL contain an initContainer named `webhook-injector`
- **THEN** the initContainer SHALL have `restartPolicy: Always` (native sidecar)

#### Scenario: Sidecar image is correct

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the webhook-injector initContainer image SHALL be `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector`

#### Scenario: Sidecar args reflect caBundle-rotation mode

- **WHEN** `kustomize build host/base/` is executed
- **THEN** the webhook-injector initContainer SHALL have an env var `WEBHOOK_INJECTOR_MODE=ca-rotation` (or equivalent mode signal per the binary's API)
- **AND** the `--webhook-config-name` argument (or its equivalent) SHALL be set to the name of the workerless `ValidatingWebhookConfiguration` to manage caBundle on (e.g., `validating-webhook-configuration` per upstream)
- **AND** the `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig` argument (or equivalent) SHALL be set to point at the remote-kubeconfig mount

#### Scenario: Sidecar args overridable per environment

- **WHEN** an overlay patches the webhook-injector initContainer args
- **THEN** the rendered output SHALL use the overridden args (e.g., a different `--webhook-config-name` value if a per-cluster overlay needs to manage a differently-named WebhookConfiguration)

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
