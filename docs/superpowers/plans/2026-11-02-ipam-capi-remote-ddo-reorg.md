# IPAM DDO overlay reorganization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task (execution method already supplied by the user = NATIVE). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trim dead/redundant RBAC from the IPAM DDO overlay, de-"legacy" the file organization, and keep the migration-fidelity tests honest — with no behavior change and no CRD byte/pin change.

**Architecture:** A layered kustomize overlay under `system/kustomize/ipam-capi-remote-ddo/` rendered by DDO into a seed and a shoot stream. This reorg deletes the dead webhook-injector seed `ClusterRole`/`ClusterRoleBinding` (injector patches the shoot via its target kubeconfig, so it needs only namespaced seed perms), deletes both redundant shoot leader-election RBAC pairs (manager runs `--leader-elect=false`; the `ClusterRole` form was a GRM workaround DDO makes obsolete), splits the two `legacy-support.yaml` bundles into purpose-named files, renames `legacy_render.py`, and updates the contract tests + sha-pinned baseline to assert the intentional removals.

**Tech Stack:** kustomize v5.8.1, Python 3 + PyYAML, bash test harness, Helm (pinned-chart oracle in tests). Integration branch `master`.

**Spec:** `docs/superpowers/specs/2026-11-02-ipam-capi-remote-ddo-reorg-design.md`

## Global Constraints

- Overlay root `system/kustomize/ipam-capi-remote-ddo/`; run every overlay test from that cwd.
- DDO stamps `metadata.namespace` on namespaced objects at render (seed ns = `cr.Namespace`) but NEVER touches `subjects[].namespace`; cluster-scoped objects are skipped. Do not hardcode a seed namespace and do not add a per-placement CR namespace jsonPatch (both rejected by the user).
- No change to: controller image, conversion-webhook wiring, the shoot-side injector `ClusterRole` (`ipam-capi-remote-webhook-injector` in `shoot/rbac.yaml`), CRD bytes, or CRD sha256 pins.
- The kept seed injector `Role` stays at metal parity (do not narrow verbs/resourceNames) unless a concrete reason arises.
- kube-secrets CR #5683 gets NO change (verified: it has no seed-namespace jsonPatch).
- Empirically verified current render inventory at HEAD `46e5ff0088`: **SEED 15 objects, SHOOT 25 objects**, all tests green.

## Review Focus

- Deleting the seed injector `ClusterRole`/`ClusterRoleBinding` must not drop the kept seed `Role`/`RoleBinding` — Task 1 render assertion pins SA+Role+RoleBinding present and ClusterRole/ClusterRoleBinding absent.
- Deleting shoot leader-election RBAC must not touch the shoot injector `ClusterRole` or the cross-operator metal bindings — Task 2 render assertion pins the shoot injector ClusterRole + both metal bindings still present.
- The sha-pinned `crd-baseline.json` fingerprints the pre-change inventory; a stale pin or un-regenerated baseline silently breaks `historical_check` — Task 4 regenerates the baseline and updates the pinned hash as a deliberate reviewed step.
- `negative_tests` iterates every rendered doc; a removed object that a negative mutation still references would raise a `KeyError` not a clean assertion — Task 4 removes dangling references to deleted objects.
- Renaming `legacy_render.py` must update every importer/reference (migration_contract.py, test scripts, README) or the suite breaks on import — Task 3 greps for residual `legacy_render` / `legacy-support` / "legacy" references.

---

### Task 0: Pin the exact before/after inventory (no code change)

**Files:**
- Read only: `tests/legacy_render.py`, `tests/migration_contract.py`, `tests/crd-baseline.json`

**Interfaces:**
- Produces: the authoritative seed/shoot identity lists and counts that Tasks 1/2/4 encode. No code artifact.

- [ ] **Step 1: Dump the live overlay render keys**

Run from `system/kustomize/ipam-capi-remote-ddo/`:
Use a small helper (avoid list-comprehension-in-print, which is invalid Python):
```bash
cat > /tmp/dumpkeys.py <<'PY'
import sys, yaml
for d in yaml.safe_load_all(sys.stdin):
    if d:
        print(d["kind"], d["metadata"]["name"])
PY
kustomize build seed/  | python3 /tmp/dumpkeys.py | sort
kustomize build shoot/ | python3 /tmp/dumpkeys.py | sort
```
Expected: SEED 15 lines (incl `ClusterRole ipam-capi-remote-webhook-injector` + `ClusterRoleBinding ipam-capi-remote-webhook-injector`); SHOOT 25 lines (incl `ClusterRole ipam-capi-leader-election-role`, `ClusterRoleBinding ipam-capi-leader-election-rolebinding`, `ClusterRole ipam-capi-remote-leader-election-role`, `ClusterRoleBinding ipam-capi-remote-leader-election-rolebinding`).

