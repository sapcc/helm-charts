## Context

**Repository:** `sapcc/helm-charts` (public GitHub: `https://github.com/sapcc/helm-charts`).

**Companion change:** `cc/kube-secrets/openspec/changes/move-cluster-overlays-to-kube-secrets`. Apply order: that change first, this change second. See its `proposal.md` and `design.md` for the kube-secrets-side counterpart.

**Tracking issue:** [`cc/unified-kubernetes#1169`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169) (GitHub Enterprise, SAP internal).

**Branch / PR:** This change lands on the existing `poc/kustomize-metal-operator-remote` branch and combines with the open PR there (originally opened for the now-archived kustomize POC change `2026-05-13-poc-kustomize-metal-operator-remote`). The PR's scope expands to include this overlay-move work — the PR description must be updated when this change is added so reviewers understand the combined intent.

### Current state

- `system/kustomize/metal-operator-remote/` is a pure-kustomize tree introduced by the archived change [`2026-05-13-poc-kustomize-metal-operator-remote`](openspec/changes/archive/2026-05-13-poc-kustomize-metal-operator-remote). It contains:
  - `host/base/` — environment-independent host (seed) resources (stays).
  - `host/overlays/{rt-eu-de-1,a-qa-de-200}/` — per-cluster patches (**MOVES OUT** — to kube-secrets).
  - `remote/upstream/` — pre-rendered upstream ironcore-dev manifests (CRDs, RBAC, webhooks) (stays).
  - `remote/custom/base/` — custom remote base (stays).
  - `remote/custom/components/{prod,qa}/` — env-TYPE Components (stays).
  - `remote/custom/overlays/{rt-eu-de-1,a-qa-de-200}/` — per-cluster patches (**MOVES OUT**).
  - `components/webhook-injector/` — reusable Component (stays).
  - `overlays/{rt-eu-de-1,a-qa-de-200}/` — top-level "compose" overlays (**MOVES OUT**).
  - `Makefile`, `README.md`, regen scripts (stay; README gets updated to reference kube-secrets).
- Three OpenSpec capability specs are scoped to this kustomize POC:
  - `openspec/specs/kustomize-resource-splitting/spec.md` (212 lines) — defines host vs remote split, mandates per-cluster overlays at `host/overlays/<cluster-name>/` (REQUIREMENT NEEDS DELTA).
  - `openspec/specs/kustomize-sidecar-injection/spec.md` (82 lines) — webhook-injector Component contract; references cluster-specific `$patch: delete` examples (NEEDS SMALLER DELTA).
  - `openspec/specs/webhook-url-rendering/spec.md` (61 lines) — build-time `yq` transform on upstream manifests (UNCHANGED).
- The legacy Helm chart at `system/metal-operator-remote/` (`Chart.yaml version: 0.6.5`) is a parallel implementation that the kustomize tree's README claims to "replace". The Concourse pipelines in kube-secrets still deploy from this Helm chart today; the kustomize tree is not yet cut over to production. This change does NOT modify the Helm chart.

### Constraints

