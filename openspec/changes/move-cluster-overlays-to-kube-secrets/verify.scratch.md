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

## Task 2 — rt-eu-de-1 deletion (commit 432b70ae24)

- 3 directories removed via `git rm -r`
- `kustomize build host/base/` and `kustomize build remote/custom/base/` produce **byte-identical** output before vs after deletion (`diff` returns 0)
- Bases / components / upstream / scripts unchanged

## Task 3 — a-qa-de-200 deletion (commit 940c25a8af)

- 3 directories removed via `git rm -r`
- `git rm` automatically removed the now-empty `host/overlays/`, `remote/custom/overlays/`, and `overlays/` parent directories (no manual `rmdir` needed)
- `kustomize build` of bases continues to succeed with byte-identical output
- Final tree contains only `host/base`, `remote/custom/base`, `remote/custom/components/{prod,qa}`, `remote/upstream/{crds-and-rbac,webhooks}`, `components/webhook-injector`, `scripts`

## Task 4B — Cross-repo validation (kube-secrets PR branch)

**Outcome:** ✓ Both kube-secrets overlays build successfully against the local helm-charts checkout with the deletions applied (the post-merge equivalent state).

| overlay | exit | resources | kinds |
|---|---|---|---|
| `runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/` | 0 | 167 | Deployment, Service, ConfigMap, Namespace, ClusterRole, ClusterRoleBinding, ServiceAccount, Role, RoleBinding, Ingress, NetworkPolicy, Secret (76), ManagedResource (73) |
| `admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/` | 0 | 172 | (same kinds; qa-de-200 has 2 of ServiceAccount/Service/Role/RoleBinding/ConfigMap due to the qa component) |

This confirms kube-secrets overlays reference only bases/components/upstream paths that survive the deletion — no accidentally-deleted dependency.

### Plan defect found and worked around

The plan's Step 4B.2 instructs a `perl -i -pe` rewrite that produces **absolute** filesystem paths (e.g., `/Users/.../helm-charts/system/...`). kustomize rejects absolute paths in `resources:` entries with `new root '<path>' cannot be absolute`.

Workaround used: rewrote refs to **relative** paths via Python (`os.path.relpath`), using `os.path.realpath` for both endpoints to handle macOS `/tmp -> /private/tmp` symlink correctly. Built with `kustomize build --load-restrictor=LoadRestrictionsNone` to allow path traversal outside each kustomization's root.

The relative-path / realpath approach should be the corrected recipe in the kustomize-resource-splitting capability spec or in the kube-secrets `cluster-overlay-layout` README, since validators on other workstations will hit the same issue. (See Step 11 follow-up.)

### State-B-only caveat (informational)

Because this validation was against the kube-secrets PR branch (State B), the `?ref=poc/kustomize-metal-operator-remote` URLs were rewritten to local paths — they were never resolved over the network. The validation confirms **structural compatibility** of helm-charts (with deletions) against kube-secrets's expected base/component/upstream paths.

The post-merge "production today" validation (Method 4A — `?ref=master` against actual github.com URLs) cannot run until both PRs merge to their respective masters. This is the standard chicken-and-egg of two-repo coordinated changes; the State-B render here is the closest we can get pre-merge.

### Additional Method-4A-style validation (URL fetch, current remote state)

Per user request, also validated by leaving the kube-secrets PR refs as-is (`?ref=poc/kustomize-metal-operator-remote`) and letting kustomize fetch helm-charts directly from github.com:

| overlay | exit | stdout lines | wall time |
|---|---|---|---|
| `runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/` | 0 | 1609 | ~19 s |
| `admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/` | 0 | 1751 | ~18 s |

`origin/poc/kustomize-metal-operator-remote` HEAD at validation time: `26aed7061` (the **pre-deletion** state — the deletion commits `432b70ae24` and `940c25a8af` are still local).

**Crucial finding: the URL-fetch render (pre-deletion remote) and the local-rewrite render (post-deletion local) are byte-identical (`diff` returns 0 for both overlays).**

This is the strongest possible pre-merge proof of safety: the deletion removed only paths that kube-secrets does **not** reference — both renders agree because the bases / components / upstream that survive the deletion are unchanged. Equivalently, the deletion is a render-level no-op for kube-secrets consumers.

A follow-up run of the github.com URL build *after* pushing the deletion commits (Step 7.3 of plan) would resolve `?ref=poc/kustomize-metal-operator-remote` against the post-deletion HEAD and produce the same render — included as an explicit Step 11.x check below to be safe.