- [ ] **Step 2: Dump the oracle render keys**

Run from `system/kustomize/ipam-capi-remote-ddo/`:
```bash
python3 -c 'import sys; sys.path.insert(0,"tests"); import legacy_render as o; r=o.render("shoot--cp--m-qa-de-200"); print("SEED",sorted((d["kind"],d["metadata"]["name"]) for d in r["seed"])); print("SHOOT",sorted((d["kind"],d["metadata"]["name"]) for d in r["shoot"]))'
```
Expected: the oracle (legacy chart 1.2.37) seed set INCLUDES `ClusterRole`/`ClusterRoleBinding ipam-capi-remote-webhook-injector`; the oracle shoot set INCLUDES both leader-election pairs. Record whether each deleted identity is oracle-inventory (→ must be filtered from the `expected` set in `compare()`) or overlay-only (→ just lower the count). This disambiguates the Task 4 edits.

- [ ] **Step 3: Record the target counts**

Write the target end-state into the ledger: SEED 15→13 (drop injector ClusterRole+ClusterRoleBinding), SHOOT 25→21 (drop 4 leader-election objects). No commit.

---

### Task 1: Delete the dead webhook-injector seed ClusterRole + ClusterRoleBinding

**Files:**
- Modify: `additions/seed/webhook-injector-rbac.yaml` (remove doc-4 ClusterRole + doc-5 ClusterRoleBinding `ipam-capi-remote-webhook-injector`; keep doc-1 ServiceAccount + doc-2 Role + doc-3 RoleBinding)
- Test: `tests/seed_render_test.sh`

**Interfaces:**
- Consumes: Task 0 inventory.
- Produces: seed render with 13 objects; no `ClusterRole`/`ClusterRoleBinding` named `ipam-capi-remote-webhook-injector`.

- [ ] **Step 1: Add the failing assertions to `tests/seed_render_test.sh`**

Add checks: `kustomize build seed/` output contains `ServiceAccount`, `Role`, and `RoleBinding` named `ipam-capi-remote-webhook-injector`, and contains NO `ClusterRole` and NO `ClusterRoleBinding` named `ipam-capi-remote-webhook-injector`. (Match the existing grep/yaml assertion style in that file.)

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/seed_render_test.sh`
Expected: FAIL (the ClusterRole/ClusterRoleBinding still render).

- [ ] **Step 3: Delete the two docs from `additions/seed/webhook-injector-rbac.yaml`**

Remove only the `ClusterRole` and `ClusterRoleBinding` documents (the ones whose rules are `resources.gardener.cloud/managedresources` + core `secrets`, and the binding with the namespaceless subject). Leave the ServiceAccount, Role, and RoleBinding untouched.

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/seed_render_test.sh`
Expected: PASS. Also run `kustomize build seed/ | grep -c '^---$'` (document separators; sanity-check 13 objects).

- [ ] **Step 5: Commit**

```bash
git add additions/seed/webhook-injector-rbac.yaml tests/seed_render_test.sh
git commit -m "refactor(ipam-capi-remote-ddo): drop dead webhook-injector seed ClusterRole/ClusterRoleBinding"
```

---

### Task 2: Delete both redundant shoot leader-election RBAC pairs

**Files:**
- Modify: `shoot/rbac.yaml` (remove `ClusterRole ipam-capi-remote-leader-election-role` + `ClusterRoleBinding ipam-capi-remote-leader-election-rolebinding`)
- Modify: `shoot/legacy-support.yaml` (remove `ClusterRole ipam-capi-leader-election-role` + `ClusterRoleBinding ipam-capi-leader-election-rolebinding`; this leaves only the metrics Service — handled by the rename in Task 3)
- Test: `tests/render_test.sh`

**Interfaces:**
- Consumes: Task 0 inventory.
- Produces: shoot render with no `ipam-capi-leader-election-role`/`-rolebinding` and no `ipam-capi-remote-leader-election-role`/`-rolebinding`; shoot injector `ClusterRole ipam-capi-remote-webhook-injector` + both metal bindings still present.

- [ ] **Step 1: Add the failing assertions to `tests/render_test.sh`**

