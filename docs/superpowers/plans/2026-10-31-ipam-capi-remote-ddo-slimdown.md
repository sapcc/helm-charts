# ipam-capi-remote-ddo CRD sourcing slim-down Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace seven copied CRDs with immutable upstream references and small SAP conversion patches, preserving the delivered seed/shoot objects.

**Architecture:** Approach C: fetch the provider's four pool CRDs as a Git directory base and group three SHA-pinned CAPI HTTP file resources in a local core-CRDs kustomization. Keep the accepted RBAC/webhook/seed scope unchanged. Ship only after DDO's safe fetching covers both mechanisms.

**Tech Stack:** Kustomize v5.8.1, YAML, Bash, Python 3/PyYAML, DDO source.kustomize.

**Spec:** `docs/superpowers/specs/2026-10-31-ipam-capi-remote-ddo-slimdown-design.md` (approved by user; commit `67a1669042`).

## Global Constraints

- Overlay root remains `system/kustomize/ipam-capi-remote-ddo`; seedPath/shootPath remain `seed`/`shoot`. No Helm chart, kube-secrets edit, cutover edit, or controller/image upgrade.
- Provider v1.1.1 commit: `7933583138cf1b5b16b6a1dd82a804729f83afab`. CAPI v1.14.2 commit: `5f7d58c9ad647f31bd342bf8de33092c27f7fc38`. Pin commit SHAs, not tags or branches.
- Provider resource: `https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/crd?ref=7933583138cf1b5b16b6a1dd82a804729f83afab`.
- Core resources: `https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/` followed by `cluster.x-k8s.io_clusters.yaml`, `ipam.cluster.x-k8s.io_ipaddresses.yaml`, or `ipam.cluster.x-k8s.io_ipaddressclaims.yaml`. Do not use per-file Git bases or import the full CAPI directory (13 CRDs).
- Exactly seven CRDs remain: four pool CRDs plus `clusters.cluster.x-k8s.io`, `ipaddresses.ipam.cluster.x-k8s.io`, and `ipaddressclaims.ipam.cluster.x-k8s.io`.
- All four pools retain conversion strategy `Webhook`, review versions `[v1]`, URL `https://ipam-capi-remote-webhook-service:443/convert`, and the existing caBundle. Patches explicitly set `clientConfig.service: null`.
- Keep the four pool move-hierarchy labels (empty strings); core CRDs retain their existing metadata and schemas. Preserve the split controller-gen stamps (pool v0.17.2, core v0.21.0).
- `shoot/rbac.yaml`, `shoot/webhooks.yaml`, seed resources, and the unreferenced pool example remain unchanged. Preserve cross-operator metal bindings and controller bindings.
- Do not merge or activate until DDO issue #58 support is released and deployed, covering both Git directory bases and HTTP file resources with cache/offline-build behavior. A CLI build is not evidence of DDO support.

## Review Focus

- Loss or expansion of the CRD inventory: assert the exact seven names and full canonical-content fingerprints (Tasks 1–2).
- Conversion service and URL coexist, or CA changes: assert URL-only conversion and exact CA fingerprints on all four pools (Task 2).
- Mutable or unsupported remote references: test exact approved SHA URLs, and no full-CAPI or per-file Git resource (Task 2).
- Parity gate silently skipped after copied files disappear: use tracked compact fingerprints, fail on missing baseline, exercise negative mutations (Tasks 1–3).
- Fresh build mistaken for warm-cache offline support: separate online CLI evidence from DDO cold-cache/warm-cache and fetch-failure evidence (Task 3).

---

## File structure and execution preflight

All paths below are relative to the overlay root unless explicitly prefixed with `docs/`.

- `tests/crd-baseline.json`: seven names, canonical SHA-256 fingerprints of the current normalized CRDs, and fingerprints of unchanged seed/shoot objects. No copied schemas or duplicated CRD YAML.
- `tests/crd_parity.py`: canonicalization and parity assertions, used by `tests/crd_diff_test.sh` and its negative tests.
- `shoot/core-crds/kustomization.yaml`: the three approved HTTP references.
- `shoot/patches/conversion-{globalinclusterippools,globalinclusterprefixpools,inclusterippools,inclusterprefixpools}.yaml`: four small strategic-merge patches.
- `shoot/kustomization.yaml`: replace seven file references with provider base plus `core-crds`; use modern `patches:` entries with `path:` for the four patches.
- Delete only `shoot/crds/{clusters,ipaddresses,ipaddressclaims,globalinclusterippools,globalinclusterprefixpools,inclusterippools,inclusterprefixpools}.yaml`.
- Update `tests/crd_diff_test.sh` and `README.md`; add `tests/remote_sources_test.sh` and `tests/crd_parity_test.sh`.

