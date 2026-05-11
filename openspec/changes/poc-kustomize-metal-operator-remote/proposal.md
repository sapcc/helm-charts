## Why

The current `build-metal-operator-remote` Makefile pipeline uses `helm template | sed | yq` to split, patch, and rewrite resources for the host/remote cluster deployment model. This is fragile (string-based sed transformations), hard to reason about (6+ chained steps), and duplicated per operator. The upstream `ironcore-dev/metal-operator` repo ships standard kubebuilder kustomize manifests (`config/crd`, `config/rbac`, `config/manager`, `config/webhook`) that can serve as direct bases, enabling a declarative kustomize-only approach that is simpler, more maintainable, and Flux-compatible.

## What Changes

**Resource rendering pipeline**
- From: `helm dep up` → `helm template` → `sed` (Role→ClusterRole) → `yq` (filter by kind) → static files
- To: Kustomize overlays referencing upstream `config/` directories directly via pinned git tags
- Reason: Eliminates Helm as intermediary, replaces imperative string processing with declarative patches
- Impact: Non-breaking (POC only, parallel to existing pipeline)

**Directory structure**
- From: `system/metal-operator-remote/` with Makefile-generated templates and managedresources
- To: `system/kustomize/metal-operator-remote/` with `host/` and `remote/` overlays
- Reason: Explicit separation of seed vs. shoot resources; follows existing `kustomize/ipam-capi-remote/` pattern
- Impact: Non-breaking (new directory, coexists with current chart)

**Webhook configuration**
- From: `helm template` → `yq` rewrite service→URL on every build
- To: Pre-rendered URL-based manifests checked in, regenerated only on upstream version bumps
- Reason: Pure kustomize can't compose URLs from service fields; pre-rendering matches current `webhooks.yaml` pattern
- Impact: Non-breaking (same output format)

**Sidecar injection**
- From: `sed` injects Helm template include (`{{- include "chart.webhook-injector-sidecar" . }}`)
- To: Kustomize Component with static initContainer definition, image overridden via `images:` transformer
- Reason: Eliminates Helm templating dependency; Component is reusable across operators
- Impact: Non-breaking (POC only)

## Capabilities

### New Capabilities

- `kustomize-resource-splitting`: Kustomize overlays that separate upstream metal-operator resources into host (seed) and remote (shoot) sets, with appropriate patches (Role→ClusterRole, namespace handling, Namespace resource exclusion)
- `kustomize-sidecar-injection`: Reusable kustomize Component for injecting webhook-injector as a native sidecar (initContainer) into operator Deployments
- `webhook-url-rendering`: Build-time step to transform upstream service-based webhook configurations into URL-based format, producing a static file consumable by kustomize at deploy time

### Modified Capabilities

(none — this is a parallel POC, no existing specs are modified)

## Impact

- **Code**: New directory `system/kustomize/metal-operator-remote/` with kustomize overlays and patches
- **Build**: New Makefile target for webhook URL regeneration (runs on upstream version bumps only)
- **Dependencies**: Requires kustomize v5+ for `patches[].target.kind` matching; references upstream `github.com/ironcore-dev/metal-operator` repo via git
- **Operators affected**: POC targets `metal-operator` only; pattern designed to be reusable for `boot-operator`, `argora-operator`, `ipam-capi`
- **Flux**: No blockers introduced; overlays produce valid `kustomize build` output without custom KRM plugins