Add shoot-render checks: NO `ClusterRole`/`ClusterRoleBinding` named `ipam-capi-leader-election-role`/`ipam-capi-leader-election-rolebinding`/`ipam-capi-remote-leader-election-role`/`ipam-capi-remote-leader-election-rolebinding`; and (regression guard) still present: `ClusterRole ipam-capi-remote-webhook-injector`, `ClusterRoleBinding ipam-capi-metal-rolebinding`, `ClusterRoleBinding ipam-capi-metal-admin-rolebinding`.

- [ ] **Step 2: Run to verify it fails**

Run: `bash tests/render_test.sh`
Expected: FAIL (the leader-election objects still render).

- [ ] **Step 3: Delete the leader-election documents**

From `shoot/rbac.yaml` remove the `ipam-capi-remote-leader-election-role` ClusterRole and its `-rolebinding`. From `shoot/legacy-support.yaml` remove the `ipam-capi-leader-election-role` ClusterRole and its `-rolebinding` (both carried a meaningless `metadata.namespace: kube-system` — gone with them). Leave the metrics Service in `shoot/legacy-support.yaml` for now (Task 3 renames the file).

- [ ] **Step 4: Run to verify it passes**

Run: `bash tests/render_test.sh`
Expected: PASS. Also `kustomize build shoot/ | grep -c '^---$'` (document separators; sanity-check 21 objects).

- [ ] **Step 5: Commit**

```bash
git add shoot/rbac.yaml shoot/legacy-support.yaml tests/render_test.sh
git commit -m "refactor(ipam-capi-remote-ddo): drop redundant shoot leader-election RBAC (manager runs --leader-elect=false)"
```

---

### Task 3: De-"legacy" the file organization

**Files:**
- Create: `additions/seed/networkpolicies.yaml` (the 3 NetworkPolicies from `additions/seed/legacy-support.yaml`)
- Create: `additions/seed/manager-config.yaml` (the ConfigMap `ipam-capi-manager-config` from `additions/seed/legacy-support.yaml`)
- Delete: `additions/seed/legacy-support.yaml`
- Rename: `shoot/legacy-support.yaml` → `shoot/metrics-service.yaml` (now holds only the metrics Service after Task 2)
- Rename: `tests/legacy_render.py` → `tests/migration_render.py`
- Modify: `additions/seed/kustomization.yaml`, `shoot/kustomization.yaml`, `tests/migration_contract.py`, `tests/migration_contract_test.sh` (and any other test script importing the oracle), `README.md`

**Interfaces:**
- Consumes: the object bodies currently in the two `legacy-support.yaml` files (verbatim; only the file they live in changes).
- Produces: no `*legacy*` filenames or identifiers; identical render output to Task 2's end-state.

- [ ] **Step 1: Split and rename the overlay files**

Move the 3 NetworkPolicies verbatim into `additions/seed/networkpolicies.yaml` and the ConfigMap verbatim into `additions/seed/manager-config.yaml`; delete `additions/seed/legacy-support.yaml`. `git mv shoot/legacy-support.yaml shoot/metrics-service.yaml`. Update `additions/seed/kustomization.yaml` `resources:` (replace `legacy-support.yaml` with `networkpolicies.yaml` + `manager-config.yaml`) and `shoot/kustomization.yaml` `resources:` (replace `legacy-support.yaml` with `metrics-service.yaml`). Replace the "legacy" wording in the file header comments with "migration inventory".

- [ ] **Step 2: Rename the oracle module and fix references**

`git mv tests/legacy_render.py tests/migration_render.py`. Update the import in `tests/migration_contract.py` (and any test script) from `legacy_render` to `migration_render`. Update the README: drop the `<!-- seed-namespace-contract -->` section (no longer applicable after Task 1) and replace "legacy" references with "migration inventory".

- [ ] **Step 3: Verify no residual references and render is unchanged**