Before execution, verify an isolated feature workspace and record the full pre-refactor Git SHA. This is a follow-up to PR #13218, not a stacked PR or an automatic update of that migration PR. Do not merge/push/activate as part of planning.

Resolve two spec ambiguities without changing behavior: keep move-hierarchy labels (rather than the contradictory drop wording in §5.2), and preserve the captured CA bytes without claiming that self-signed issuer CN proves a universal CA. If evidence requires a different CA or schemas at the approved pins differ, stop and report the mismatch; do not silently weaken parity or change the pins.

### Task 1: Make CRD fidelity independent of disposable live captures

**Files:** Create `tests/crd_parity.py`, `tests/crd_parity_test.sh`, `tests/crd-baseline.json`; modify `tests/crd_diff_test.sh`.

**Interfaces:** `python3 tests/crd_parity.py <shoot-render.yaml> <seed-render.yaml> <baseline.json>` returns 0 only for exact normalized inventory/content parity, otherwise nonzero with differing object identities. Produces the compact baseline consumed by Task 2.

- [ ] **Step 1: Write failing parity tests.** From temporary fixture manifests, assert: unchanged inputs pass; changed schema, missing CRD, added eighth CRD, changed caBundle, and missing baseline each fail. Baseline generation must be explicit, never an automatic fallback during test execution.
- [ ] **Step 2: Run RED.** `bash tests/crd_parity_test.sh` must fail because the parity utility is absent.
- [ ] **Step 3: Implement canonicalization and capture the pre-refactor baseline.** Load YAML, ignore document order and mapping-key order; apply only the current test's server metadata/status and Gardener/Helm delivery-artifact normalization. Preserve all schema fields, arrays, names, labels, annotations, and CA bytes. Hash deterministic JSON per `(apiVersion, kind, namespace, name)`; detect duplicate identities. Capture fingerprints from both current renders before changing sources and cross-check CRD fingerprints against the seven current files. Record the full source Git SHA and the two upstream pins in the baseline.
- [ ] **Step 4: Use the baseline unconditionally.** Replace the vendored-file dependency in `crd_diff_test.sh` with the utility. Preserve unconditional seven-name, stamp, and label assertions. Optional live captures may provide extra evidence, but their absence cannot skip the tracked-baseline comparison. No runtime baseline regeneration.
- [ ] **Step 5: Verify GREEN.** Run `bash tests/crd_parity_test.sh` and `bash tests/crd_diff_test.sh`. Both return 0; each negative mutation returns nonzero. Save evidence of baseline provenance in the task report.
- [ ] **Step 6: Commit the focused fidelity gate.** Stage only these four files; commit `test(ipam-capi-remote-ddo): preserve compact pre-refactor render fingerprints`.

### Task 2: Swap copied CRDs for pinned sources and SAP conversion patches

**Files:** Create `shoot/core-crds/kustomization.yaml`, four `shoot/patches/conversion-*.yaml`, and `tests/remote_sources_test.sh`; modify `shoot/kustomization.yaml`; delete the seven enumerated copied CRD files.

**Interfaces:** Consumes Task 1's unchanged baseline and parity command. Produces `kustomize build shoot/` with exactly the same normalized objects as before, fetched through two remote-loader mechanisms.

