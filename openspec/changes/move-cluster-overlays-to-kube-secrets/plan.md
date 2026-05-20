# Move Cluster Overlays to kube-secrets — helm-charts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove per-cluster kustomize overlays for `metal-operator-remote` (clusters `rt-eu-de-1`, `a-qa-de-200`) from `sapcc/helm-charts`, apply spec deltas to two existing capability specs, update the kustomize tree's README to point at the new home in `cc/kube-secrets`. Land via the existing open PR on `poc/kustomize-metal-operator-remote`.

**Architecture:** Pure removal — six overlay directories deleted, README updated, two spec deltas applied at archive time. Bases (`host/base/`, `remote/upstream/`, `remote/custom/base/`, components) stay intact and continue to be consumed by kube-secrets overlays via kustomize Git URL refs (`https://github.com/sapcc/helm-charts.git//...?ref=master`).

**Tech Stack:** kustomize, git, openspec CLI 1.2.0, gh CLI (for PR description update). No new code; no Makefile changes.

**Cross-references:**
- Specs deltas: `openspec/changes/move-cluster-overlays-to-kube-secrets/specs/kustomize-resource-splitting/spec.md`, `openspec/changes/move-cluster-overlays-to-kube-secrets/specs/kustomize-sidecar-injection/spec.md`
- Design: `openspec/changes/move-cluster-overlays-to-kube-secrets/design.md`
- Companion change (must be merged first): `cc/kube-secrets/openspec/changes/move-cluster-overlays-to-kube-secrets`
- Tracking issue: `cc/unified-kubernetes#1169`
- Branch: `poc/kustomize-metal-operator-remote` (existing — combines with the open PR)

**Working directory throughout this plan:** `/Users/D065300/IdeaProjects/sapcc/helm-charts`

---

## Task 1: Pre-flight verification

**Files:**
- Read: companion kube-secrets master OR PR branch
- Read: `system/metal-operator-remote/Chart.yaml` (verify Helm chart unaffected)

- [ ] **Step 1.1: Determine kube-secrets companion state and select validation method**

The kube-secrets companion change may be in either of two states. The state determines which validation method to use in Task 4.

```bash
# Check kube-secrets master HEAD
KS_REMOTE=https://github.wdf.sap.corp/cc/kube-secrets
KS_MASTER_SHA=$(git ls-remote "$KS_REMOTE" refs/heads/master | awk '{print $1}')
echo "kube-secrets master HEAD: $KS_MASTER_SHA"

# Look for the new overlay file on master
git ls-remote "$KS_REMOTE" refs/heads/master | head -1
# Then fetch and inspect (lightweight — just one path):
KS_TMP=/tmp/ks-state-check
git clone --depth=1 "$KS_REMOTE" "$KS_TMP" 2>/dev/null || (cd "$KS_TMP" && git pull --ff-only)
test -f "$KS_TMP/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/kustomization.yaml" \
  && echo "STATE A: companion has merged to master" \
  || echo "STATE B: companion is on a feature branch (not yet on master)"
```

Record the determined state in `verify.scratch.md` along with:
- **State A**: kube-secrets master SHA (for traceability in commit messages and PR description).
- **State B**: kube-secrets PR number, branch name, and PR HEAD SHA.

Validation methods:
- **State A → Task 4A** (direct kustomize build with `?ref=master`).
- **State B → Task 4B** (local-path rewrite). This is the normal review-time validation.

- [ ] **Step 1.2: Verify kube-secrets has the new overlays (regardless of state)**

For State A (master):
```bash
KS=/tmp/ks-master
git clone "$KS_REMOTE" "$KS"
cd "$KS" && git checkout master && git pull --ff-only
git log -1 --format='%h %s'
test -f $KS/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/kustomization.yaml && echo "rt-eu-de-1 OK"
test -f $KS/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/kustomization.yaml && echo "a-qa-de-200 OK"
```

For State B (branch — replace `<KS_PR_BRANCH>` with the actual branch name):
```bash
KS=/tmp/ks-pr-branch
KS_PR_BRANCH=<branch-name>
git clone --branch "$KS_PR_BRANCH" "$KS_REMOTE" "$KS"
cd "$KS" && git log -1 --format='%h %s'
test -f $KS/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/kustomization.yaml && echo "rt-eu-de-1 OK"
test -f $KS/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/kustomization.yaml && echo "a-qa-de-200 OK"
```

