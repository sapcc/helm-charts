## ADDED Requirements

### Requirement: Webhook configurations transformed from service-based to URL-based

The webhook URL rendering step SHALL transform upstream service-based webhook `clientConfig` into URL-based format, producing a static YAML file.

#### Scenario: Service clientConfig replaced with URL

- **WHEN** the upstream webhook manifest contains `clientConfig.service` with `name`, `namespace`, and `path`
- **THEN** the rendered output SHALL replace it with `clientConfig.url` in the format `https://metal-operator-webhook-service:443<path>`
- **THEN** the `clientConfig.service` field SHALL be removed

#### Scenario: All webhooks transformed

- **WHEN** the upstream defines multiple webhooks (ValidatingWebhookConfiguration and MutatingWebhookConfiguration)
- **THEN** every webhook entry with a `clientConfig.service` SHALL be transformed to URL-based
- **THEN** no `clientConfig.service` fields SHALL remain in the output

#### Scenario: Output matches current webhooks.yaml

- **WHEN** comparing the rendered output with the current `metal-operator-remote/webhooks.yaml`
- **THEN** the webhook configurations SHALL be functionally equivalent (same webhook names, rules, failurePolicy, URL paths)

---

### Requirement: Pre-rendered webhook manifests checked into repository

The URL-based webhook manifests SHALL be pre-rendered and committed as a static file, consumable by kustomize without external tools at deploy time.

#### Scenario: Static file exists in repository

- **WHEN** examining `remote/webhooks/manifests-url-based.yaml`
- **THEN** it SHALL contain valid Kubernetes webhook configuration resources with URL-based clientConfig

#### Scenario: Kustomize build uses static file

- **WHEN** `kustomize build remote/webhooks/` is executed
- **THEN** it SHALL succeed using only the pre-rendered static file (no external tool invocation)

---

### Requirement: Regeneration Makefile target for upstream upgrades

A Makefile target SHALL exist to regenerate the URL-based webhook manifests when the upstream version changes.

#### Scenario: Regeneration produces correct output

- **WHEN** `make regen-metal-operator-webhooks` (or equivalent) is executed
- **THEN** it SHALL fetch the upstream webhook manifests via `kustomize build` on the upstream ref
- **THEN** it SHALL apply the service→URL transformation via `yq`
- **THEN** it SHALL write the result to `remote/webhooks/manifests-url-based.yaml`

#### Scenario: Regeneration after upstream version bump

- **WHEN** the upstream git ref is updated in `remote/webhooks/upstream/kustomization.yaml`
- **THEN** running the regeneration target SHALL produce an updated `manifests-url-based.yaml` reflecting the new upstream webhooks
