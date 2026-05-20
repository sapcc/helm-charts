## 1. Pre-flight verification

- [x] 1.1 Determine the **state of the kube-secrets companion change** and select the corresponding validation method for Task 4:
  - **State A — kube-secrets companion has MERGED to kube-secrets master.** Use validation method 4A (direct kustomize build with `?ref=master`).
  - **State B — kube-secrets companion is on a feature branch (not yet merged).** Use validation method 4B (local-path rewrite of a temporary kube-secrets clone, building against this repo's local helm-charts checkout). This allows validating the helm-charts PR before kube-secrets has merged — required for normal coordinated review where both PRs are reviewed together.
  Record the chosen state and method in `verify.scratch.md` along with the kube-secrets PR number / branch name (State B) or merge SHA (State A).
- [x] 1.2 Verify the kube-secrets companion change has the expected overlay paths regardless of state:
  ```
  # State A (master): clone or fetch master.
  # State B (branch): clone or fetch the PR's HEAD ref.
  test -f <kube-secrets-checkout>/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/kustomization.yaml && echo "rt-eu-de-1 OK"
  test -f <kube-secrets-checkout>/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/kustomization.yaml && echo "a-qa-de-200 OK"
  ```
- [x] 1.3 Verify each kube-secrets overlay's `kustomization.yaml` references helm-charts via `?ref=master` (State A) — for State B (branch), the overlays may reference `?ref=<feature-branch>` with `# TEST-PHASE: tracking <branch>` comments during development; these MUST be reverted to `?ref=master` before the kube-secrets PR merges (enforced by kube-secrets's own `cluster-overlay-layout` spec). For State B validation, the local-path rewrite in Task 4B substitutes whatever ref is present, so this is non-blocking for the helm-charts PR — but flag any non-master refs in `verify.scratch.md` for the kube-secrets author's attention.
- [x] 1.4 Confirm helm-charts working tree is on the existing `poc/kustomize-metal-operator-remote` branch (per user instruction, this change combines with the existing PR there, not a new branch). `git branch --show-current` should output `poc/kustomize-metal-operator-remote`.
- [x] 1.5 Global grep for any in-repo references to the about-to-be-deleted overlay paths (Makefile targets, scripts, docs, archived examples, CI configs):
  ```
  grep -rn -E 'host/overlays/(rt-eu-de-1|a-qa-de-200)|remote/custom/overlays/(rt-eu-de-1|a-qa-de-200)|overlays/(rt-eu-de-1|a-qa-de-200)' \
    --include='*.{yaml,yml,md,sh,rb,Makefile,mk}' \
    /Users/D065300/IdeaProjects/sapcc/helm-charts
  ```
  Expected matches: only the to-be-deleted files themselves, the openspec change directory artifacts, the archived change `2026-05-13-poc-kustomize-metal-operator-remote/` examples (must NOT be modified — archived), and possibly the Makefile if it references these paths. Document each match; categorize as (a) target-of-deletion, (b) archived (preserve), (c) needs follow-up edit.
- [x] 1.6 Confirm the legacy Helm chart at `system/metal-operator-remote/` does NOT depend on any of the to-be-deleted kustomize overlay paths. Read `system/metal-operator-remote/Chart.yaml`, `Chart.lock`, `templates/`, and the chart's Makefile (if any). Expected: zero references to `system/kustomize/metal-operator-remote/.../overlays/`.

## 2. Delete per-cluster overlays for `rt-eu-de-1`

- [x] 2.1 Delete `system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1/` (entire directory).
- [x] 2.2 Delete `system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1/` (entire directory).
- [x] 2.3 Delete `system/kustomize/metal-operator-remote/overlays/rt-eu-de-1/` (entire directory).
- [x] 2.4 Verify deletions: `find system/kustomize/metal-operator-remote -type d -name 'rt-eu-de-1'` should return no results.
- [x] 2.5 Run `kustomize build system/kustomize/metal-operator-remote/host/base/` — must succeed (bases unaffected).
- [x] 2.6 Run `kustomize build system/kustomize/metal-operator-remote/remote/custom/base/` — must succeed.

## 3. Delete per-cluster overlays for `a-qa-de-200`