Run from `system/kustomize/ipam-capi-remote-ddo/`:
```bash
grep -rn 'legacy_render\|legacy-support\|legacy' . --include='*.py' --include='*.sh' --include='*.yaml' --include='*.md' ; echo "exit=$?"
kustomize build seed/  | python3 /tmp/dumpkeys.py | wc -l   # 13
kustomize build shoot/ | python3 /tmp/dumpkeys.py | wc -l   # 21
```
Expected: the grep prints only intentional mentions in the design/plan docs under `docs/` (or nothing in the overlay/tests); render counts 13/21 unchanged. (Note: `legacy_render.py`'s internal LEGACY chart commit constant may legitimately keep the word "legacy" in a variable name — acceptable; the filename and the user-facing "legacy-support" naming are what must go.)

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor(ipam-capi-remote-ddo): split legacy-support bundles into purpose-named files, rename oracle to migration_render"
```

---

### Task 4: Update the migration-fidelity contract + baseline for the intentional removals

**Files:**
- Modify: `tests/migration_contract.py`
- Modify: `tests/rbac_fidelity_test.sh`
- Regenerate: `tests/crd-baseline.json` (+ update its pinned sha256 literal in `tests/migration_contract.py`)

**Interfaces:**
- Consumes: Task 0 inventory (which deleted identities are oracle-inventory vs overlay-only); the end-state renders from Tasks 1–3.
- Produces: a green suite that asserts SEED 13 / SHOOT 21 and the absence of the deleted RBAC.

- [ ] **Step 1: Run the suite to see the expected failures**

Run from `system/kustomize/ipam-capi-remote-ddo/`: `bash tests/migration_contract_test.sh` and `bash tests/rbac_fidelity_test.sh`.
Expected: FAIL — `compare()` count mismatch (expects 15/25, now 13/21), `delivered()` asserting the seed injector ClusterRoleBinding, `historical_check` sha/baseline mismatch, and `rbac_fidelity` key-set mismatch.

- [ ] **Step 2: Update `migration_contract.py` `compare()` + `delivered()`**

- Change the seed count 15→13 and shoot count 25→21.
- Remove the `delivered()` seed-injector-ClusterRoleBinding assertion and the `namespace_patch()` machinery (Approach A removed that binding; there is no subject to patch). `delivered()` now just `place()`s seed at `cr.Namespace` and shoot at `kube-system`.
- Per Task 0's finding: for each deleted identity that is still emitted by the oracle, filter it out of the `expected` (oracle) inventory in `compare()` — mirror the existing `RESTORED` filtering pattern — so `actual.keys() == expected.keys()` holds. Add a short comment marking each as an intentional deviation (GRM-workaround leader-election; unused-mode injector ClusterRole).
- Drop `main()`'s second `compare(..., "ipam-alternate-seed")` call only if it exclusively exercised the namespace patch; otherwise keep it (it still validates generic namespace stamping of the kept namespaced objects).

- [ ] **Step 3: Update `historical_check` + regenerate `crd-baseline.json`**

- Remove the deleted identities from the `RESTORED` filter and from the pre-repair re-derivation (the seed injector ClusterRoleBinding `+kube-system` branch; any leader-election handling).
- Regenerate `tests/crd-baseline.json` from the new render using the same fingerprint logic (`crd_parity.py`), then update the pinned sha256 literal in `migration_contract.py` to the new file's hash. Record in the ledger that the baseline + pin were regenerated as a deliberate migration-fidelity-contract change.

- [ ] **Step 4: Update `negative_tests` and `rbac_fidelity_test.sh`**

- In `negative_tests`, remove any mutation case that references a now-deleted object (would raise `KeyError` instead of a clean assertion).
- In `rbac_fidelity_test.sh`, drop the two shoot leader-election identities from the expected key set so `actual.keys() == expected.keys()` holds; keep the one reviewed delta (shoot injector ClusterRole `OLD_RULES`→`NEW_RULES`).

- [ ] **Step 5: Run the full overlay suite**

Run from `system/kustomize/ipam-capi-remote-ddo/` — every `*_test.sh`:
```bash
for t in tests/*_test.sh; do echo "== $t =="; bash "$t" || break; done
```
Expected: all 9 tests PASS; seed render 13, shoot render 21.

- [ ] **Step 6: Commit**

```bash
git add tests/migration_contract.py tests/rbac_fidelity_test.sh tests/crd-baseline.json
git commit -m "test(ipam-capi-remote-ddo): assert intentional RBAC removals; regenerate pinned baseline"
```

---

## Notes for the builder

- **DDO prune behavior (verify, do not block):** confirm DDO prunes resources dropped from a render so the already-applied stale `ClusterRole`/`ClusterRoleBinding` objects get cleaned up on-cluster at the next reconcile. If DDO does not prune, note it in the final PR description as a manual cleanup step; it does not block the overlay change.
- **kube-secrets CR #5683:** no change (verified). Do not touch `feat/ipam-capi-remote-ddo-cr`.
- **CRD sourcing:** unchanged in this reorg (hybrid: pool remote git base + 3 core vendored). The flip to all-remote is a separate follow-up gated on DDO krusty-fetch.
- **Finish:** after the final whole-branch review, push `feat/ipam-capi-remote-ddo-m-qa-de-200` to update draft PR #13218; keep it draft (platform gates still pending).
