## ADDED Requirements

### Requirement: Webhook-injector sidecar injected via kustomize Component

The webhook-injector sidecar SHALL be injected into the controller Deployment as a native sidecar (initContainer with `restartPolicy: Always`) using a kustomize Component.

#### Scenario: Sidecar present in host overlay output

- **WHEN** `kustomize build host/` is executed (with the webhook-injector component included)
- **THEN** the Deployment output SHALL contain an initContainer named `webhook-injector`
- **THEN** the initContainer SHALL have `restartPolicy: Always` (native sidecar)

#### Scenario: Sidecar image is correct

- **WHEN** `kustomize build host/` is executed
- **THEN** the webhook-injector initContainer image SHALL be `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector`

#### Scenario: Sidecar args match current configuration

- **WHEN** `kustomize build host/` is executed
- **THEN** the webhook-injector initContainer SHALL have args `--webhook-config-name=webhook-config` and `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig`

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

---

### Requirement: Image tag overridable via kustomize images transformer

The webhook-injector image tag SHALL be overridable without modifying the Component files directly.

#### Scenario: Override image tag in overlay

- **WHEN** an overlay includes the webhook-injector component and sets `images:` with a `newTag`
- **THEN** the rendered output SHALL use the overridden tag instead of the default

#### Scenario: Default tag used when no override

- **WHEN** no image override is specified in the consuming overlay
- **THEN** the rendered output SHALL use the tag defined in the Component's `kustomization.yaml`

---

### Requirement: Webhook-injector sidecar removable per environment

The webhook-injector sidecar is included in the base (for clusters with webhooks enabled) but SHALL be removable by per-environment overlays where webhooks are disabled.

#### Scenario: Overlay removes sidecar when webhooks disabled

- **WHEN** an environment has `ENABLE_WEBHOOKS=false`
- **THEN** the overlay SHALL remove the webhook-injector initContainer via a `$patch: delete` on the initContainers array entry
- **THEN** the rendered Deployment output SHALL have no initContainers

#### Scenario: Base includes sidecar by default

- **WHEN** `kustomize build host/base/` is executed without overlay modifications
- **THEN** the Deployment SHALL include the webhook-injector initContainer (webhooks enabled is the default)