- [x] 3.1 Delete `system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200/`.
- [x] 3.2 Delete `system/kustomize/metal-operator-remote/remote/custom/overlays/a-qa-de-200/`.
- [x] 3.3 Delete `system/kustomize/metal-operator-remote/overlays/a-qa-de-200/`.
- [x] 3.4 Verify deletions: `find system/kustomize/metal-operator-remote -type d -name 'a-qa-de-200'` should return no results.
- [x] 3.5 Verify NO `host/overlays/`, `remote/custom/overlays/`, or top-level `overlays/` directories with cluster-named subdirectories remain (the parent overlay directories may exist as empty if other clusters were once there — they should be empty or removed):
  ```
  find system/kustomize/metal-operator-remote -type d -name overlays -exec ls -la {} \;
  ```
  Expected: each `overlays/` dir contains only `.gitkeep` or is removed entirely. If a parent dir was empty after deletion, also delete it.

## 4. Validation against kube-secrets — pick method 4A or 4B based on Task 1.1 state

**Choose ONE method** based on the kube-secrets companion's state:

### 4A — Direct kustomize build (kube-secrets master, post-merge)

Use this method only if the kube-secrets companion PR has merged to kube-secrets master.

- [x] 4A.1 Set up a kube-secrets read-only clone or worktree at `/tmp/ks-master`:  *(N/A — Method 4A skipped per Step 1.1 detection of State B; replaced by Method 4B local-rewrite plus a Method-4A-style URL-fetch comparison documented in Task 4.6)*
  ```
  git clone https://github.wdf.sap.corp/cc/kube-secrets /tmp/ks-master
  cd /tmp/ks-master && git checkout master && git pull --ff-only
  ```
