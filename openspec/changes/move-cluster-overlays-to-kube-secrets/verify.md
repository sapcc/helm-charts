# Verification Report

> This is a **PRE-APPLY BASELINE** snapshot taken at the end of the planning phase.
> The actual verification — task completion, implementation signal, and final
> archive readiness — will be re-recorded after the apply phase completes.
> The verify artifact is required for the OpenSpec workflow to reach 7/7
> artifacts; this baseline documents the planning state as the starting
> condition for apply.

**Change**: `move-cluster-overlays-to-kube-secrets` (helm-charts side)
**Verified at**: 2026-05-19 (planning baseline; apply phase not yet started)
**Verifier**: planning-phase author (`@d065300` + assistant)
**Phase**: PRE-APPLY BASELINE
**Branch**: `poc/kustomize-metal-operator-remote` (combines with existing open PR)

---

## 1. Structural Validation (`openspec validate --all --json`)

- [x] All items return `"valid": true`

**Result** (4/4 valid):

```json
{
  "items": [
    { "id": "kustomize-resource-splitting",          "type": "spec",   "valid": true, "issues": [] },
    { "id": "kustomize-sidecar-injection",           "type": "spec",   "valid": true, "issues": [] },
    { "id": "move-cluster-overlays-to-kube-secrets", "type": "change", "valid": true, "issues": [] },
    { "id": "webhook-url-rendering",                 "type": "spec",   "valid": true, "issues": [] }
  ],
  "summary": {
    "totals": { "items": 4, "passed": 4, "failed": 0 },
    "byType": {
      "change": { "items": 1, "passed": 1, "failed": 0 },
      "spec":   { "items": 3, "passed": 3, "failed": 0 }
    }
  }
}
```

**Notes:**
- Three existing capability specs validate clean: `kustomize-resource-splitting`, `kustomize-sidecar-injection`, `webhook-url-rendering`.
- The change with its delta specs validates clean.
- Re-run after apply (post-archive) will validate the synced specs (the deltas applied to the live spec files).

---

## 2. Task Completion (`tasks.md` and `plan.md`)

- [ ] All `- [ ]` have been changed to `- [x]`

**Pre-apply baseline (expected: 0% complete):**

| File | Total checkboxes | Completed (`- [x]`) | Incomplete (`- [ ]`) |
|---|---|---|---|
| `tasks.md` | 44 | 0 | 44 |
| `plan.md`  | 46 | 0 | 46 |

This is the expected state pre-apply. **Re-run this section after apply phase completes.**

**Incomplete tasks** (deferred to apply):

| Task | Reason incomplete | Blocks archive? |
|---|---|---|
| All tasks 1.x – 11.x in `tasks.md` | Apply phase not yet started | Yes (must complete before archive) |
| All steps 1.x – 11.x in `plan.md` | Apply phase not yet started | Yes |

**Coordination prerequisite (NOT blocking pre-apply work):** Task 1.1 detects whether the kube-secrets companion change is in **State A** (merged to master) or **State B** (still on a feature branch). Both states are supported — Task 4 has matching validation methods (4A for State A, 4B local-path rewrite for State B). The helm-charts apply phase can proceed in either state; the only gate is that the validation in Task 4 must succeed before Task 9 (merge).

---

## 3. Delta Spec Sync State

For each capability directory under `openspec/changes/move-cluster-overlays-to-kube-secrets/specs/`, compare against the corresponding `openspec/specs/<capability>/spec.md`:

| Capability | Sync status | Notes |
|---|---|---|
| `kustomize-resource-splitting` | **Needs sync (will happen at archive)** | Delta spec at `openspec/changes/move-cluster-overlays-to-kube-secrets/specs/kustomize-resource-splitting/spec.md` contains: 1 ADDED requirement, 1 MODIFIED requirement, 2 REMOVED requirements (each with Reason + Migration). Target file at `openspec/specs/kustomize-resource-splitting/spec.md` exists (212 lines, current state). `openspec archive` will apply RENAMED → REMOVED → MODIFIED → ADDED in that order. |
| `kustomize-sidecar-injection` | **Needs sync (will happen at archive)** | Delta spec at `openspec/changes/move-cluster-overlays-to-kube-secrets/specs/kustomize-sidecar-injection/spec.md` contains: 1 MODIFIED requirement (the "Webhook-injector sidecar removable per environment" requirement is reframed from overlay-action to Component-capability semantics). Target file at `openspec/specs/kustomize-sidecar-injection/spec.md` exists (82 lines). `openspec archive` will apply the MODIFIED. |
| `webhook-url-rendering` | **N/A (no delta)** | Spec is unchanged by this change. No delta in the change directory. |

**Pre-apply expectation:** sync targets exist (these are MODIFIED specs, not new). Sync happens at archive time, post-merge.

**Post-apply expectation:** after `openspec archive move-cluster-overlays-to-kube-secrets`:
- `kustomize-resource-splitting/spec.md` reflects the new ADDED requirement, the MODIFIED requirement, and the two REMOVED requirements are gone.
- `kustomize-sidecar-injection/spec.md` reflects the MODIFIED requirement.
- `webhook-url-rendering/spec.md` unchanged.

---

## 4. Design / Specs Coherence Spot Check

Sample check that `design.md` decisions are reflected in the spec deltas:

