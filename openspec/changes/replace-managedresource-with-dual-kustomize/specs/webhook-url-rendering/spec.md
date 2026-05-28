## REMOVED Requirements

### Requirement: Webhook configurations transformed from service-based to URL-based

**Reason**: The URL rewrite mechanism is eliminated entirely. The new design routes webhook callbacks via an `ExternalName` Service in the workerless cluster's `system` namespace (which CNAMEs to the host cluster's actual `metal-operator-webhook-service` ClusterIP), so upstream's verbatim `clientConfig.service` form is used directly without transformation. Routing semantics are governed by the new "Webhook delivery via ExternalName routing" and "Workerless cluster receives system namespace and webhook-service ExternalName" requirements added to the `kustomize-resource-splitting` capability.

**Migration**: The `remote/upstream/webhooks/` kustomize tree references upstream's `config/webhook/` directory directly via Git URL ref (using a two-layer structure: an inner layer that pulls upstream and removes the regular ClusterIP Service via `$patch: delete`, and an outer layer that adds the `system` Namespace and the `webhook-service` ExternalName Service). The workerless `ValidatingWebhookConfiguration` carries upstream's verbatim `clientConfig.service: { name: webhook-service, namespace: system, path: /<…> }`. No `yq` transformation, no `clientConfig.url` substitution, no per-cluster URL parameterization is needed.

---

### Requirement: Pre-rendered webhook manifests checked into repository

**Reason**: With the URL rewrite eliminated and webhook content delivered directly to the workerless cluster via kustomize Git URL ref, no pre-rendered webhook YAML file is committed to the repository. The previous static file `system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml` is deleted; upstream's `config/webhook/manifests.yaml` is consumed live via `resources: https://github.com/ironcore-dev/metal-operator//config/webhook?ref=<tag>` at build time.

**Migration**: Consumers that previously referenced `manifests-url-based.yaml` (e.g., older kustomization.yaml files) are updated by this change to reference the upstream Git URL instead. Builds that need offline reproducibility can pin `?ref=<tag>` to a specific upstream commit SHA.

---

### Requirement: Regeneration Makefile target for upstream upgrades

**Reason**: The `regen-metal-operator-remote-webhooks` (and related `regen-metal-operator-remote-crds`) Makefile targets in `system/Makefile` are deleted. Upstream version bumps no longer require running a regeneration script; they propagate by changing the `?ref=<tag>` query parameter in the relevant `kustomization.yaml` files. The `wrap-managedresources.sh` helper script is also deleted.

**Migration**: Upgrading the upstream metal-operator version is performed by editing the `?ref=` value in `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`, `remote/upstream/crds-and-rbac/kustomization.yaml`, and `remote/upstream/webhooks/upstream-no-svc/kustomization.yaml`. The next `kustomize build` (or `kubectl apply -k`) automatically picks up the new upstream content. No regeneration cycle, no commit of pre-rendered output.