- **Apply order is hard:** kube-secrets must merge first. If this change merges before kube-secrets has the overlays, any local development or CI smoke tests that exercise the kustomize tree for these clusters break (no overlays anywhere).
- **Branch coupling:** the existing open PR on `poc/kustomize-metal-operator-remote` covers both the original kustomize POC (already merged via that change's apply phase) and now the overlay-move work. Reviewers reading the diff post-archive of the POC change see only the move-overlays diff. The PR description and commit history must make this clear.
- **No new specs in this change:** spec deltas only. New capability `cluster-overlay-layout` lives in kube-secrets.
- **Helm chart stays untouched:** `system/metal-operator-remote/Chart.yaml`, `templates/`, `values.yaml`, etc. are out of scope.

### Stakeholders

- **Foundation team** — owns metal-operator-remote and the kustomize POC. Reviewers of this change.
- **Reviewers** of the existing PR — already engaged with the kustomize work; this change augments their review surface.
- **Operators** — affected only at the future cutover (separate activity); this change does not change deploy behavior.

## Goals / Non-Goals

**Goals:**

1. Remove per-cluster kustomize overlays for `metal-operator-remote` (clusters `rt-eu-de-1`, `a-qa-de-200`) from this repo: 6 overlay paths total (3 per cluster).
2. Apply spec deltas to `kustomize-resource-splitting/spec.md` (MODIFIED + REMOVED requirements) and `kustomize-sidecar-injection/spec.md` (smaller MODIFIED) so the specs reflect the new placement reality.
3. Update `system/kustomize/metal-operator-remote/README.md` to reference the kube-secrets location of overlays.
4. Validate post-deletion: every overlay in kube-secrets master must still `kustomize build` successfully against this PR's helm-charts state. If anything breaks, this change is incomplete.
5. Combine with the existing open PR on `poc/kustomize-metal-operator-remote` rather than opening a new PR. PR description updated to reflect combined scope.

**Non-Goals:**

- Touching the legacy Helm chart at `system/metal-operator-remote/`.
- Adding new specs or capabilities. (The kube-secrets companion change adds the new `cluster-overlay-layout` capability spec.)
- Changing the Makefile or upstream-regeneration tooling at `system/kustomize/metal-operator-remote/Makefile` and surrounding scripts.
- Decommissioning the kustomize POC's archived change (`2026-05-13-poc-kustomize-metal-operator-remote/`) — that's archived and stays.
- CODEOWNERS modifications. (kube-secrets companion change adds CODEOWNERS rules; this side has no new paths to cover.)
- Smoke-check CI in helm-charts that would validate kube-secrets overlays at PR time. Explicitly dropped per user decision; manual `gate` step before each `apply` on the kube-secrets pipelines is the operational compensation.
- Migrating any clusters beyond `rt-eu-de-1` and `a-qa-de-200`, or any charts beyond `metal-operator-remote`. Future work.

## Decisions

### Decision: Pure deletion + spec deltas, no in-tree reference example

- **Chosen:** Delete all six per-cluster overlay paths entirely. Add a README pointer to the kube-secrets location. Do not keep an in-tree "reference example."
- **Reason:** Convention restoration is the goal — half-measures (keeping one cluster as an example) create two sources of truth and risk drift between the in-tree "example" and the real overlays in kube-secrets. README docs serve the educational role better than stale code.
- **Alternatives considered:**
  - Keep one cluster as a reference (Option B in brainstorm). Rejected for drift risk.
  - Defer deletion until full Concourse cutover (Option C in brainstorm). Rejected — adds compounding tech debt.

### Decision: Two spec deltas, one no-change

- **Chosen:** Apply MODIFIED + REMOVED requirements to `kustomize-resource-splitting/spec.md`. Apply smaller MODIFIED to `kustomize-sidecar-injection/spec.md`. Leave `webhook-url-rendering/spec.md` unchanged.
- **Reason:** `kustomize-resource-splitting/spec.md` mandates per-cluster overlay paths in helm-charts that no longer exist after this change — it MUST be updated. `kustomize-sidecar-injection/spec.md` references cluster-specific usage examples (e.g., `$patch: delete` for ENABLE_WEBHOOKS=false in rt-eu-de-1) that move out — small surgical removal of those scenarios. `webhook-url-rendering/spec.md` covers a build-time transform on upstream manifests; entirely unaffected by overlay placement.
- **Alternatives considered:**
  - Update all three specs even if `webhook-url-rendering/spec.md` doesn't strictly need it. Rejected — keeps unrelated specs unchanged for cleaner archive history.
  - Remove `kustomize-resource-splitting/spec.md` entirely and let kube-secrets's new `cluster-overlay-layout/spec.md` cover the whole concern. Rejected — host vs remote split, base/components requirements, and `MUST_BE_SET_IN_OVERLAY` requirements are still helm-charts concerns; removing the spec would leave them undocumented.

### Decision: Cross-reference, not absorption

- **Chosen:** `kustomize-resource-splitting/spec.md` after delta cross-references `cc/kube-secrets/openspec/specs/cluster-overlay-layout/spec.md` as the location of authoritative per-cluster overlay requirements. The two capabilities are linked by name, not consumed into one.
- **Reason:** Each spec stays focused on what its repo controls. helm-charts owns base/component structure; kube-secrets owns overlay placement and pipeline mechanics. Cross-references make the relationship discoverable without entangling ownership.

### Decision: Land via existing PR on poc/kustomize-metal-operator-remote

- **Chosen:** This change's commits and openspec artifacts land on the already-open PR on the `poc/kustomize-metal-operator-remote` branch. PR description updated when artifacts land to reflect combined scope ("kustomize POC + move overlays to kube-secrets").
- **Reason:** A separate PR would duplicate review surface for reviewers who already engaged with the POC work. The branch name is mildly misleading post-merge, but commit history makes the scope clear.
- **Alternatives considered:**
  - Open a new `feature/move-cluster-overlays-to-kube-secrets` PR off master. Rejected per user decision — combine with existing PR.

### Decision: Apply order is helm-charts SECOND

- **Chosen:** Merge kube-secrets PR first; merge this PR second.
- **Reason:** kube-secrets must be self-sufficient before helm-charts removes the in-tree overlays. This PR is the point of no return — the smallest reversal window is achieved by keeping it last.

## Risks / Trade-offs

- **[Premature merge — this PR merges before kube-secrets companion]** → PR description and reviewer notes explicitly require the kube-secrets companion to be merged first. Reviewers verify the kube-secrets PR's merge SHA before approving this PR. The validation gate (kustomize build against kube-secrets master) only passes after kube-secrets merges.
- **[A kube-secrets overlay still references a path being deleted]** → Validation gate (described in tasks.md): clone or worktree kube-secrets master after the kube-secrets PR has merged, run `kustomize build` against every overlay using a helm-charts worktree at this PR's HEAD. Any failure blocks merge.
- **[The combined PR scope confuses reviewers]** → PR description rewritten to clearly delineate the two distinct concerns (kustomize POC, already merged via archived change; move overlays to kube-secrets, this change). Use the OpenSpec change directories as the navigable index.
- **[Future readers of helm-charts wonder where overlays went]** → README update at `system/kustomize/metal-operator-remote/README.md` adds a "Per-cluster overlays" section pointing to kube-secrets paths. Spec delta cross-references `cluster-overlay-layout` capability.
- **[Helm chart at `system/metal-operator-remote/` becomes orphaned vs the kustomize tree]** → Out of scope for this change. The Helm chart is still in production. A separate future change archives or deprecates it after Concourse cutover.

## Migration Plan

### Test-phase coordination

This change is a pure deletion + two spec deltas. The "test phase" must support **two scenarios** depending on the kube-secrets companion's state:

**Scenario A — kube-secrets companion has merged to master.** Validation is straightforward: clone or worktree kube-secrets master and run `kustomize build` against each overlay. kustomize fetches helm-charts master via HTTPS. Note: at this point helm-charts master still has the in-tree overlays (this PR's deletion isn't merged yet) — so this validates the "production today" state, not the "after both PRs merge" state.

**Scenario B — kube-secrets companion is still on a feature branch.** This is the normal review-time scenario. The validation must work without requiring kube-secrets to have merged first. The technique:

1. Clone the kube-secrets PR branch into `/tmp/ks-pr-validation`.
2. Rewrite every `kustomization.yaml` in that throwaway clone to substitute `https://github.com/sapcc/helm-charts.git//<path>?ref=<anything>` with the local helm-charts checkout path (`/Users/D065300/IdeaProjects/sapcc/helm-charts/<path>`). The local checkout is on this PR's branch with deletions applied.
3. Run `kustomize build` against each rewritten overlay. kustomize reads bases from the local helm-charts working tree directly — no network fetch.
4. This is the **post-merge equivalent** test: the helm-charts state has deletions applied, the kube-secrets state has new overlays present, and the build either succeeds (deletion is safe) or fails (deletion is removing something a kube-secrets overlay still needs).
5. After the test, `rm -rf /tmp/ks-pr-validation`. The original kube-secrets PR branch is unaffected.

Both scenarios are documented with concrete commands in `tasks.md` Task 4 (4A and 4B variants) and `plan.md` Task 4 (Step 4A.x and 4B.x). Pre-flight Task 1.1 detects which state applies.

If a coordinated base change in helm-charts is discovered necessary during PR review:
- Push to this branch (already the working branch).
- The kube-secrets PR's overlays may reference `?ref=poc/kustomize-metal-operator-remote` with `# TEST-PHASE: tracking poc/kustomize-metal-operator-remote` comments for validation against published helm-charts branch state.
- Before kube-secrets PR merges, kube-secrets's TEST-PHASE refs MUST be reverted to `?ref=master` (enforced by kube-secrets's `cluster-overlay-layout` spec). After kube-secrets merges, the local-rewrite validation here uses the published helm-charts branch HEAD, then once helm-charts also merges, kube-secrets master references helm-charts master which now matches.

