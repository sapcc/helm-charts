## MODIFIED Requirements

### Requirement: Webhook-injector sidecar removable per environment

The webhook-injector sidecar is included in the base (for clusters with webhooks enabled) but the Component SHALL be designed such that consuming overlays (located in any repository — see `cluster-overlay-layout` capability in `cc/kube-secrets`) can remove it via `$patch: delete` on the initContainers array entry. The Component MUST NOT have implicit dependencies (e.g., other base resources that assume the webhook-injector is always present) that would break when the sidecar is removed.

#### Scenario: Component supports removal via $patch:delete

- **WHEN** a consuming kustomization patches the initContainer array entry with `$patch: delete`
- **THEN** the rendered Deployment output SHALL have no initContainers
- **AND** the rendered Deployment SHALL still be valid (no dangling references to the removed initContainer in volumeMounts, env, args, etc.)

#### Scenario: Base includes sidecar by default

- **WHEN** `kustomize build host/base/` is executed without overlay modifications
- **THEN** the Deployment SHALL include the webhook-injector initContainer (webhooks enabled is the default)
