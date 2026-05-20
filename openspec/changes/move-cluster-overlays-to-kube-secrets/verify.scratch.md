# Implementation scratchpad — move-cluster-overlays-to-kube-secrets

> Live notes captured during plan execution. Discarded (or moved into `verify.md`) at archive time.

## Task 1.1 — kube-secrets state

- **State:** **B** (companion change is on a feature branch, not yet on master)
- **kube-secrets master HEAD:** `65db2a189c1c6a9565db0ca79175016d0ee8fe4c` (no `values/kustomize/` directory present)
- **kube-secrets PR branch:** `openspec/move-cluster-overlays-to-kube-secrets`
- **kube-secrets PR HEAD:** `a2754a0` (`docs(openspec): log CODEOWNERS inline-integration refactor as deviation #8`)
- **Validation method to use in Task 4:** **4B** (local-path rewrite)

## Task 1.2 — overlay file presence on kube-secrets PR branch

- ✓ `values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/kustomization.yaml`
- ✓ `values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/kustomization.yaml`

Each overlay also has nested `host/kustomization.yaml` and `remote/kustomization.yaml` per the kube-secrets layout.

## Task 1.3 — overlay refs

All 8 ref lines on the kube-secrets PR branch use `?ref=poc/kustomize-metal-operator-remote` with explicit `# TEST-PHASE: tracking poc/kustomize-metal-operator-remote until helm-charts merges its companion change.` comments. This is acceptable for State B per plan Step 1.3 — flagged for kube-secrets author to flip back to `?ref=master` and remove `TEST-PHASE` comments before that PR merges. **Non-blocking for the helm-charts PR** (Task 4B's local-path rewrite substitutes whatever ref is present).

Refs found (sample):
- `host/base?ref=poc/kustomize-metal-operator-remote`
- `remote/upstream/crds-and-rbac?ref=poc/kustomize-metal-operator-remote`
- `remote/upstream/webhooks?ref=poc/kustomize-metal-operator-remote`
- `remote/custom/base?ref=poc/kustomize-metal-operator-remote`
- `remote/custom/components/{prod,qa}?ref=poc/kustomize-metal-operator-remote`

The kube-secrets `values/kustomize/README.md` already documents the TEST-PHASE / pre-merge-flip discipline.

## Task 1.4 — working branch

`poc/kustomize-metal-operator-remote` ✓ (combines with existing open PR per user instruction).

## Task 1.5 — global grep

Hits classified:
- (a) targets-of-deletion: `system/kustomize/metal-operator-remote/overlays/{rt-eu-de-1,a-qa-de-200}/kustomization.yaml` — OK to delete
- (b) preserved (this change's own artifacts): `openspec/changes/move-cluster-overlays-to-kube-secrets/{plan,proposal,tasks}.md`
- (c) other consumer: `system/kustomize/metal-operator-remote/README.md` → handled in Task 5 (rewrite)

No (c) hits in Makefile / scripts / CI configs / archived examples.

## Task 1.6 — legacy Helm chart isolation

`grep -rn 'kustomize/metal-operator-remote' system/metal-operator-remote/` → 0 matches.
The Helm chart at `system/metal-operator-remote/` and the kustomize tree at `system/kustomize/metal-operator-remote/` are independent. ✓

## Pre-deletion tree snapshot

All bases / components / upstream pre-renders that MUST survive the deletion:

```
system/kustomize/metal-operator-remote/
├── components/webhook-injector/
├── host/base/
├── remote/custom/base/
├── remote/custom/components/{prod,qa}/
├── remote/upstream/crds-and-rbac/{,source/}
├── remote/upstream/webhooks/{,source/}
└── scripts/
```

Six overlay directories slated for deletion, each with exactly one `kustomization.yaml`:
- `host/overlays/{rt-eu-de-1,a-qa-de-200}/`
- `remote/custom/overlays/{rt-eu-de-1,a-qa-de-200}/`
- `overlays/{rt-eu-de-1,a-qa-de-200}/`
