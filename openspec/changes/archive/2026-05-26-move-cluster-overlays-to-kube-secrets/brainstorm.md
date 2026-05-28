## Design Summary

This change is the helm-charts half of a two-repo coordinated change. Where the companion change in [`cc/kube-secrets`](https://github.wdf.sap.corp/cc/kube-secrets) ADDS the per-cluster kustomize overlays for `metal-operator-remote` (clusters `rt-eu-de-1` and `a-qa-de-200`) under a new `values/kustomize/` tree plus the supporting Concourse plumbing, this change REMOVES the same overlays from helm-charts and applies the corresponding spec deltas to two existing capability specs (`kustomize-resource-splitting`, `kustomize-sidecar-injection`). Bases, components, and upstream pre-renders stay in helm-charts — only the per-cluster overlays move out. The change restores the established convention that all cluster-specific configuration lives in kube-secrets, which the original kustomize POC ([archived change `2026-05-13-poc-kustomize-metal-operator-remote`](openspec/changes/archive/2026-05-13-poc-kustomize-metal-operator-remote)) violated by hosting per-cluster overlays in-tree.

## Alternatives Considered

### Option A: Delete overlays + delta the existing specs (CHOSEN)

- **Approach**: Remove `system/kustomize/metal-operator-remote/host/overlays/{rt-eu-de-1,a-qa-de-200}/`, `system/kustomize/metal-operator-remote/remote/custom/overlays/{rt-eu-de-1,a-qa-de-200}/`, and `system/kustomize/metal-operator-remote/overlays/{rt-eu-de-1,a-qa-de-200}/`. Keep bases, components, upstream pre-renders, Makefile, and regen scripts. Apply MODIFIED + REMOVED requirements to `kustomize-resource-splitting/spec.md` (remove per-cluster overlay path requirements; replace with cross-reference to kube-secrets capability `cluster-overlay-layout`). Apply smaller MODIFIED to `kustomize-sidecar-injection/spec.md` (drop cluster-specific examples). Keep `webhook-url-rendering/spec.md` unchanged.
- **Pros**: Pure removal — no new code, no new build paths, low risk; preserves the bases/components architecture that enables the kustomize-based deploy from kube-secrets; specs stay accurate; the Helm chart at `system/metal-operator-remote/` remains untouched (still drives the legacy production deploy that hasn't cut over yet).
- **Cons**: Once merged, anyone iterating locally on `system/kustomize/metal-operator-remote/` no longer has reference overlays in-tree to inspect — they need to clone kube-secrets to see overlay structure. Mitigated by an updated README in `system/kustomize/metal-operator-remote/` pointing at the kube-secrets location.

### Option B: Keep one overlay in-tree as a "reference example"

- **Approach**: Move only `a-qa-de-200` overlay to kube-secrets; keep `rt-eu-de-1` overlay in helm-charts as a reference example. Document that production overlays live in kube-secrets but the in-tree example serves as documentation.
- **Pros**: Lower context-loss for newcomers reading helm-charts in isolation.
- **Cons**: Hybrid state is confusing — readers wonder whether `rt-eu-de-1`'s in-tree overlay is canonical or stale. Two sources of truth violate the convention this change is restoring. Risks the in-tree "example" diverging from the real production overlay in kube-secrets.
- **Why not chosen**: Half-measures defeat the goal. If overlays belong in kube-secrets, all overlays belong in kube-secrets. Use README docs for examples instead.

### Option C: Defer the deletion until full Concourse cutover

- **Approach**: Keep overlays in helm-charts until the kube-secrets-based pipelines have been live for both clusters and the legacy Helm pipeline has been decommissioned. Only then delete.
- **Pros**: Maximum safety — overlays stay available until clearly redundant.
- **Cons**: Weeks-to-months of dual state during which the convention is still violated; delays this change indefinitely.
- **Why not chosen**: The deletion is safe at apply time (apply order ensures kube-secrets has the overlays first). Deferral creates compounding "we'll fix it later" debt.

## Agreed Approach

**Option A.** Delete the per-cluster overlay paths; apply spec deltas. The bases, components, upstream pre-renders, and Makefile stay — they're consumed by kube-secrets overlays via kustomize Git URL refs (`https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/<base-path>?ref=master`). The legacy Helm chart at `system/metal-operator-remote/` is unaffected; it continues driving the production deploy until operators flip clusters to the kustomize pipeline (a separate follow-up activity, deliberately out of scope for this change).

The change is intentionally minimal: no new code, no new specs, no Makefile changes. Just file deletions plus two spec deltas. This minimizes review surface and keeps the helm-charts side of the coordinated change focused on a single concept: "overlays no longer live here."

## Key Decisions

- **Overlays delete entirely; bases stay**: per-cluster overlay paths under `host/overlays/`, `remote/custom/overlays/`, and `overlays/` are removed for the two clusters in scope. All other paths under `system/kustomize/metal-operator-remote/` are untouched.
- **Two spec deltas, one no-change**: `kustomize-resource-splitting/spec.md` gets MODIFIED + REMOVED requirements (remove per-cluster overlay path requirements; cross-reference kube-secrets capability). `kustomize-sidecar-injection/spec.md` gets a small MODIFIED (drop cluster-specific usage examples; keep the Component contract). `webhook-url-rendering/spec.md` is unchanged — it covers a build-time transform on upstream manifests, unaffected by overlay placement.
- **Cross-reference in spec text**: `kustomize-resource-splitting/spec.md` after delta points at `cc/kube-secrets/openspec/specs/cluster-overlay-layout/spec.md` as the location of authoritative per-cluster overlay requirements. This makes the spec self-describing for future readers.
- **README in `system/kustomize/metal-operator-remote/` updated**: add a section "Per-cluster overlays live in cc/kube-secrets" with the full path and a one-line example of what an overlay looks like there. Replaces the in-tree example readers had pre-deletion.
- **Apply order: helm-charts merges SECOND**: kube-secrets PR must be merged first. helm-charts PR is the point of no return — it removes the overlays. Smallest reversal window means it goes last.
- **Coordinated review, sequential merge**: both PRs are reviewed together as a coordinated pair (same tracking issue, cross-linked descriptions). Merge events sequence T+0 (kube-secrets) then T+2 (helm-charts) per the apply-order invariant.
- **No CODEOWNERS changes here**: this change touches existing paths only. The kube-secrets companion change adds new CODEOWNERS rules; this side has none.
- **Validation gate before merge**: every kube-secrets overlay must still build successfully against helm-charts after this PR's deletions. The validation supports two scenarios: (a) when kube-secrets companion has merged, build directly against `?ref=master`; (b) when kube-secrets companion is on a feature branch (the normal review-time case), use a local-path rewrite of a temporary kube-secrets clone to build against the helm-charts working tree (post-merge equivalent). If any build fails, the deletion is incomplete (something a kube-secrets overlay still needs is being removed). Method (b) decouples helm-charts review-time validation from the kube-secrets merge sequencing — both PRs can be reviewed in parallel.

## Open Questions

- [ ] README update wording in `system/kustomize/metal-operator-remote/README.md` — exact text added/removed to point at kube-secrets. — owner: implementation (`tasks.md`)
- [ ] Confirm no other in-repo references to the deleted overlay paths (e.g., Makefile, scripts, docs) — global grep during apply phase. — owner: implementation
- [ ] Cross-check: the legacy Helm chart at `system/metal-operator-remote/` does NOT depend on the kustomize tree's per-cluster overlays. Verify by reading `Chart.yaml dependencies:` and the Makefile. — owner: implementation
