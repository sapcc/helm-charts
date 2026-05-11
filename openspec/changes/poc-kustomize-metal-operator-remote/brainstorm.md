## Design Summary

Replace the fragile Makefile pipeline (`helm template | sed | yq`) for `metal-operator-remote` with pure kustomize overlays referencing the upstream `ironcore-dev/metal-operator` GitHub repo's `config/` directory directly. The key insight is that the upstream repo ships standard kubebuilder kustomize manifests (`config/crd`, `config/rbac`, `config/manager`, `config/webhook`) which can serve as remote bases — eliminating the need for Helm rendering and post-processing entirely. The one exception is webhook URL rewriting (service→URL), which requires a one-time build step on upstream upgrades.

**Deployment model context**: The "remote cluster" is a workerless virtual cluster (API server only, no nodes). The metal-operator controller runs in the host/seed cluster and reconciles resources in the remote virtual cluster's API server. CRDs, RBAC, and webhooks are pushed to the remote API server via Gardener ManagedResources. Webhooks use URL-based clientConfig pointing back to the seed's webhook service (since the virtual cluster has no pods).

## Alternatives Considered

### Option A: Pure Kustomize with Upstream `config/` as Remote Base (Chosen)

- **Approach**: Reference `github.com/ironcore-dev/metal-operator//config/{crd,rbac,manager,webhook}` directly via kustomize remote resources pinned to git tags. Create overlays for host/remote splitting, patches for sidecar injection and Role→ClusterRole conversion. Webhook URL rewrite is pre-rendered and checked in.
- **Pros**: Aligns with existing `ipam-capi-remote` pattern; Flux-compatible without plugins; clean separation of host/remote; minimal build steps (webhook regen only on upgrades); reproducible via pinned tags
- **Cons**: Webhook URL rewrite can't be expressed as pure kustomize (requires one-time yq step); Role→ClusterRole patch needs kustomize v5+; tied to upstream `config/` stability

### Option B: Helm Template + Kustomize Post-Processing (Hybrid)

- **Approach**: Keep `helm template` as the rendering step, replace sed/yq post-processing with kustomize overlays on the pre-rendered output.
- **Pros**: Works with existing Helm chart dependency; no dependency on upstream config/ stability; familiar to team
- **Cons**: Still requires CI/Makefile step to run helm template; intermediate rendered.yaml is either stale (if checked in) or non-reproducible; Flux can't run autonomously; doesn't reduce pipeline complexity much
- **Why not chosen**: Doesn't achieve Flux autonomy and still requires Helm as an intermediary

### Option C: Helmify + Kustomize (Current Pattern Enhanced)

- **Approach**: Use kustomize→helmify pipeline (like `ipam-capi-remote` build step) to produce a Helm chart, which Flux deploys via Helm controller.
- **Pros**: Matches existing build-ipam-capi-remote pattern exactly; produces Helm chart Flux expects
- **Cons**: helmify is fragile and produces incorrect templates; still needs sed post-processing; adds complexity (kustomize→helmify→helm→deploy); doesn't actually reduce pipeline complexity
- **Why not chosen**: Adds an unnecessary intermediary (helmify) and doesn't simplify the overall flow

## Agreed Approach

**Option A: Pure Kustomize with Upstream `config/` as Remote Base.**

The upstream `ironcore-dev/metal-operator` repo has a standard kubebuilder `config/` directory that cleanly separates resources by concern (CRDs, RBAC, Manager, Webhook). This allows kustomize overlays to directly select host vs. remote resources without filtering — each overlay simply references the directories it needs. The webhook-injector sidecar is injected via a kustomize Component (reusable across operators), and the only non-kustomize step is a one-time `yq` rewrite for webhook URL conversion on upstream upgrades.

This was chosen because it achieves maximum Flux compatibility (native kustomize-controller, no plugins), eliminates Helm as a dependency for the remote deployment path, and establishes a pattern reproducible across other operators (boot, ipam, argora).

## Key Decisions

- **Pure kustomize, no Helm**: The kustomize overlays will not use Helm templating. Parameterization is handled via kustomize components and per-environment overlays.
- **Upstream `config/` as source of truth**: Reference the upstream GitHub repo's `config/` directories directly (pinned to git tags), not the published Helm chart.
- **webhook-injector as kustomize Component**: The sidecar definition lives in `components/webhook-injector/` as a reusable Component, with image tags overridden via `images:` transformer in environment overlays.
- **Pre-rendered webhook manifests (W4)**: Webhook service→URL rewrite is performed once via `yq` on upstream upgrades, committed as a static file. At deploy time, Flux sees pure kustomize.
- **Host/remote folder split**: Directory structure explicitly separates `host/` (seed cluster) and `remote/` (shoot cluster) resources for clarity.
- **Role→ClusterRole via JSON patch**: Still needed for `leader_election_role.yaml` and `leader_election_role_binding.yaml` — the Makefile does a blanket `sed 's/kind: Role/kind: ClusterRole/g'` converting ALL Roles (including leader election) to ClusterRoles for the remote cluster. This is intentional: GRM namespace workaround requires everything to be cluster-scoped in the shoot. The main `role.yaml` is already a ClusterRole upstream.
- **Include all RBAC in remote set**: The Makefile ships everything (including leader election) to the remote cluster. The controller does leader election against the remote API server. Only metrics RBAC might be excludable (needs verification during POC).

## Open Questions (Resolved)

- [x] Does `config/rbac/role.yaml` in upstream use `Role` or `ClusterRole`? **RESOLVED: Already ClusterRole.** The main `role.yaml` is `kind: ClusterRole`. Only `leader_election_role.yaml` uses `Role` — and it gets converted to `ClusterRole` for the remote cluster (blanket conversion, GRM workaround).
- [x] Are there additional resources in `config/rbac/` that belong to host-side only? **RESOLVED: No — everything goes to remote.** The Makefile does a blanket Role→ClusterRole and ships all RBAC to the remote cluster (leader election, metrics, everything). It only filters out Service and Webhook kinds. The kustomize POC should match this behavior: include all, convert Role→ClusterRole, remove nothing.

## Open Questions (Remaining)

- [ ] What kustomize version does the Flux kustomize-controller in our clusters support? Need v5+ for `target.kind` patches. — owner: verify during POC
- [ ] Can webhook-injector Component be shared across metal-operator, boot-operator, and ipam-capi? Need to verify args/config differences. — owner: POC follow-up