- [ ] **Step 1: Write failing source-contract tests.** Assert exact provider directory URL, exact three HTTP URLs grouped under `core-crds`, no `shoot/crds/*.yaml` references/files, no extra remote sources, four patch paths, and `service: null` in each patch. Each patch targets its corresponding full pool-CRD name and contains the exact conversion URL, `[v1]`, and the baseline's matching CA bytes. Assert neither RBAC nor webhook sourcing changed.
- [ ] **Step 2: Run RED.** `bash tests/remote_sources_test.sh` fails on the existing seven copied files and absent remote wiring.
- [ ] **Step 3: Extract the shim before deleting source files.** Copy the exact caBundle from each existing pool CRD into its small conversion patch; verify all four bytes agree. Include `apiVersion: apiextensions.k8s.io/v1`, `kind: CustomResourceDefinition`, the full metadata.name, `strategy: Webhook`, and the exact clientConfig/service-null contract. Keep patches limited to SAP conversion deltas, not schema bodies or upstream metadata.
- [ ] **Step 4: Wire Approach C.** Add the provider directory resource and local `core-crds` resource where the seven copied file entries were; retain `../base`, `../additions/shoot`, `rbac.yaml`, and `webhooks.yaml`. Write the three exact core HTTP resources. Add modern `patches:` path entries. Delete only the seven copied CRDs.
- [ ] **Step 5: Verify GREEN and full render fidelity.** Run `bash tests/remote_sources_test.sh` and `bash tests/crd_diff_test.sh`. Render both modes; assert all four pool clientConfigs have URL and no service, CA bytes match the baseline, and core CRD specs match baseline. All unchanged seed/shoot fingerprints must still match. A mismatch at the approved CAPI pin is a blocker, not permission to omit fields or re-record the baseline.
- [ ] **Step 6: Commit the source swap.** Stage only the declared source/patch/test changes and deletions; commit `refactor(ipam-capi-remote-ddo): source seven CRDs from immutable upstream pins`.

### Task 3: Verify integration, document maintenance, and enforce the release gate

**Files:** Modify `README.md`; extend `tests/crd_parity_test.sh` or `tests/remote_sources_test.sh` only where required for the negative checks below. No production resource changes.

**Interfaces:** Consumes Task 2's final source layout. Produces a documented version-bump procedure and a verification report distinguishing CLI and deployed-DDO evidence.

- [ ] **Step 1: Add missing negative checks first.** Mutations must reject replacing either SHA with a tag, importing CAPI's full `core/config/crd`, leaving service alongside URL, removing a conversion patch, and modifying a baseline fingerprint without explicit baseline review. Run each new check against its bad fixture and record nonzero exits.
- [ ] **Step 2: Verify GREEN on the real tree.** Run `bash tests/crd_parity_test.sh` and `bash tests/remote_sources_test.sh`; all fixture assertions pass and the production layout passes. Do not add a second copied CRD bundle as a fixture.
- [ ] **Step 3: Update README.** Document two upstream origins, release-tag-to-commit provenance, the raw-HTTP versus Git-directory distinction, four SAP conversion patches, retained RBAC/webhook/seed scope, and the accepted maximize-upstream audit. Replace copied-file/local-capture-only instructions with the mandatory fingerprint gate. Upstream upgrades require intentional fingerprint review, never blind baseline refresh.
- [ ] **Step 4: Run the full operand suite once after reconciliation.** From the overlay root: `for t in tests/*_test.sh; do bash "$t" || exit; done`. Require all scripts to exit 0, including render, CRD, RBAC, no-pool, seed, webhook, parity, and remote-source gates. Record normalized counts and the line-count reduction; do not promise exactly 79% after adding tests/patches.
- [ ] **Step 5: Record DDO release acceptance separately.** With issue #58's implementer/operator evidence, identify the released build and verify both source mechanisms: cold-cache successful fetch, warm-cache render with outbound network blocked, unavailable uncached source failing closed, and deterministic repeated output. A fresh CLI checkout needs network; offline output requires a populated DDO cache. Without this evidence, mark shipping BLOCKED, not complete, and leave the refactor unactivated. Do not mutate live clusters to obtain evidence without approval.
- [ ] **Step 6: Commit docs and any focused test hardening.** Commit `docs(ipam-capi-remote-ddo): document upstream pins and DDO remote-fetch release gate`.

## Final review and integration

Require a whole-change review of source wiring, exact seven-CRD parity, service-null conversion semantics, unchanged RBAC/seed resources, and release-gate evidence. Fix blocking findings before integration. User's execution-time decision: fold this into existing PR #13218 and mark it draft/blocked, rather than opening a separate or stacked PR. Keep kube-secrets PR #5683 draft and aligned; retain both default webhook-label transformations when per-cluster lists replace defaults. Do not merge or activate until the required DDO remote-fetch release and the admin chart's source.kustomize delivery support are released/deployed.

## Self-review

Spec coverage: CRD removal/source pins/shim are Task 2; unchanged-resource fidelity is Tasks 1–2; negative and release gates plus maintenance docs are Task 3. All interfaces and file paths are explicit. Every Review Focus item has an owning check. Deliberately retain the approved CRD-only scope; general upstream RBAC/webhook/Deployment refactoring is not hidden in this plan.