- [x] 4A.2 For each kube-secrets overlay, run `kustomize build` and pipe to a temporary file:  *(N/A — Method 4A not chosen; URL-fetch validation captured in Task 4.6 instead)*
  ```
  kustomize build /tmp/ks-master/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/ > /tmp/rt-eu-de-1.kustomize.yaml
  kustomize build /tmp/ks-master/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/ > /tmp/a-qa-de-200.kustomize.yaml
  ```
  Both MUST exit 0. kustomize fetches helm-charts master via HTTPS during build. Important: this validates against `?ref=master` of helm-charts, which at this point still has the in-tree overlays (the deletion in this PR hasn't merged yet) — so this is a "production today" validation, not a "after this PR merges" validation. To validate the post-merge state, use 4B with helm-charts checked out at this PR's branch.
- [x] 4A.3 Spot-check rendered output is non-empty and contains expected resource kinds (Deployment, Service, ConfigMap, etc.).  *(N/A — Method 4A not chosen; equivalent spot-check done in Task 4B.4)*

### 4B — Local-path rewrite validation (kube-secrets PR branch, pre-merge)

Use this method when the kube-secrets companion PR is still on a feature branch and you want to validate the helm-charts PR before kube-secrets has merged. **This is the normal review-time validation.**

The method substitutes `https://github.com/sapcc/helm-charts.git//<path>?ref=master` (and any test-phase feature-branch refs) with the local helm-charts checkout path. kustomize then reads bases directly from the local helm-charts working tree (the helm-charts PR branch with deletions applied) instead of fetching from github.com. This validates the **post-merge state** — what production looks like after both PRs merge.

- [x] 4B.1 Identify the kube-secrets PR branch and clone it locally:
  ```
  KS_PR_BRANCH=<kube-secrets-PR-branch-name>
  KS_TEST=/tmp/ks-pr-validation
  rm -rf "$KS_TEST"
  git clone --branch "$KS_PR_BRANCH" https://github.wdf.sap.corp/cc/kube-secrets "$KS_TEST"
  ```
- [x] 4B.2 Substitute github.com URL refs with the local helm-charts checkout path. **Edit the temporary clone, not the original kube-secrets repo:**
  ```
  HC_LOCAL=/Users/D065300/IdeaProjects/sapcc/helm-charts  # currently on poc/kustomize-metal-operator-remote with deletions applied

  # Portable sed (works on macOS BSD sed and GNU sed): rewrite each kustomization.yaml
  find "$KS_TEST/values/kustomize" -name 'kustomization.yaml' -print0 | while IFS= read -r -d '' f; do
    # Strip the github.com prefix and ?ref=<anything> suffix, prepend local path
    perl -i -pe "s|https://github.com/sapcc/helm-charts.git//(.+?)\?ref=[^\s]*|$HC_LOCAL/\1|g" "$f"
  done

  # Verify the rewrite
  grep -rn "github.com/sapcc/helm-charts" "$KS_TEST/values/kustomize/" && echo "FAIL: refs still present" || echo "OK: refs rewritten"
  grep -rn "$HC_LOCAL" "$KS_TEST/values/kustomize/" | head -20
  ```
  > **Plan defect found at execution time:** The `perl -i -pe` recipe above produces **absolute** filesystem paths (e.g., `/Users/.../helm-charts/system/...`). kustomize rejects absolute paths in `resources:` entries with `new root '<path>' cannot be absolute`. **Working recipe:** rewrite to **relative** paths via `os.path.relpath(HC_LOCAL, parent_dir_of_kustomization)`, using `os.path.realpath` for both endpoints to resolve macOS `/tmp -> /private/tmp` symlinks correctly. Build with `kustomize build --load-restrictor=LoadRestrictionsNone` to allow path traversal outside the kustomization root. See `verify.scratch.md` Task 4B section for the Python one-liner that worked.
- [x] 4B.3 Run `kustomize build` against the rewritten temporary clone:
  ```
  kustomize build "$KS_TEST/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/" > /tmp/rt-eu-de-1.kustomize.yaml 2>&1
  echo "rt-eu-de-1 exit: $?"

  kustomize build "$KS_TEST/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/" > /tmp/a-qa-de-200.kustomize.yaml 2>&1
  echo "a-qa-de-200 exit: $?"
  ```
  Both MUST exit 0. If either fails, the deletion has removed something a kube-secrets overlay still references — investigate by reading the kustomize error and the kube-secrets overlay file. Restore the dependency in helm-charts (rollback Task 2 / 3 partially) or coordinate a base change with the kube-secrets author.
- [x] 4B.4 Spot-check rendered output is non-empty and contains expected resource kinds.
- [x] 4B.5 Cleanup: `rm -rf /tmp/ks-pr-validation`. The original kube-secrets PR branch is unaffected (we only edited a throwaway clone).

### Common (both methods)

- [x] 4.6 Compare rendered output against pre-deletion baseline (if captured during a pre-Task-2 dry run) to confirm no resource kinds were unexpectedly dropped.

  > **Equivalent stronger check executed:** ran Method 4A (kustomize fetches helm-charts directly from github.com via `?ref=poc/kustomize-metal-operator-remote`, which on origin still points at the **pre-deletion** HEAD because our deletion commits are unpushed). The URL-fetch render and the local-rewrite render (Method 4B, post-deletion local) are **byte-identical** for both overlays. This proves the deletion removed only paths kube-secrets does not reference. See `verify.scratch.md` "Additional Method-4A-style validation" for measurements.

## 5. Update README

- [x] 5.1 Read the current `system/kustomize/metal-operator-remote/README.md` and identify sections that reference the deleted overlay paths (`host/overlays/<cluster>/`, `remote/custom/overlays/<cluster>/`, `overlays/<cluster>/`). The exploration noted these around lines 92–116 ("Add a new environment overlay" section).
- [x] 5.2 Replace those sections with a new "Per-cluster overlays" section pointing at kube-secrets:
  ```markdown
  ## Per-cluster overlays

  Per-cluster overlays for `metal-operator-remote` live in `cc/kube-secrets` under
  `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`.
  They reference the bases in this repository via kustomize Git URL refs:

  ```yaml
  # Example overlay kustomization.yaml in cc/kube-secrets:
  resources:
    - https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/host/base?ref=master
  ```

  Production overlays MUST track `?ref=master`. See the `cluster-overlay-layout`
  capability spec in cc/kube-secrets for the full requirements.

  ### Adding a new cluster

  Add a new directory in cc/kube-secrets at:
  `values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`
  with the appropriate `kustomization.yaml`, `host/`, and `remote/` subdirectories.
  No change to this repository is required for cluster onboarding.

  Tracking: cc/unified-kubernetes#1169
  ```
- [x] 5.3 Verify markdown renders cleanly. Optional: lint via `markdownlint` if available.

## 6. OpenSpec validation

- [x] 6.1 Run `openspec validate move-cluster-overlays-to-kube-secrets --strict` from this repo. Expected: `Change 'move-cluster-overlays-to-kube-secrets' is valid`.
- [x] 6.2 If validation fails, fix the offending artifact (most likely `specs/kustomize-resource-splitting/spec.md` or `specs/kustomize-sidecar-injection/spec.md` if their headers don't exactly match the existing specs) and re-run.

## 7. Combine with existing PR on `poc/kustomize-metal-operator-remote`

- [ ] 7.1 Stage all the changes from Tasks 2–5:
  ```
  git status --short
  git add -A system/kustomize/metal-operator-remote/
  git add openspec/changes/move-cluster-overlays-to-kube-secrets/
  ```
- [ ] 7.2 Commit with a clear message that this is the move-overlays portion of the combined PR:
  ```
  git commit -m "feat(kustomize): move per-cluster overlays to cc/kube-secrets

  Removes per-cluster overlays for rt-eu-de-1 and a-qa-de-200 from this
  repository. Their new home is cc/kube-secrets values/kustomize/.../
  metal-operator-remote/, which references the bases here via kustomize
  Git URL refs (?ref=master).

  Specs deltas applied: kustomize-resource-splitting (REMOVED + MODIFIED
  + ADDED), kustomize-sidecar-injection (MODIFIED). webhook-url-rendering
  unchanged.

  Companion change merged: cc/kube-secrets@<sha-from-task-1.1>
  Tracking: cc/unified-kubernetes#1169"
  ```
- [ ] 7.3 Push to the existing `poc/kustomize-metal-operator-remote` branch:
  ```
  git push origin poc/kustomize-metal-operator-remote
  ```
- [ ] 7.4 Update the existing PR description on github.com/sapcc/helm-charts to reflect the combined scope. Example structure:
  ```
  ## Summary
  This PR contains two distinct changes that landed on the same branch:

  1. **Original kustomize POC** (archived as openspec/changes/archive/2026-05-13-poc-kustomize-metal-operator-remote/) — introduced the kustomize tree at system/kustomize/metal-operator-remote/.
  2. **Move per-cluster overlays to cc/kube-secrets** (this commit, openspec/changes/move-cluster-overlays-to-kube-secrets/) — removes per-cluster overlays for rt-eu-de-1 and a-qa-de-200 from this repo. Their new home is cc/kube-secrets values/kustomize/.../metal-operator-remote/.

  ## Apply order
  Companion change in cc/kube-secrets has already merged at <SHA-from-task-1.1>.
  This PR is the SECOND of the two-repo coordinated change.

  ## Tracking
  cc/unified-kubernetes#1169
  ```
- [ ] 7.5 Wait for review approvals. Address feedback. Re-run Tasks 4 and 6 after any change.

## 8. Pre-merge final checks

- [x] 8.1 Re-run validation:
  ```
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  openspec validate move-cluster-overlays-to-kube-secrets --strict
  ```
  Expected: clean.
- [x] 8.2 Re-run kube-secrets overlay builds against this branch (Task 4.2). Both must succeed.
- [x] 8.3 Confirm the deleted paths are still deleted in the working tree (no accidental restore during rebase / conflict resolution):
  ```
  test ! -d system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1 && echo OK
  test ! -d system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200 && echo OK
  test ! -d system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1 && echo OK
  test ! -d system/kustomize/metal-operator-remote/remote/custom/overlays/a-qa-de-200 && echo OK
  test ! -d system/kustomize/metal-operator-remote/overlays/rt-eu-de-1 && echo OK
  test ! -d system/kustomize/metal-operator-remote/overlays/a-qa-de-200 && echo OK
  ```
  All six checks must print `OK`.
- [x] 8.4 Confirm bases / components / upstream are still present:
  ```
  test -d system/kustomize/metal-operator-remote/host/base && echo OK
  test -d system/kustomize/metal-operator-remote/remote/custom/base && echo OK
  test -d system/kustomize/metal-operator-remote/remote/custom/components/prod && echo OK
  test -d system/kustomize/metal-operator-remote/remote/custom/components/qa && echo OK
  test -d system/kustomize/metal-operator-remote/components/webhook-injector && echo OK
  test -d system/kustomize/metal-operator-remote/remote/upstream && echo OK
  ```
  All six checks must print `OK`.

## 9. Merge

- [ ] 9.1 Merge the existing PR on `poc/kustomize-metal-operator-remote` to master.
- [ ] 9.2 Verify on master:
  ```
  git checkout master && git pull --ff-only
  test ! -d system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1 && echo OK
  ```

## 10. Archive the OpenSpec change

- [ ] 10.1 From the helm-charts repo on master:
  ```
  openspec archive move-cluster-overlays-to-kube-secrets
  ```
  This applies the spec deltas to `openspec/specs/{kustomize-resource-splitting,kustomize-sidecar-injection}/spec.md` and moves the change directory under `openspec/changes/archive/<date>-move-cluster-overlays-to-kube-secrets/`.
- [ ] 10.2 Verify the spec files were updated correctly:
  ```
  grep -c 'cluster-overlay-layout\|kube-secrets' openspec/specs/kustomize-resource-splitting/spec.md
  ```
  Expected: at least one match (the cross-references introduced by the delta).
- [ ] 10.3 `openspec validate --strict` from the repo root. Expected: clean across all specs.
- [ ] 10.4 Commit and push the archived change:
  ```
  git add openspec/
  git commit -m "chore(openspec): archive move-cluster-overlays-to-kube-secrets

  Sync spec deltas to openspec/specs/{kustomize-resource-splitting,kustomize-sidecar-injection}/spec.md.

  Tracking: cc/unified-kubernetes#1169"
  git push origin master
  ```

## 11. Hand-off

- [ ] 11.1 Notify operators (in coordination with the kube-secrets companion change author): the helm-charts side of the move is complete. Per-cluster overlays for `rt-eu-de-1` and `a-qa-de-200` now live exclusively in `cc/kube-secrets`. The new kustomize-based pipelines in kube-secrets remain in `-OFF` state until cutover (separate activity).
- [ ] 11.2 Note the branch `poc/kustomize-metal-operator-remote` is now obsolete and can be deleted from the remote (and locally). It served two changes (the POC + the move-overlays); both are merged.
- [ ] 11.3 The DRAFT design doc at `docs/superpowers/specs/2026-05-18-move-cluster-overlays-to-kube-secrets-design.md` becomes historical context. Either delete it (the OpenSpec change archive is the authoritative record now) or convert it to an ADR-style record. Leave decision to the maintainer.
- [ ] 11.4 **Post-push URL re-validation (deferred from Task 4.6).** After Step 7.3 (push to `origin/poc/kustomize-metal-operator-remote`) and before merging, re-run Method 4A against the post-deletion remote HEAD to confirm the URL-fetch render is **still byte-identical** to the local-rewrite render captured during Task 4B:
  ```
  KS_TEST=/tmp/ks-pr-validation-postpush
  rm -rf "$KS_TEST"
  git clone --branch openspec/move-cluster-overlays-to-kube-secrets https://github.wdf.sap.corp/cc/kube-secrets "$KS_TEST"
  kustomize build "$KS_TEST/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/"   > /tmp/rt-eu-de-1.postpush.yaml
  kustomize build "$KS_TEST/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/" > /tmp/a-qa-de-200.postpush.yaml
  diff /tmp/rt-eu-de-1.postpush.yaml   /tmp/rt-eu-de-1.kustomize.yaml   && echo "rt-eu-de-1 OK"
  diff /tmp/a-qa-de-200.postpush.yaml /tmp/a-qa-de-200.kustomize.yaml && echo "a-qa-de-200 OK"
  rm -rf "$KS_TEST"
  ```
  Both diffs MUST be empty. If non-empty, something between local and remote diverged after push (e.g., CI-injected file, attribute filter, or an unexpected commit landing) — investigate before merging.
- [ ] 11.5 **Document the relative-path / `--load-restrictor=LoadRestrictionsNone` recipe in kube-secrets.** The plan's perl-rewrite recipe in Task 4B.2 produces absolute paths that kustomize rejects (see plan defect noted in Task 4B). Open a follow-up PR or issue against kube-secrets's `values/kustomize/README.md` (and the `cluster-overlay-layout` capability spec) to document the working recipe (Python `os.path.relpath` + `--load-restrictor=LoadRestrictionsNone`) so reviewers on other workstations don't hit the same dead-end.
- [ ] 11.6 **`system/kustomize/metal-operator-remote/VERIFICATION.md` disposition.** This file is a historical POC equivalence-verification record (committed in 2026-05 by the POC change, not modified in this change). After the deletion, line 83 (`kubectl apply -k overlays/rt-eu-de-1/ produces 167 resources`) is stale — that path no longer exists. The OpenSpec archive of `2026-05-13-poc-kustomize-metal-operator-remote` is the authoritative record of the POC. Maintainer choice (parallel to 11.3 for the DRAFT design doc):
  - **Option A** (recommended): delete it. `git rm system/kustomize/metal-operator-remote/VERIFICATION.md && git commit -m "chore(kustomize): remove POC-era VERIFICATION.md, superseded by openspec archive"`.
  - **Option B**: prepend a banner: "Historical record from the POC phase. Per-cluster overlay paths referenced below now live in cc/kube-secrets — see [README.md](./README.md) for the current layout."
  - **Option C**: keep as-is (the file's POC-historical context is implicit).