### Apply order

**Review model: coordinated review, sequential merge.** Both PRs reviewed together as a coordinated pair (same tracking issue, cross-linked descriptions). Merge events sequence T+0 (kube-secrets) then T+2 (this PR).

```
T-1   Pre-flight: kube-secrets PR is approved and ready, with `?ref=master` (no TEST-PHASE refs remaining).
       This PR is approved and ready.

T+0   kube-secrets PR merges to master.

T+1   Validation: clone kube-secrets master, run `kustomize build` against every overlay using a helm-charts
       worktree of this PR's HEAD. Each must succeed.

T+2   This PR merges to master.
       ├── system/kustomize/metal-operator-remote/host/overlays/{rt-eu-de-1,a-qa-de-200}/         deleted
       ├── system/kustomize/metal-operator-remote/remote/custom/overlays/{rt-eu-de-1,a-qa-de-200}/ deleted
       ├── system/kustomize/metal-operator-remote/overlays/{rt-eu-de-1,a-qa-de-200}/              deleted
       ├── system/kustomize/metal-operator-remote/README.md                                        updated
       ├── openspec/specs/kustomize-resource-splitting/spec.md                                     delta applied (after archive)
       └── openspec/specs/kustomize-sidecar-injection/spec.md                                      delta applied (after archive)

T+3   Archive this OpenSpec change (`openspec archive move-cluster-overlays-to-kube-secrets`).
       Spec deltas sync from the change's specs/ directory to openspec/specs/.

T+4+  (separate, future activity — NOT part of this change)
       Operators flip kube-secrets pipelines from -OFF to ON per cluster, run diff/apply, soak.
```

