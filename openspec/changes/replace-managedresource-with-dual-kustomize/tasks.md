## 1. Pre-flight: dependency tracking and coordination

- [x] 1.1 Verify [SAP-cloud-infrastructure/webhook-injector#9](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9) status — has the `ca-rotation` mode been released? If not, this change can land in `master` but cannot be cut over to production until the new image is available. Document the gating in the PR description.
- [x] 1.2 Confirm with the parallel `cc/kube-secrets` OpenSpec change author (the kube-secrets-side coordinated change) that the per-cluster overlay restructure (`metal-operator-remote/host/` + `metal-operator-remote/remote/` subpaths) and the Concourse pipeline definition for the dual-step apply are tracked there. Cross-reference the OpenSpec change name in the kube-secrets repo.
- [x] 1.3 Verify webhook-injector is already deployed for all production `metal-operator-remote` clusters (`rt-eu-de-1`, `a-qa-de-200`, others if any). If a legacy non-sidecar deployment path exists for any cluster, plan an additional migration step before this change can ship.
- [x] 1.4 Audit the current kustomize tree for any GRM-era patches/transforms beyond the `Role → ClusterRole` conversion (e.g., resource-name munging, label injection in `wrap-managedresources.sh`). Document findings — they may need to be removed in this change too.

## 2. Webhook delivery restructure (two-layer kustomize)

- [x] 2.1 Create the inner-layer subdirectory `system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc/`.
- [x] 2.2 Write `upstream-no-svc/kustomization.yaml`: `resources:` references `https://github.com/ironcore-dev/metal-operator//config/webhook?ref=v0.4.0`; `patches:` contains a `$patch: delete` for the `Service` named `webhook-service` in namespace `system`.
- [x] 2.3 Verify inner layer build: `kustomize build system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc/` outputs ONLY a `ValidatingWebhookConfiguration` (no Service). Use `yq '.kind' | sort | uniq -c` to confirm.
- [x] 2.4 Create `system/kustomize/metal-operator-remote/remote/upstream/webhooks/system-namespace.yaml` defining a `Namespace` named `system`.
- [x] 2.5 Create `system/kustomize/metal-operator-remote/remote/upstream/webhooks/webhook-service-stub.yaml` defining a `Service` named `webhook-service` in namespace `system` with `spec.type: ExternalName` and `spec.externalName: metal-operator-webhook-service`.
- [x] 2.6 Rewrite the outer `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml`: `resources:` lists `upstream-no-svc/`, `system-namespace.yaml`, `webhook-service-stub.yaml`. Remove any `patches:` / `replacements:` / Makefile-related scaffolding.
- [x] 2.7 Verify outer layer build: `kustomize build system/kustomize/metal-operator-remote/remote/upstream/webhooks/` outputs `Namespace system`, `Service webhook-service` (ExternalName), and `ValidatingWebhookConfiguration` (with `clientConfig.service` form, no `caBundle`).
- [x] 2.8 Verify the caBundle invariant: `kustomize build .../webhooks/ | yq '.. | select(.caBundle? // "missing")'` returns empty.

## 3. Remote root composition

- [x] 3.1 Create or update `system/kustomize/metal-operator-remote/remote/kustomization.yaml` to compose `upstream/crds-and-rbac/`, `upstream/webhooks/`, and `custom/`. Confirm it produces a single self-contained kustomize root.
- [x] 3.2 Edit `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/kustomization.yaml` to remove the `Role → ClusterRole` and `RoleBinding → ClusterRoleBinding` conversion patches. Keep only the upstream Git URL ref + the Service exclusion patch.
- [x] 3.3 Verify CRDs+RBAC build: `kustomize build remote/upstream/crds-and-rbac/` produces upstream Roles as `kind: Role` (not ClusterRole). Use `yq 'select(.kind == "Role" or .kind == "RoleBinding") | .kind' | sort | uniq -c` to confirm.
- [x] 3.4 Verify full remote root build: `kustomize build remote/` produces 16 CRDs + 55 ClusterRoles + 10 ClusterRoleBindings + 2 ServiceAccounts + 1 Role + 1 RoleBinding (per upstream count) + Namespace `metal-servers` + Namespace `system` + Service `webhook-service` (ExternalName) + ValidatingWebhookConfiguration + custom Namespace + custom RBAC.
- [x] 3.5 Verify NO `kind: ManagedResource` or wrapping `Secret` in `kustomize build remote/` output: `yq '.kind' | grep -c ManagedResource` returns 0.

## 4. Host root: consolidate manager patches and restore args

- [x] 4.1 Create `system/kustomize/metal-operator-remote/host/base/manager-patch.yaml` consolidating the contents of the existing `manager-remote-patch.yaml` and `manager-webhook-patch.yaml`. Verify line-by-line that no field is dropped (env vars, volumes, volumeMounts, ports, securityContext, network labels, serviceAccountName, hostNetwork, resources).
- [x] 4.2 Add the 6 SAP-specific manager `args` to `manager-patch.yaml` (`--mac-prefixes-file=/etc/macdb/macdb.yaml`, `--probe-image=keppel.global.cloud.sap/ccloud-ghcr-io-mirror/ironcore-dev/metalprobe:latest`, `--probe-os-image=ghcr.io/ironcore-dev/os-images/gardenlinux:1443.3`, `--insecure=false`, `--registry-url=http://[2a10:afc0:e013:d002::]:30010`, `--manager-namespace=metal-operator-system`). Use `op: replace` on `/spec/template/spec/containers/0/args` semantic.
- [x] 4.3 Update `system/kustomize/metal-operator-remote/host/base/kustomization.yaml` `patches:` field to reference only `manager-patch.yaml` (remove `manager-remote-patch.yaml` and `manager-webhook-patch.yaml` entries).
- [x] 4.4 Delete the now-unused `system/kustomize/metal-operator-remote/host/base/manager-remote-patch.yaml` and `system/kustomize/metal-operator-remote/host/base/manager-webhook-patch.yaml`.
- [x] 4.5 Verify host base build: `kustomize build host/base/` produces a `Deployment` named `controller-manager` with all 6 SAP args + `--leader-elect` ABSENT (or whatever upstream sets, but at minimum the 6 SAP args present); env vars `KUBERNETES_SERVICE_HOST`, `KUBERNETES_CLUSTER_DOMAIN`, `KUBECONFIG`; volumes for `webhook-certs`, `remote-serviceaccount`, `remote-kubeconfig`, `macdb`; the webhook server port 9443.
- [x] 4.6 Verify host base build does NOT produce a `ConfigMap` named `webhook-config`: `kustomize build host/base/ | yq 'select(.kind == "ConfigMap" and .metadata.name == "webhook-config")'` returns empty.

## 5. Webhook-injector sidecar configuration for caBundle-rotation mode

- [x] 5.1 Edit `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml` (or equivalent) to set `WEBHOOK_INJECTOR_MODE=ca-rotation` env var (or the equivalent flag agreed with the binary maintainers in [webhook-injector#9](https://github.com/SAP-cloud-infrastructure/webhook-injector/issues/9)). Add a comment cross-referencing the issue.
- [x] 5.2 Update the sidecar's `--webhook-config-name` argument to point at the workerless `ValidatingWebhookConfiguration` name (`validating-webhook-configuration` per upstream). Add a comment noting that in `ca-rotation` mode this references the workerless resource (not a host-side ConfigMap).
- [x] 5.3 Update `system/kustomize/metal-operator-remote/host/base/webhook-injector-rbac.yaml`: narrow the host-side Role's verbs (drop ConfigMap read on `webhook-config` if present); ensure remote-cluster RBAC delivered via remote-kubeconfig is scoped to `get` and `patch` on `validatingwebhookconfigurations.admissionregistration.k8s.io` only (no broader verbs).
- [x] 5.4 Verify sidecar args in build output: `kustomize build host/base/ | yq 'select(.kind == "Deployment") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .env, .args'` shows `WEBHOOK_INJECTOR_MODE=ca-rotation` and the workerless WebhookConfiguration name.

## 6. Delete obsolete pre-render machinery

- [x] 6.1 Delete `system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml`.
- [x] 6.2 Delete `system/kustomize/metal-operator-remote/remote/upstream/webhooks/managedresources.yaml` (if not already deleted by Section 2's restructure).
- [x] 6.3 Delete `system/kustomize/metal-operator-remote/remote/upstream/webhooks/manifests-url-based.yaml` (if not already deleted by Section 2's restructure).
- [x] 6.4 Delete `system/kustomize/metal-operator-remote/host/base/webhook-config.yaml`.
- [x] 6.5 Delete `system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh`. If `scripts/` becomes empty, delete the directory.
- [x] 6.6 Edit `system/Makefile`: delete the `regen-metal-operator-remote`, `regen-metal-operator-remote-crds`, `regen-metal-operator-remote-webhooks` targets and the `KUSTOMIZE_METAL_OPERATOR_REMOTE` variable. Verify `make help` (or equivalent) still lists other operators' regen targets.
- [ ] 6.7 Update `system/kustomize/metal-operator-remote/VERIFICATION.md` to reflect the new structure (or note it's historical and out of scope per Open Question in brainstorm).

## 7. README and documentation

- [x] 7.1 Update `system/kustomize/metal-operator-remote/README.md`: document the `host` ≡ workload-cluster, `remote` ≡ workerless-cluster mapping; describe the dual-kustomize apply model; describe the new two-layer `remote/upstream/webhooks/` structure; note that the deployment pipeline lives in `cc/kube-secrets` (not in this repo).
- [x] 7.2 Add a "Removed in <date>" section to the README documenting what was removed in this change (Makefile targets, pre-rendered files, wrap script) and where the new mechanisms live (kustomize Git URL refs, ExternalName Service on workerless).
- [x] 7.3 Ensure the README's "Upgrade upstream metal-operator version" section reflects the new workflow: edit `?ref=` in three `kustomization.yaml` files (`host/base/`, `remote/upstream/crds-and-rbac/`, `remote/upstream/webhooks/upstream-no-svc/`), then `kubectl apply` (no regen step).

## 8. End-to-end validation against expected behavior

- [x] 8.1 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean.
- [x] 8.2 Build both roots independently:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /tmp/host.yaml
  kustomize build system/kustomize/metal-operator-remote/remote/ > /tmp/remote.yaml
  ```
  Both must succeed without errors.
- [x] 8.3 Resource categorization sanity check on `/tmp/host.yaml`: `yq '.kind' | sort | uniq -c` should show Deployment, Service (×2), Ingress, NetworkPolicy, ConfigMap, Secret (×3), ServiceAccount, Role, RoleBinding. NO ManagedResource, no `webhook-config` ConfigMap.
- [x] 8.4 Resource categorization sanity check on `/tmp/remote.yaml`: should show CustomResourceDefinition (×16), ClusterRole, ClusterRoleBinding, ServiceAccount, Role (≥1, un-converted), RoleBinding (≥1, un-converted), Namespace (×2: `metal-servers` + `system`), Service (×1: `webhook-service` ExternalName), ValidatingWebhookConfiguration. NO ManagedResource. NO `caBundle` field anywhere.
- [x] 8.5 caBundle absence check: `yq '.. | select(has("caBundle")) // empty' /tmp/remote.yaml` returns empty.
- [x] 8.6 ExternalName Service shape check: `yq 'select(.kind == "Service" and .metadata.namespace == "system")' /tmp/remote.yaml` shows `spec.type: ExternalName` and `spec.externalName: metal-operator-webhook-service`.
- [x] 8.7 Build a per-cluster overlay (against the in-flight kube-secrets coordinated change's branch) end-to-end:
  ```
  kustomize build <kube-secrets-branch>/values/kustomize/<test-cluster>/metal-operator-remote/host/  > /tmp/host-cluster.yaml
  kustomize build <kube-secrets-branch>/values/kustomize/<test-cluster>/metal-operator-remote/remote/ > /tmp/remote-cluster.yaml
  ```
  Both must succeed and incorporate per-cluster patches (image tags, OIDC group component, NetworkPolicy CIDRs).
- [x] 8.8 Compare host output against the helm-rendered output of the same cluster: `helm template metal-operator-remote system/metal-operator-remote --values <kube-secrets-helm-values-for-the-same-cluster>` filtered to host-cluster resources only. Expect functional equivalence (same kinds, names, specs) modulo Deployment name (`controller-manager` vs `metal-operator-controller-manager`) and minor structural differences. Document any divergence.
- [x] 8.9 Compare remote output against the helm-rendered ManagedResources unwrapped: workerless cluster should receive equivalent CRDs + RBAC + Namespace + ValidatingWebhookConfiguration content. The kustomize version uses `clientConfig.service` form whereas helm uses `clientConfig.url`; this is expected.

## 9. Pull request preparation (REUSE existing PR [#11633](https://github.com/sapcc/helm-charts/pull/11633))

The existing PR [`sapcc/helm-charts#11633`](https://github.com/sapcc/helm-charts/pull/11633) "poc(metal): kustomize-based resource splitting for metal-operator-remote" on branch `poc/kustomize-metal-operator-remote` already bundles two prior scopes (POC archive + move-cluster-overlays-to-kube-secrets). This change adds **Scope 3** to the same PR — no new branch, no new PR.

- [ ] 9.1 Verify branch is `poc/kustomize-metal-operator-remote` (PR #11633's branch). Confirm via `git branch --show-current` and `gh pr view 11633 --json headRefName`. The new commits from Sections 2-7 sit on top of the prior Scope 1 + Scope 2 commits.
- [ ] 9.2 Stage and commit all kustomize tree changes, Makefile edits, README updates, and OpenSpec change directory (already done per-task during Sections 2-8 — verify with `git log --oneline master..HEAD`).
- [ ] 9.3 Push to the existing remote branch:
  ```
  git push origin poc/kustomize-metal-operator-remote
  ```
  (No `-u` flag — branch already tracks `origin/poc/kustomize-metal-operator-remote`.)
- [ ] 9.4 **Update PR #11633's description to add a Scope 3 section** (instead of creating a new PR). Use:
  ```
  gh pr view 11633 --json body --jq .body > /tmp/pr-11633-body.md
  # Edit /tmp/pr-11633-body.md to insert a "## Scope 3 — Replace ManagedResource pipeline with dual-kustomize apply" section AFTER the existing Scope 2 section and BEFORE "How to verify locally"
  gh pr edit 11633 --body-file /tmp/pr-11633-body.md
  ```
  The Scope 3 section content is fully drafted in `plan.md` Step 9.3 — copy it verbatim. Covers: what changed (kustomize tree restructure, manager patches consolidation, sidecar mode, deletions, README updates), spec deltas (3 capabilities), validation results, pre-merge gates (kube-secrets coordinated PR + webhook-injector#9), apply order, cross-repo coordination references.
- [ ] 9.5 Verify reviewers and PR state. If reviewers from prior scopes are still appropriate, no change needed. Otherwise add controllers-team / sap-cc-platform-team handles via `gh pr edit 11633 --add-reviewer ...`. If pre-merge gates are unsatisfied, mark draft via `gh pr ready 11633 --undo`.
- [ ] 9.6 Add a comment summarizing the Scope 3 push for reviewers tracking the PR:
  ```
  gh pr comment 11633 --body "..."
  ```
  Comment body is drafted in `plan.md` Step 9.6 — covers the highlights (drop MR, two-layer webhook delivery, manager args, sidecar mode, Role→ClusterRole removal, Makefile cleanup) and the spec validation status.

## 10. Pre-merge final checks

- [x] 10.1 Re-run validation:
  ```
  cd /Users/D065300/IdeaProjects/sapcc/helm-charts
  openspec validate replace-managedresource-with-dual-kustomize --strict
  ```
  Expected: clean.
- [x] 10.2 Re-run kube-secrets per-cluster overlay builds against this branch (Task 8.7). Both must succeed.
- [ ] 10.3 Confirm coordinated kube-secrets PR is ready and reviewed; align merge timing.
- [x] 10.4 Confirm webhook-injector image with `ca-rotation` mode is published to `keppel.global.cloud.sap/ccloud-ghcr-io-mirror/SAP-cloud-infrastructure/webhook-injector`. If not yet available, the PR can merge to `master` but production cutover is gated.
- [x] 10.5 Confirm Concourse pipeline definition (in kube-secrets) is in `-OFF` state until cutover, mirroring the previous `move-cluster-overlays-to-kube-secrets` change's pattern.

## 11. Merge

- [ ] 11.1 Merge PR [#11633](https://github.com/sapcc/helm-charts/pull/11633) (the multi-scope PR, with all three scopes — Scope 1 POC archive, Scope 2 move-cluster-overlays, Scope 3 this change) after coordinated review. Coordinate timing with the kube-secrets coordinated change PR merge so both land within the same change window. Use `gh pr merge 11633 --squash --delete-branch` (or the maintainer's preferred merge strategy).
- [ ] 11.2 Verify on `master`:
  ```
  git checkout master && git pull --ff-only
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /tmp/host.yaml && echo OK
  kustomize build system/kustomize/metal-operator-remote/remote/ > /tmp/remote.yaml && echo OK
  test ! -f system/kustomize/metal-operator-remote/scripts/wrap-managedresources.sh && echo OK
  test ! -f system/kustomize/metal-operator-remote/remote/upstream/crds-and-rbac/managedresources.yaml && echo OK
  ```
  All four checks must print `OK`.

## 12. Archive the OpenSpec change

- [ ] 12.1 From the helm-charts repo on master:
  ```
  openspec archive replace-managedresource-with-dual-kustomize
  ```
  This applies the spec deltas to `openspec/specs/{kustomize-resource-splitting,kustomize-sidecar-injection,webhook-url-rendering}/spec.md` and moves the change directory under `openspec/changes/archive/<date>-replace-managedresource-with-dual-kustomize/`.
- [ ] 12.2 Verify the spec files were updated correctly:
  ```
  grep -c 'ManagedResource' openspec/specs/kustomize-resource-splitting/spec.md
  ```
  Expected: 0 (the requirement was removed).
- [ ] 12.3 `openspec validate --all --strict` from the repo root. Expected: clean.
- [ ] 12.4 Commit and push the archived change:
  ```
  git add openspec/
  git commit -m "chore(openspec): archive replace-managedresource-with-dual-kustomize

  Sync spec deltas to openspec/specs/{kustomize-resource-splitting,kustomize-sidecar-injection,webhook-url-rendering}/spec.md.

  Tracking: cc/unified-kubernetes#831"
  git push origin master
  ```

## 13. Hand-off and production cutover

- [ ] 13.1 Notify operators (in coordination with the kube-secrets coordinated change author): the helm-charts side of the dual-kustomize restructure is complete and merged. The kustomize-based pipelines in kube-secrets remain in `-OFF` state until per-cluster cutover (a separate runbook activity).
- [ ] 13.2 Document the cutover runbook in `cc/kube-secrets`: per-cluster steps to (a) deploy the new ValidatingWebhookConfiguration to workerless before turning off the old helm release, (b) flip the pipeline from `-OFF` to `-ON`, (c) verify `kubectl get vwc` on workerless shows the new config with caBundle populated, (d) verify the controller pod is running and admission validation works end-to-end.
- [ ] 13.3 Track follow-up: deletion of the now-obsolete helm chart `system/metal-operator-remote/` once all production clusters have cut over. This is a separate change.
- [ ] 13.4 Track follow-up: deletion of the now-empty `webhook-url-rendering` capability spec at `openspec/specs/webhook-url-rendering/` (after the archive applies the REMOVED requirements, the spec file has only its Purpose section). Decide whether to delete the directory entirely or leave as a vestigial placeholder. Capture as a small follow-up OpenSpec change.
- [ ] 13.5 Track follow-up: extract reusable scaffolding for boot/ipam/argora/khalkeon operators that share the same dual-host/remote pattern (per epic `cc/unified-kubernetes#831`). Whichever operator is tackled second should consider whether to publish a kustomize Component or a templated tree to avoid copy-paste.
- [ ] 13.6 Track follow-up: structured-auth migration (replacing Gardener-managed `serviceaccount.resources.gardener.cloud/*` annotations on `remote-serviceaccount-secret.yaml` and `rotate-kubeconfig-secret.yaml`). This is a separate workstream tracked in epic `cc/unified-kubernetes#831`'s "Solved" section.
- [ ] 13.7 Track follow-up: verify-phase Open Questions from the brainstorm (Deployment name mismatch helm vs kustomize, behavior under network partitions, cluster teardown procedure documentation). Decide whether each becomes a verify-phase test or a follow-up runbook addition.
- [ ] 13.8 Track follow-up: spec a pattern for fine-grained per-cluster overrides of ConfigMap/Secret content. Today kube-secrets overlays must replace whole `stringData` / `data` values when overriding placeholders embedded in multi-line YAML strings (e.g., `remote-kubeconfig` ConfigMap with `APISERVER_URL_PLACEHOLDER`, `metal-token-rotate-kubeconfig` Secret with `NAMESPACE_PLACEHOLDER`). Mechanisms explored during PR review: kustomize `replacements` (works on YAML paths, can't reach inside multi-line string values), `configMapGenerator` / `secretGenerator` with `behavior: merge` (works for structured top-level keys only), post-kustomize-build `envsubst` / Flux `postBuild.substituteFrom` (requires `${VAR}` placeholders to survive the kustomize build into the final output, then substitute at deploy boundary). Mechanism choice depends on (a) confirmed Concourse pipeline tooling — `kubectl` + `envsubst` shell pipeline, or `flux` CLI in the deploy image — and (b) Flux migration trajectory. Both unconfirmed. **Deferred** pending those clarifications; capture exploration in a separate OpenSpec change when ready. Affects multiple operators beyond metal-operator-remote — likely a cross-cutting capability.

## 14. Post-PR-push refactor: encapsulate sidecar-coupled resources in webhook-injector Component

This refactor was identified during PR [#11633](https://github.com/sapcc/helm-charts/pull/11633) review. Re-examining the provenance of the `metal-operator-webhook-injector` ServiceAccount confirms it was introduced FOR the sidecar feature in commit `9ffb1dc0c3` (Fabian Ruff, 2026-04-20: *"Add RBAC and service account for the webhook-injector sidecar"*). The Pod's `serviceAccountName` override on the manager Deployment exists only because the Pod hosts the sidecar — upstream's manager-only Deployment uses upstream's `controller-manager` SA. All sidecar-introduced host-side resources (SA + Role + RoleBinding + Pod-level SA assignment) SHALL therefore live inside `components/webhook-injector/` so that enabling/disabling the Component is an atomic toggle.

Chronology: this section runs AFTER Section 9 (PR prep, already complete) and BEFORE Section 11 (Merge). The new ADDED requirement in `specs/kustomize-sidecar-injection/spec.md` ("Webhook-injector Component encapsulates all sidecar-introduced resources") governs the end state.

- [x] 14.1 `git mv system/kustomize/metal-operator-remote/host/base/webhook-injector-rbac.yaml system/kustomize/metal-operator-remote/components/webhook-injector/webhook-injector-rbac.yaml`. Preserves git history.
- [x] 14.2 Edit `system/kustomize/metal-operator-remote/components/webhook-injector/kustomization.yaml`: add a `resources:` block listing `webhook-injector-rbac.yaml`. Component shape becomes: `resources` (the SA + Role + RoleBinding) + `patches` (the existing sidecar patch) + `images` (the existing image override).
- [x] 14.3 Edit `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`: add `spec.template.spec.serviceAccountName: metal-operator-webhook-injector` to the existing patch. The patch already targets the `controller-manager` Deployment to inject the initContainer; the SA-name override fits in the same hierarchy. No new patch file needed.
- [x] 14.4 Edit `system/kustomize/metal-operator-remote/host/base/manager-patch.yaml`: remove the `serviceAccountName: metal-operator-webhook-injector` line (currently at line 19, under `spec.template.spec`). All other fields (env, args, volumes, volumeMounts, ports, securityContext, network labels, hostNetwork, resources, strategy) MUST remain unchanged.
- [x] 14.5 Edit `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`: remove `webhook-injector-rbac.yaml` from the `resources:` list. The `components: [../../components/webhook-injector]` line ensures the Component (and its now-resident SA + Role + RoleBinding) is still composed.
- [x] 14.6 Verify build equivalence:
  ```bash
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /tmp/host-base-post-refactor.yaml
  diff <(yq -s '.' /tmp/host-base-pre-refactor.yaml | jq -S '. | sort_by(.kind, .metadata.name)') \
       <(yq -s '.' /tmp/host-base-post-refactor.yaml | jq -S '. | sort_by(.kind, .metadata.name)')
  ```
  Expected: empty diff (resource set is identical; only the source file location of webhook-injector-rbac changed).
- [x] 14.7 Verify `metal-operator-webhook-injector` no longer appears in any file under `host/`:
  ```bash
  grep -r "metal-operator-webhook-injector" system/kustomize/metal-operator-remote/host/ && echo "FAIL: should be empty" || echo "OK: no host-side references"
  ```
- [x] 14.8 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean (the new ADDED requirement in `kustomize-sidecar-injection/spec.md` covers the new file layout).
- [x] 14.9 Commit on `poc/kustomize-metal-operator-remote`. Use `git add` for the specific paths only (specs + kustomize tree files); no `git add -A`. Suggested message: `refactor(metal-operator-remote): encapsulate sidecar-coupled resources in webhook-injector Component`.
- [x] 14.10 Push to origin: `git push origin poc/kustomize-metal-operator-remote`.
- [x] 14.11 Update PR #11633 description's Scope 3 section with a 1–2 line note about the encapsulation refactor (the final structure: the Component owns ALL sidecar-introduced resources, atomic enable/disable). Apply via `gh pr edit 11633 --body-file ...`.

## 15. Post-PR-push refactor: absorb SAP-CC deployment-wide defaults

This refactor was identified during PR review as a follow-up: the kustomize base currently holds POC-era values for several manager args + an empty macdb. Verified empirically across all 6 SAP-CC `metal-operator-remote` deployments (`a-qa-de-200`, `rt-eu-de-1`, `rt-eu-de-2`, `rt-eu-de-3`, `rt-na-us-2`, `rt-qa-de-1`):

- **7 of 8 manager args byte-identical** (only `--registry-url` varies per cluster)
- **macdb structurally identical** (4 macPrefixes: Dell c4cbe1b1, Dell d08e79, Lenovo 0894ef, HPE 5ced8c — all Redfish/443/bmc; only the region token in vault refs varies)
- **Webhook-injector args**: production sidecar (live on `rt-eu-de-1`'s shoot) runs with `--webhook-config-name=metal-operator-remote-webhook-config`, `--leader-election-id=metal-operator-remote-webhook-injector-leader`, `--cert-secret-name=metal-operator-remote-cert-secret-name` — values to align in our base
- **Production cert SAN** (decoded from caBundle on `m-eu-de-1`'s VWC): `DNS:metal-operator-webhook-service` (single SAN, derived from URL form by binary auto-derivation)

Sidecar arg refactor uses webhook-injector PR #10 v2's label-based patch mode (binary release gated; existing PR #11633 cutover gating already covers this).

- [x] 15.1 Edit `system/kustomize/metal-operator-remote/host/base/manager-patch.yaml`: replace the `args` list with the 7 uniform SAP-CC defaults + `--registry-url=REGISTRY_URL_PLACEHOLDER`. Keep the rest of the patch (env, volumes, securityContext, etc.) unchanged.
- [x] 15.2 Edit `system/kustomize/metal-operator-remote/host/base/macdb-secret.yaml`: replace `stringData.macdb.yaml: '{}'` with the SAP-CC fleet vendor list (4 macPrefixes with `REGION_PLACEHOLDER` in vault refs). Verify YAML parses correctly via `yq eval '. | .stringData."macdb.yaml" | from_yaml | .macPrefixes | length' …` returning 4.
- [x] 15.3 Edit `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`: replace the `args` list to use webhook-injector PR #10 v2's flag scheme: `--webhook-label=webhook-injector.cloud.sap/managed=true`, `--cert-sans=metal-operator-webhook-service,webhook-service.system.svc,webhook-service.system.svc.cluster.local`, `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig`, `--leader-election-id=metal-operator-remote-webhook-injector-leader`, `--cert-secret-name=metal-operator-remote-cert-secret-name`. Remove `--webhook-config-name=validating-webhook-configuration` (replaced by `--webhook-label`).
- [x] 15.4 Edit `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml`: add a `patches:` block applying `op: add path: /metadata/labels value: {webhook-injector.cloud.sap/managed: "true"}` to the upstream `ValidatingWebhookConfiguration validating-webhook-configuration`.
- [x] 15.5 Verify build cleanliness: `kustomize build host/base/` succeeds; `kustomize build remote/` succeeds.
- [x] 15.6 Verify the new placeholders are present and findable in the host/base/ output: `grep -c REGISTRY_URL_PLACEHOLDER /tmp/host-base.yaml` ≥1; `grep -c REGION_PLACEHOLDER /tmp/host-base.yaml` ≥8 (4 macPrefixes × 2 vault refs each); `grep -c APISERVER_URL_PLACEHOLDER /tmp/host-base.yaml` ≥1 (existing, unchanged).
- [x] 15.7 Verify the new manager args are present: `grep -c metalprobe:v0.5.0`, `grep -c gardenlinux:1770.0`, `grep -c manager-namespace=metal-servers`, `grep -c enforce-first-boot`, `grep -c enforce-power-off` all ≥1.
- [x] 15.8 Verify old POC defaults are gone: `grep -c metalprobe:latest`, `grep -c metal-operator-system`, `grep -c gardenlinux:1443.3` all 0.
- [x] 15.9 Verify webhook-injector args: `grep webhook-label`, `grep cert-sans`, `grep leader-election-id`, `grep cert-secret-name` all present in build output; `grep webhook-config-name` is absent.
- [x] 15.10 Verify macdb populated: `grep -c "^      - macPrefix:" /tmp/host-base.yaml` returns 4.
- [x] 15.11 Verify VWC label patch: `kustomize build remote/ | yq 'select(.kind == "ValidatingWebhookConfiguration") | .metadata.labels."webhook-injector.cloud.sap/managed"'` returns `"true"`.
- [x] 15.12 Verify helm chart still renders (we did not break the helm path): `helm dep update system/metal-operator-remote/`, then `helm template metal-operator-remote system/metal-operator-remote/ -f /Users/D065300/IdeaProjects/sapcc/kube-secrets/values/helm/runtime/metal-operator-remote.yaml -f /Users/D065300/IdeaProjects/sapcc/kube-secrets/values/helm/runtime/eu-de-1/rt-eu-de-1/metal-operator-remote.yaml --namespace metal-operator-system --set global.region=eu-de-1` succeeds without templating errors.
- [x] 15.13 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean.
- [x] 15.14 Commit on `poc/kustomize-metal-operator-remote`. Use `git add` for the specific paths only; no `git add -A`. Suggested message: `refactor(metal-operator-remote): absorb SAP-CC deployment-wide defaults into kustomize base`.
- [x] 15.15 Push to origin: `git push origin poc/kustomize-metal-operator-remote`.
- [x] 15.16 Update PR #11633 description's Scope 3 section with the new defaults-absorption details (manager args restored to fleet values, macdb populated, sidecar args switched to PR #10 v2 flag scheme, VWC label patch). Apply via `gh pr edit 11633 --body-file ...`.