| design.md decision | spec delta counterpart | Coherence |
|---|---|---|
| Pure deletion + spec deltas (Decision: "Pure deletion + spec deltas, no in-tree reference example") | `kustomize-resource-splitting` delta has 2 REMOVED requirements + 1 ADDED + 1 MODIFIED; `kustomize-sidecar-injection` delta has 1 MODIFIED | ✓ Aligned |
| Two spec deltas, one no-change (Decision: "Two spec deltas, one no-change") | Two delta files exist; `webhook-url-rendering` not touched | ✓ Aligned |
| Cross-reference, not absorption (Decision: "Cross-reference, not absorption") | New ADDED Requirement "Per-cluster overlay placement delegated to kube-secrets capability" explicitly cross-references `cluster-overlay-layout` in cc/kube-secrets | ✓ Aligned |
| Land via existing PR on poc/kustomize-metal-operator-remote (Decision: "Land via existing PR ...") | Captured in tasks.md Tasks 7.x and plan.md Tasks 7.x; not specced (operational, not normative) | ✓ Acceptable (operational) |
| Apply order is helm-charts SECOND (Decision: "Apply order is helm-charts SECOND") | Captured in tasks.md Task 1.1 (HARD prerequisite) and plan.md Step 1.1; design.md Migration Plan documents T+0/T+1/T+2 sequencing | ✓ Aligned |
| README update at system/kustomize/metal-operator-remote/ (Decision: "README in system/kustomize/metal-operator-remote/ updated") | Tasks 5.x in both tasks.md and plan.md | ✓ Aligned |
| Validation gate before merge (Decision: kustomize build kube-secrets overlays) | Tasks 4.x in both tasks.md and plan.md | ✓ Aligned |
| Helm chart untouched (Goal: "Non-Goal: Touching the legacy Helm chart") | Plan Task 1.7 explicitly verifies independence; no task modifies `system/metal-operator-remote/` | ✓ Aligned |

**Drift warnings:** None. All design decisions either map to a spec delta or are operational concerns tracked in tasks/plan.

---

## 5. Implementation Signal

- [ ] No unstaged files in worktree
- [ ] All relevant commits pushed

**Pre-apply state:**
- Worktree status (`git status --short`):
  ```
  ?? .opencode/
  ?? docs/
  ?? openspec/changes/move-cluster-overlays-to-kube-secrets/
  ```
- Three untracked items (expected pre-apply):
  - `.opencode/` — local tooling, gitignored or out-of-scope.
  - `docs/` — contains the DRAFT design doc (`docs/superpowers/specs/2026-05-18-move-cluster-overlays-to-kube-secrets-design.md`); will be either removed or kept as historical context per Task 11.3.
  - `openspec/changes/move-cluster-overlays-to-kube-secrets/` — the planning artifacts written by this brainstorming + OpenSpec workflow. Will be staged and committed during apply (Task 7.1 in plan.md).
- Commit range: **N/A pre-apply.** Will be populated after apply phase.

**Post-apply expectation:**
- Working tree clean (every artifact + every deletion committed).
- Commit range: 4 commits (Task 2 deletion of rt-eu-de-1, Task 3 deletion of a-qa-de-200, Task 5 README update, Task 7 commit of openspec planning artifacts) plus the merge commit and the post-archive commit.

---

## Overall Decision

- [ ] PASS — ready to proceed to docs gate and finishing-a-development-branch
- [ ] PASS WITH WARNINGS
- [ ] FAIL
- [x] **PRE-APPLY BASELINE** — planning artifacts complete and validated; apply phase not yet started

**Next step:**

Apply phase. The kube-secrets companion change may be in either state when apply begins:
- **State A**: kube-secrets companion has merged to master → use Task 4A validation (direct kustomize build against `?ref=master`).
- **State B**: kube-secrets companion is on a feature branch → use Task 4B validation (local-path rewrite of a temporary kube-secrets clone, building against the local helm-charts checkout). **This is the normal review-time scenario.**

In a fresh session, run `/opsx-apply` (or invoke `superpowers:subagent-driven-development` per the plan's REQUIRED SUB-SKILL header) in this repository working directory (`/Users/D065300/IdeaProjects/sapcc/helm-charts`). Execute tasks per `plan.md` task-by-task on the existing `poc/kustomize-metal-operator-remote` branch (per user instruction — combines with existing open PR). Plan Task 1.1 detects the kube-secrets state and selects the validation method automatically.

After apply completes (and BEFORE merge to master), re-generate this verify.md by re-running the 5 checks above:
1. `openspec validate --all --json` → all 4 items still valid.
2. `tasks.md` and `plan.md` checkboxes all `- [x]`.
3. Spec sync state still "Needs sync" (sync happens at archive, post-merge).
4. Design / specs coherence still aligned (re-spot-check after any task-driven amendments).
5. Implementation signal: deleted directories confirmed (Task 8.3); bases / components / upstream intact (Task 8.4); commits pushed; PR description updated (Task 7.4).

After the helm-charts PR merges and `openspec archive` runs (plan.md Task 10), a final post-archive verify will record:
1. Validation across the synced specs (kustomize-resource-splitting, kustomize-sidecar-injection now reflect deltas).
2. All tasks `- [x]`.
3. Spec sync state: "Synced".
4. Coherence spot-check post-sync.
5. Commit range on master: `<merge-base..post-archive-commit>`.

---

## Companion Change Reference

This change has a companion in `cc/kube-secrets`: `openspec/changes/move-cluster-overlays-to-kube-secrets/` (7/7 artifacts complete and validated). That change must be merged FIRST (apply order: kube-secrets → helm-charts).

Tracking issue: [`cc/unified-kubernetes#1169`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169).