### Rollback

- **This PR revert (after T+2):** `git revert` the merge commit. The deleted overlay paths return to helm-charts. kube-secrets master continues operating with overlays in `values/kustomize/`. The duplicate state is benign because the kube-secrets pipelines are still in `-OFF` state. Any in-flight Concourse runs (helm-based) are unaffected.
- **kube-secrets PR revert (after T+0, before T+2):** Different change's rollback — see kube-secrets `design.md`. Does not affect this PR's mergeability if kube-secrets reverts cleanly.
- **Full rollback:** Revert this PR first (returns overlays here), then kube-secrets PR (removes overlays from kube-secrets). Order: latest-merged first.

## Open Questions

- [ ] README update at `system/kustomize/metal-operator-remote/README.md` — exact text added (pointing at kube-secrets path) and removed (in-tree overlay descriptions). Exact wording during apply phase. — owner: implementation
- [ ] Cross-check: confirm no other in-repo references to the deleted overlay paths exist (Makefile targets, scripts, documentation, archived change examples, CI files). Global grep during apply. — owner: implementation
- [ ] Cross-check: the legacy Helm chart at `system/metal-operator-remote/` does NOT reference the kustomize tree's per-cluster overlays. Verify by reading `Chart.yaml dependencies:`, `templates/`, and the chart Makefile. — owner: implementation
- [ ] Existing open PR description on `poc/kustomize-metal-operator-remote` — exact rewrite text to clarify combined scope (kustomize POC, already merged via archived change; this change adds move-overlays work). — owner: implementation