Both files must be present in either state. If missing, the companion change is incomplete; STOP and notify the kube-secrets author.

- [ ] **Step 1.3: Verify kube-secrets overlay refs are sensible**

```bash
# State A: refs MUST be ?ref=master (kube-secrets's own spec enforces this on master).
# State B: refs MAY be ?ref=master OR ?ref=<branch-name> with TEST-PHASE comment.
grep -rn '?ref=' $KS/values/kustomize/ | sort -u
grep -rn 'TEST-PHASE' $KS/values/kustomize/
```

- **State A**: any non-master ref or TEST-PHASE comment is a bug in the kube-secrets PR (it shouldn't have merged with those). STOP and notify.
- **State B**: TEST-PHASE comments are acceptable during review; flag for the kube-secrets author's attention but do not block. The local-path rewrite in Task 4B substitutes whatever ref is present.

- [ ] **Step 1.4: Confirm working branch**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
git branch --show-current
```
Expected: `poc/kustomize-metal-operator-remote`. If different, switch:
```bash
git checkout poc/kustomize-metal-operator-remote
git pull --ff-only
```
Per user instruction, this change combines with the existing open PR on this branch.

- [ ] **Step 1.5: Global grep for references to to-be-deleted paths**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
grep -rln -E 'host/overlays/(rt-eu-de-1|a-qa-de-200)|remote/custom/overlays/(rt-eu-de-1|a-qa-de-200)|metal-operator-remote/overlays/(rt-eu-de-1|a-qa-de-200)' \
  --exclude-dir=.git \
  --exclude-dir=openspec/changes/archive \
  | sort -u
```
Categorize each match:
- (a) **Target of deletion** — the overlay file itself or its sibling. OK to delete.
- (b) **Archived change** — `openspec/changes/archive/2026-05-13-poc-kustomize-metal-operator-remote/` (excluded above). Preserve.
- (c) **Other consumer** — Makefile target, script, doc. **MUST be updated as part of this change.** Document in `verify.scratch.md` and add a sub-task to Task 5 (README) or a new Task 5b.

If category (c) hits exist, STOP and review with user before proceeding.

- [ ] **Step 1.6: Verify legacy Helm chart unaffected**

```bash
grep -n 'kustomize/metal-operator-remote' system/metal-operator-remote/Chart.yaml \
                                            system/metal-operator-remote/Chart.lock \
                                            system/metal-operator-remote/values.yaml \
                                            system/metal-operator-remote/templates/*.yaml \
                                            system/metal-operator-remote/Makefile 2>/dev/null
```
Expected: zero matches. The Helm chart at `system/metal-operator-remote/` and the kustomize tree at `system/kustomize/metal-operator-remote/` are independent.

---

## Task 2: Delete per-cluster overlays for rt-eu-de-1

**Files:**
- Delete: `system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1/`
- Delete: `system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1/`
- Delete: `system/kustomize/metal-operator-remote/overlays/rt-eu-de-1/`

- [ ] **Step 2.1: Failing test — bases build cleanly before deletion**

Baseline check that bases build:
```bash
kustomize build system/kustomize/metal-operator-remote/host/base/ > /dev/null && echo "host/base OK"
kustomize build system/kustomize/metal-operator-remote/remote/custom/base/ > /dev/null && echo "remote/custom/base OK"
```
Both should already work. Record success in `verify.scratch.md`.

- [ ] **Step 2.2: Delete the three rt-eu-de-1 overlay directories**

```bash
git rm -r system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1
git rm -r system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1
git rm -r system/kustomize/metal-operator-remote/overlays/rt-eu-de-1
```

- [ ] **Step 2.3: Verify deletion**

```bash
find system/kustomize/metal-operator-remote -type d -name 'rt-eu-de-1'
```
Expected: empty output.

- [ ] **Step 2.4: Verify bases still build**

```bash
kustomize build system/kustomize/metal-operator-remote/host/base/ > /dev/null && echo "host/base OK"
kustomize build system/kustomize/metal-operator-remote/remote/custom/base/ > /dev/null && echo "remote/custom/base OK"
```
Both must still print OK.

- [ ] **Step 2.5: Commit**

```bash
git commit -m "feat(kustomize): remove rt-eu-de-1 per-cluster overlays

Per-cluster overlays for metal-operator-remote moved to cc/kube-secrets.
This commit removes the overlay paths from this repo:
- system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1/
- system/kustomize/metal-operator-remote/remote/custom/overlays/rt-eu-de-1/
- system/kustomize/metal-operator-remote/overlays/rt-eu-de-1/

Bases, components, and upstream pre-renders are unchanged. kube-secrets
overlays continue to consume them via Git URL refs (?ref=master).

Tracking: cc/unified-kubernetes#1169
Refs: openspec/changes/move-cluster-overlays-to-kube-secrets/"
```

---

## Task 3: Delete per-cluster overlays for a-qa-de-200

**Files:**
- Delete: `system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200/`
- Delete: `system/kustomize/metal-operator-remote/remote/custom/overlays/a-qa-de-200/`
- Delete: `system/kustomize/metal-operator-remote/overlays/a-qa-de-200/`

- [ ] **Step 3.1: Delete the three a-qa-de-200 overlay directories**

```bash
git rm -r system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200
git rm -r system/kustomize/metal-operator-remote/remote/custom/overlays/a-qa-de-200
git rm -r system/kustomize/metal-operator-remote/overlays/a-qa-de-200
```

- [ ] **Step 3.2: Verify deletion**

```bash
find system/kustomize/metal-operator-remote -type d -name 'a-qa-de-200'
```
Expected: empty output.

- [ ] **Step 3.3: Check parent overlays/ directories — remove if empty**

```bash
for dir in system/kustomize/metal-operator-remote/host/overlays \
          system/kustomize/metal-operator-remote/remote/custom/overlays \
          system/kustomize/metal-operator-remote/overlays; do
  if [[ -d "$dir" ]]; then
    contents=$(ls -A "$dir")
    if [[ -z "$contents" ]]; then
      echo "Empty: $dir — removing"
      rmdir "$dir"
    else
      echo "Not empty: $dir — contents: $contents"
    fi
  fi
done
```
For any non-empty directory, document the contents in `verify.scratch.md`. Likely there are no other clusters present (only `rt-eu-de-1` and `a-qa-de-200` had overlays per the original POC).

- [ ] **Step 3.4: Commit**

```bash
git add -A system/kustomize/metal-operator-remote/
git commit -m "feat(kustomize): remove a-qa-de-200 per-cluster overlays

Per-cluster overlays for metal-operator-remote moved to cc/kube-secrets.
This commit removes:
- system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200/
- system/kustomize/metal-operator-remote/remote/custom/overlays/a-qa-de-200/
- system/kustomize/metal-operator-remote/overlays/a-qa-de-200/

After this commit, no cluster-specific overlays remain in this repo for
metal-operator-remote. Bases continue to be consumed by kube-secrets
overlays via Git URL refs.

Tracking: cc/unified-kubernetes#1169"
```

---

## Task 4: Validate against kube-secrets — pick method 4A or 4B based on Step 1.1 state

**Files:**
- Read: temporary kube-secrets clone (`/tmp/ks-master` or `/tmp/ks-pr-validation`)
- Read: local helm-charts checkout (`/Users/D065300/IdeaProjects/sapcc/helm-charts` at the PR branch HEAD with deletions applied)

**Choose ONE method** based on the kube-secrets companion's state determined in Step 1.1.

### Method 4A — Direct kustomize build (kube-secrets master, post-merge)

Use only if Step 1.1 determined State A (companion merged to master).

- [ ] **Step 4A.1: Confirm working tree of `/tmp/ks-master`**

```bash
cd /tmp/ks-master && git checkout master && git pull --ff-only
git log -1 --format='%h %s'
```

- [ ] **Step 4A.2: Push helm-charts branch HEAD so refs resolve**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
git push origin poc/kustomize-metal-operator-remote
```
This makes the branch's HEAD reachable via HTTPS (kube-secrets references `?ref=master`, but reviewers may want to test against the branch — see 4A.3 alternate).

- [ ] **Step 4A.3: Build each kube-secrets overlay**

```bash
KS=/tmp/ks-master
kustomize build "$KS/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/" > /tmp/rt-eu-de-1.kustomize.yaml 2>&1
echo "rt-eu-de-1 exit: $?"

kustomize build "$KS/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/" > /tmp/a-qa-de-200.kustomize.yaml 2>&1
echo "a-qa-de-200 exit: $?"
```

Both MUST exit 0. Important: this validates against `?ref=master` of helm-charts, which still has the in-tree overlays. The deletion in this PR isn't merged yet. So 4A is a "production today" validation — useful but not a "post-merge" validation.

For a "post-merge" validation while still on the helm-charts branch, switch to Method 4B (which uses local helm-charts paths and exercises the deletion).

- [ ] **Step 4A.4: Spot-check rendered output**

```bash
grep -E '^kind: ' /tmp/rt-eu-de-1.kustomize.yaml | sort -u
grep -E '^kind: ' /tmp/a-qa-de-200.kustomize.yaml | sort -u
```

### Method 4B — Local-path rewrite validation (kube-secrets PR branch, pre-merge)

**This is the normal review-time validation.** Use when the kube-secrets companion is on a feature branch and you want to validate the helm-charts PR (with deletions applied) against the kube-secrets PR. Substitutes `https://github.com/sapcc/helm-charts.git//<path>?ref=<anything>` with the local helm-charts checkout path so kustomize reads bases from the working tree directly.

- [ ] **Step 4B.1: Identify kube-secrets PR branch and clone fresh copy**

```bash
KS_PR_BRANCH=<kube-secrets-PR-branch-name-from-Step-1.1>
KS_TEST=/tmp/ks-pr-validation
rm -rf "$KS_TEST"
git clone --branch "$KS_PR_BRANCH" https://github.wdf.sap.corp/cc/kube-secrets "$KS_TEST"
cd "$KS_TEST" && git log -1 --format='%h %s'
```

- [ ] **Step 4B.2: Rewrite github.com URL refs to local helm-charts path**

```bash
HC_LOCAL=/Users/D065300/IdeaProjects/sapcc/helm-charts
# helm-charts must be on poc/kustomize-metal-operator-remote with all deletions applied (Tasks 2 + 3 done)

# Use perl for portable in-place edit (works on macOS BSD and Linux GNU)
find "$KS_TEST/values/kustomize" -name 'kustomization.yaml' -print0 | while IFS= read -r -d '' f; do
  perl -i -pe "s|https://github.com/sapcc/helm-charts.git//(.+?)\\?ref=[^\\s\"']*|$HC_LOCAL/\\1|g" "$f"
done

# Verify the rewrite — github.com refs should be gone, replaced by local paths.
echo "=== Remaining github.com refs (should be empty) ==="
grep -rn "github.com/sapcc/helm-charts" "$KS_TEST/values/kustomize/" || echo "OK: none remaining"

echo "=== Local-path refs (sample) ==="
grep -rn "$HC_LOCAL" "$KS_TEST/values/kustomize/" | head -10
```

If `grep -rn "github.com/sapcc/helm-charts"` still finds matches after the rewrite, the perl regex didn't match those particular forms. Inspect those lines and adjust the regex. Common variants:
- `https://github.com/sapcc/helm-charts.git//path?ref=master`
- `https://github.com/sapcc/helm-charts.git//path?ref=feature-branch`
- `https://github.com/sapcc/helm-charts.git//path` (no ref — uncommon, but possible)

- [ ] **Step 4B.3: Run kustomize build**

```bash
kustomize build "$KS_TEST/values/kustomize/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote/" > /tmp/rt-eu-de-1.kustomize.yaml 2>&1
echo "rt-eu-de-1 exit: $?"

kustomize build "$KS_TEST/values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/" > /tmp/a-qa-de-200.kustomize.yaml 2>&1
echo "a-qa-de-200 exit: $?"
```

Both MUST exit 0. This is the **post-merge equivalent** test — it builds against helm-charts state with deletions applied (the local working tree) and kube-secrets state from the PR. If both succeed, the helm-charts PR is safe to merge once the kube-secrets PR is also approved.

- [ ] **Step 4B.4: Investigate failures**

If either build fails:
1. Read the kustomize error output. It usually names a missing path or unresolvable resource.
2. Common cases:
   - **Missing base** — the deletion removed a path the kube-secrets overlay expects. Restore it: `git restore system/kustomize/metal-operator-remote/<path>` and revisit which overlays were targets-of-deletion.
   - **Path mismatch** — the local-path rewrite produced a path that doesn't exist in the local helm-charts checkout. Inspect the rewritten kustomization.yaml and the local filesystem.
   - **Component unavailable** — a `components/` reference resolved to a path that's correct but contains broken kustomization. Inspect.
3. Fix in helm-charts (Tasks 2 / 3 / 5 amendments) or coordinate with kube-secrets author.
4. Re-run from Step 4B.2.

- [ ] **Step 4B.5: Spot-check rendered output**

```bash
grep -E '^kind: ' /tmp/rt-eu-de-1.kustomize.yaml | sort -u
grep -E '^kind: ' /tmp/a-qa-de-200.kustomize.yaml | sort -u
```

Compare against expected resource kinds from the original overlay's intent: Deployment, Service, ConfigMap, ClusterRole, ClusterRoleBinding, ServiceAccount, plus cluster-specific resources. No kind should be unexpectedly absent.

- [ ] **Step 4B.6: Cleanup**

```bash
rm -rf /tmp/ks-pr-validation
```

The original kube-secrets PR branch is unaffected — the rewrite only modified the throwaway `/tmp/ks-pr-validation` clone.

---

## Task 5: Update README

**Files:**
- Modify: `system/kustomize/metal-operator-remote/README.md`

- [ ] **Step 5.1: Read current README and identify in-tree-overlay references**

```bash
cat system/kustomize/metal-operator-remote/README.md | grep -n -E 'overlay|host/overlays|remote/custom/overlays|rt-eu-de-1|a-qa-de-200'
```
Note line numbers of the "Add a new environment overlay" section (per exploration, around lines 92–116). Note any other overlay references.

- [ ] **Step 5.2: Edit README — replace in-tree overlay sections**

Open `system/kustomize/metal-operator-remote/README.md`. Locate the "Add a new environment overlay" section (or equivalent). Replace it with:

```markdown
## Per-cluster overlays

Per-cluster overlays for `metal-operator-remote` live in `cc/kube-secrets`
(`https://github.wdf.sap.corp/cc/kube-secrets`) under
`values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`.

They reference the bases in this repository via kustomize Git URL refs:

```yaml
# Example overlay kustomization.yaml in cc/kube-secrets:
resources:
  - https://github.com/sapcc/helm-charts.git//system/kustomize/metal-operator-remote/host/base?ref=master
```

Production overlays MUST track `?ref=master`. Test/scratch overlays may
temporarily reference a feature branch with a `# TEST-PHASE: tracking <branch>`
comment, but MUST be reverted to `master` before merge. See the
`cluster-overlay-layout` capability spec in cc/kube-secrets for the full
requirements.

### Adding a new cluster

Add a new directory in `cc/kube-secrets` at:
`values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/`
with the appropriate `kustomization.yaml`, `host/`, and `remote/` subdirectories.
**No change to this repository is required for cluster onboarding.**

### Updating bases

Changes to `host/base/`, `remote/custom/base/`, components, or upstream pre-renders
in this repository are picked up automatically by kube-secrets overlays at the next
`kustomize build` (since they track `?ref=master`). Apply normal change-management
in this repository (PR review, OpenSpec change for spec-level requirements).

Tracking: [`cc/unified-kubernetes#1169`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169)
```

Remove any other text that references in-tree overlay paths (e.g., `kustomize build host/overlays/<cluster>/`, `kubectl apply -k overlays/<cluster>/`).

- [ ] **Step 5.3: Verify markdown syntactically valid**

```bash
which markdownlint && markdownlint system/kustomize/metal-operator-remote/README.md
# OR
which mdl && mdl system/kustomize/metal-operator-remote/README.md
# OR (always works) — visually inspect:
less system/kustomize/metal-operator-remote/README.md
```

- [ ] **Step 5.4: Commit**

```bash
git add system/kustomize/metal-operator-remote/README.md
git commit -m "docs(kustomize): update README to reference kube-secrets for overlays

Per-cluster overlays now live in cc/kube-secrets at
values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/.
README updated to point readers there and document the cross-repo wiring.

Tracking: cc/unified-kubernetes#1169"
```

---

## Task 6: OpenSpec validation

**Files:**
- Read-only: `openspec/changes/move-cluster-overlays-to-kube-secrets/`

- [ ] **Step 6.1: Validate the change**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
openspec validate move-cluster-overlays-to-kube-secrets --strict
```
Expected: `Change 'move-cluster-overlays-to-kube-secrets' is valid`.

- [ ] **Step 6.2: If validation fails, fix the spec deltas**

Likely failure modes:
- The MODIFIED Requirement header in `specs/kustomize-resource-splitting/spec.md` doesn't exactly match the existing `openspec/specs/kustomize-resource-splitting/spec.md` header (case-sensitive, whitespace-sensitive).
  - Fix: re-read the existing spec's `### Requirement: ...` line verbatim and update the delta to match.
- A scenario in the delta has wrong heading level (must be `####`, not `###` or bullet).
  - Fix: ensure all scenarios use exactly four hashtags.
- A REMOVED Requirement is missing `**Reason**:` or `**Migration**:`.
  - Fix: add both per the template.

After fixing, re-run `openspec validate --strict`.

---

## Task 7: Combine with existing PR

**Files:**
- Modify: PR description on `github.com/sapcc/helm-charts` (existing open PR for `poc/kustomize-metal-operator-remote`)

- [ ] **Step 7.1: Push current branch state**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
git push origin poc/kustomize-metal-operator-remote
```

- [ ] **Step 7.2: Identify the existing PR number**

```bash
gh pr list --head poc/kustomize-metal-operator-remote --json number,title,state --jq '.[] | "PR #\(.number): \(.title) [\(.state)]"'
```
Record the PR number (e.g., `#NNNN`).

- [ ] **Step 7.3: Update the PR description**

```bash
PR_NUM=<from step 7.2>
KS_SHA=<from step 1.1>

gh pr edit $PR_NUM --body "$(cat <<EOF
## Summary

This PR contains two distinct changes that landed on the same branch:

1. **Original kustomize POC** — introduces the kustomize tree at \`system/kustomize/metal-operator-remote/\`. Spec-tracked under \`openspec/changes/archive/2026-05-13-poc-kustomize-metal-operator-remote/\` (already archived).

2. **Move per-cluster overlays to cc/kube-secrets** — removes per-cluster overlays for \`rt-eu-de-1\` and \`a-qa-de-200\` from this repo. Their new home is \`cc/kube-secrets\` at \`values/kustomize/<clusterType>/<region>/<clusterName>/metal-operator-remote/\`. Spec-tracked under \`openspec/changes/move-cluster-overlays-to-kube-secrets/\`.

## Apply order (Two-repo coordinated change)

Companion change in cc/kube-secrets has merged at \`$KS_SHA\`. **This PR is the SECOND of the two.** Do not merge before the kube-secrets companion is on master.

## Validation

- \`openspec validate move-cluster-overlays-to-kube-secrets --strict\` passes
- \`kustomize build\` of each kube-secrets overlay against this branch produces valid output (see Task 4 of plan.md)

## Tracking

[\`cc/unified-kubernetes#1169\`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1169)
EOF
)"
```

- [ ] **Step 7.4: Notify reviewers of the augmented scope**

Post a comment on the PR explaining the new commits and pointing reviewers at `openspec/changes/move-cluster-overlays-to-kube-secrets/proposal.md` for the move-overlays scope:

```bash
gh pr comment $PR_NUM --body "Updated this PR to combine the original kustomize POC with the move-cluster-overlays-to-kube-secrets change. New commits delete per-cluster overlays for rt-eu-de-1 and a-qa-de-200 and apply spec deltas. Companion kube-secrets PR has merged at $KS_SHA. See openspec/changes/move-cluster-overlays-to-kube-secrets/proposal.md for the full proposal."
```

- [ ] **Step 7.5: Wait for review approvals; address feedback**

Iterate as needed. After any change to overlay-related files (none expected at this stage; the deletion is the change), re-run Tasks 4 and 6.

---

## Task 8: Pre-merge final checks

**Files:**
- All paths verified previously, re-confirmed.

- [ ] **Step 8.1: Re-validate openspec**

```bash
openspec validate move-cluster-overlays-to-kube-secrets --strict
```
Expected: clean.

- [ ] **Step 8.2: Re-run kube-secrets overlay validation (Task 4.2)**

This is critical immediately before merge. Re-run with the latest branch HEAD pushed.

- [ ] **Step 8.3: Confirm deleted paths are still deleted**

```bash
for path in \
  host/overlays/rt-eu-de-1 \
  host/overlays/a-qa-de-200 \
  remote/custom/overlays/rt-eu-de-1 \
  remote/custom/overlays/a-qa-de-200 \
  overlays/rt-eu-de-1 \
  overlays/a-qa-de-200; do
  if [[ ! -d "system/kustomize/metal-operator-remote/$path" ]]; then
    echo "OK: $path is deleted"
  else
    echo "FAIL: $path still exists"
    exit 1
  fi
done
```
All six must print OK. If any prints FAIL, a rebase or merge has restored the directory — `git rm -r` it again.

- [ ] **Step 8.4: Confirm bases / components / upstream are intact**

```bash
for path in \
  host/base \
  remote/custom/base \
  remote/custom/components/prod \
  remote/custom/components/qa \
  components/webhook-injector \
  remote/upstream; do
  if [[ -d "system/kustomize/metal-operator-remote/$path" ]]; then
    echo "OK: $path is present"
  else
    echo "FAIL: $path is missing"
    exit 1
  fi
done
```
All six must print OK.

---

## Task 9: Merge

- [ ] **Step 9.1: Merge the PR**

Use the PR's merge button on github.com/sapcc/helm-charts (or `gh pr merge $PR_NUM`). Use the merge strategy the repo's CODEOWNERS / merge policy mandates (squash, rebase, or merge commit — the project's existing convention).

- [ ] **Step 9.2: Verify on master**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
git checkout master && git pull --ff-only
test ! -d system/kustomize/metal-operator-remote/host/overlays/rt-eu-de-1 && echo "rt-eu-de-1 deleted on master OK"
test ! -d system/kustomize/metal-operator-remote/host/overlays/a-qa-de-200 && echo "a-qa-de-200 deleted on master OK"
test -d system/kustomize/metal-operator-remote/host/base && echo "host/base intact OK"
```

---

## Task 10: Archive the OpenSpec change

**Files:**
- Modify: `openspec/specs/kustomize-resource-splitting/spec.md` (delta applied at archive)
- Modify: `openspec/specs/kustomize-sidecar-injection/spec.md` (delta applied at archive)
- Move: `openspec/changes/move-cluster-overlays-to-kube-secrets/` → `openspec/changes/archive/<date>-move-cluster-overlays-to-kube-secrets/`

- [ ] **Step 10.1: Run openspec archive**

```bash
cd /Users/D065300/IdeaProjects/sapcc/helm-charts
git checkout master && git pull --ff-only
openspec archive move-cluster-overlays-to-kube-secrets
```

- [ ] **Step 10.2: Verify spec deltas applied correctly**

```bash
grep -c 'cluster-overlay-layout\|kube-secrets' openspec/specs/kustomize-resource-splitting/spec.md
grep -n 'Requirement: Per-cluster overlay placement delegated to kube-secrets capability' openspec/specs/kustomize-resource-splitting/spec.md
```
Expected: at least one cross-reference match; the new ADDED Requirement present.

```bash
grep -n 'Component supports removal via .patch:delete' openspec/specs/kustomize-sidecar-injection/spec.md
```
Expected: the modified scenario header present.

- [ ] **Step 10.3: Verify removed requirements are gone**

```bash
grep -c 'Host overlays parameterize per-environment values' openspec/specs/kustomize-resource-splitting/spec.md
grep -c 'Top-level per-environment kustomization renders all resources' openspec/specs/kustomize-resource-splitting/spec.md
```
Both should return 0 (the requirements are removed).

- [ ] **Step 10.4: Validate all specs**

```bash
openspec validate --strict
```
Expected: clean across all specs (kustomize-resource-splitting, kustomize-sidecar-injection, webhook-url-rendering).

- [ ] **Step 10.5: Commit and push the archive**

```bash
git add openspec/
git commit -m "chore(openspec): archive move-cluster-overlays-to-kube-secrets

Sync spec deltas to:
- openspec/specs/kustomize-resource-splitting/spec.md (REMOVED + MODIFIED + ADDED)
- openspec/specs/kustomize-sidecar-injection/spec.md (MODIFIED)

Tracking: cc/unified-kubernetes#1169"
git push origin master
```

---

## Task 11: Hand-off and cleanup

- [ ] **Step 11.1: Notify operators**

In coordination with the kube-secrets companion change author, notify the on-call ops channel:
- The helm-charts side of the move is complete and merged.
- Per-cluster overlays for `rt-eu-de-1` and `a-qa-de-200` now live exclusively in `cc/kube-secrets`.
- The new kustomize-based pipelines in kube-secrets remain in `-OFF` state until cutover (separate activity, not part of this change).

- [ ] **Step 11.2: Branch cleanup (optional)**

The branch `poc/kustomize-metal-operator-remote` served two changes (the POC + the move-overlays); both are now merged. Delete from remote and locally:
```bash
git push origin --delete poc/kustomize-metal-operator-remote
git branch -d poc/kustomize-metal-operator-remote
```
(Skip if the team's policy is to keep merged branches.)

- [ ] **Step 11.3: DRAFT design doc disposition**

The DRAFT design doc at `docs/superpowers/specs/2026-05-18-move-cluster-overlays-to-kube-secrets-design.md` was the brainstorming carry-over. It is now historical context — the OpenSpec archive (`openspec/changes/archive/<date>-move-cluster-overlays-to-kube-secrets/`) is the authoritative record.

Maintainer choice:
- **Option A** (recommended): delete it. `git rm docs/superpowers/specs/2026-05-18-move-cluster-overlays-to-kube-secrets-design.md && git commit -m "chore: remove draft design doc, superseded by openspec archive"`.
- **Option B**: keep as historical context. No action.
- **Option C**: convert to ADR. Move to `docs/adr/<ADR-number>-move-cluster-overlays-to-kube-secrets.md` if the project uses ADRs.

- [ ] **Step 11.4: Clean up the kube-secrets master clone**

```bash
rm -rf /tmp/ks-master
```
(Only if no other ongoing tasks need it.)

---

## Self-review checklist

Before declaring this plan complete:

1. **Spec coverage** — every requirement in the spec deltas is exercised:
   - `kustomize-resource-splitting`:
     - ADDED "Per-cluster overlay placement delegated to kube-secrets capability" → enforced by Tasks 2, 3 (deletion) + Task 4 (kube-secrets builds against this branch) + Task 6 (validation).
     - MODIFIED "Host and remote produce equivalent output" → enforced by Task 4 (cross-validation with kube-secrets render).
     - REMOVED "Host overlays parameterize per-environment values" + "Top-level per-environment kustomization renders all resources" → enforced by Tasks 2, 3 (the deletion) and Task 8.3 (post-merge confirmation).
   - `kustomize-sidecar-injection`:
     - MODIFIED "Webhook-injector sidecar removable per environment" → enforced by Task 4 (kube-secrets overlay using $patch:delete still builds correctly against this branch).
2. **No placeholders** — every step has real commands or real instructions. No "TBD", "implement appropriately", etc.
3. **Path consistency** — all `system/kustomize/metal-operator-remote/...` paths in this plan match the actual filesystem layout.
4. **Frequent commits** — Tasks 2, 3, 5 each end with a commit. Task 7 pushes; Task 9 merges; Task 10 commits the archive. ~4 commits total, plus the merge commit.
