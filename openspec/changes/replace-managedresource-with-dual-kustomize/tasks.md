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

## 16. Pivot to PR-10-v2 patch mode with admission-webhook bootstrap (Option B)

This section captures a substantive architectural pivot identified during cross-repo review of [`SAP-cloud-infrastructure/webhook-injector#10`](https://github.com/SAP-cloud-infrastructure/webhook-injector/pull/10) v2 by inspecting the actual code at HEAD `06b512f` of branch `optional-webhook-config-and-crd-patching`. Two findings force the pivot:

1. **`--external-host` is mandatory in patch mode.** The binary's `cmd/webhook-injector/main.go` enforces `os.Exit(1)` when patch mode is active and `--external-host` is empty. Our previous design (caBundle-only patch mode without `--external-host`) cannot boot the new binary. Code reference: `cmd/webhook-injector/main.go` ~L130-L142.

2. **PR-10-v2 introduces an admission-webhook bootstrap mechanism that solves a GitOps reconciliation problem we hadn't fully grappled with.** Our previous design relied on an `ExternalName` Service in the workerless cluster's `system` namespace (`webhook-service` → `metal-operator-webhook-service`) to bridge upstream's `clientConfig.service` form to the host cluster's actual webhook service via DNS search paths. ExternalName for webhook clientConfig is rejected by Gardener's default `--enable-aggregator-routing=true` (see [k3s-io/k3s#6659](https://github.com/k3s-io/k3s/issues/6659)) — so ExternalName routing was already a latent risk. The pivot replaces ExternalName routing with admission-time Service→URL rewrite: the sidecar bootstraps `metal-operator-webhook-injector-mutator` on the workerless cluster, the mutator rewrites `clientConfig.Service` → `clientConfig.URL` synchronously at admission time, and the workerless API server stores URL form for callbacks. Reapply idempotency is preserved (admission rewrites before validation, so 3-way-merge re-introductions of the Service field are sanitized in-flight).

**Trade-off accepted:** the host cluster's `metal-operator-webhook-service` Service grows a second exposed port (9444 → sidecar admission server), and `cc/kube-secrets` widens the remote-kubeconfig RBAC to allow `mutatingwebhookconfigurations` `create` so the sidecar can bootstrap the admission webhook. Both are mechanical changes consistent with the existing architecture (same network path, same DNS resolution, same RBAC delivery model).

**Bootstrap-window risk:** on a fresh install of a new workerless cluster, the order between `host/` apply (brings up sidecar → bootstraps admission webhook) and `remote/` apply (delivers the labeled VWC) matters. If `remote/` lands first, the metal3 VWC enters the workerless apiserver in Service form pointing at an endpointless ClusterIP, and the upstream `failurePolicy: Fail` setting (× 7 webhook entries — BiosSettings, BiosVersion, BmcSecret, BmcSettings, BmcVersion, Endpoint, Server) blocks all metal3 CRD writes until the periodic reconcile recovers (up to one `--sync-period`). This is non-catastrophic (auto-recovery) but ugly. Mitigation is enforced via a Concourse pipeline gate task in `cc/kube-secrets` (Section 16.13–16.15 below) — out of scope for this repo, captured as a coordination note.

### Tasks

- [x] 16.1 Edit `system/kustomize/metal-operator-remote/host/base/webhook-service.yaml`: add a second port entry `name: admission, port: 9444, protocol: TCP, targetPort: 9444` after the existing `webhook` port. Verify the existing webhook port retains `port: 443, targetPort: 9443` and gains an explicit `name: webhook`.

- [x] 16.2 Edit `system/kustomize/metal-operator-remote/components/webhook-injector/sidecar.yaml`:
  - Replace the `--cert-sans` value with the single entry `metal-operator-webhook-service` (drop `webhook-service.system.svc` and `webhook-service.system.svc.cluster.local`).
  - Append four new args after `--cert-secret-name`:
    - `--external-host=metal-operator-webhook-service`
    - `--external-port=443`
    - `--admission-webhook-name=metal-operator-webhook-injector-mutator`
    - `--admission-external-port=9444`
  - Add a third entry to the `ports:` list under the webhook-injector initContainer: `name: admission, containerPort: 9444`.

- [x] 16.3 Delete `system/kustomize/metal-operator-remote/remote/upstream/webhooks/webhook-service-stub.yaml` (the ExternalName Service is no longer used).

- [x] 16.4 Delete `system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc/` (entire directory — the Service-strip workaround is no longer needed; we consume upstream's VWC manifest directly).

- [x] 16.5 Delete `system/kustomize/metal-operator-remote/remote/upstream/webhooks/system-namespace.yaml`. With upstream's Service object no longer being applied (we reference only `manifests.yaml`, not the whole `config/webhook/` directory), no resource on the workerless cluster needs the `system` namespace to exist. The VWC's `clientConfig.service.namespace: system` field is harmless because it is replaced with URL form by admission rewrite before any callback fires; K8s does not validate Service existence at VWC apply time.

- [x] 16.6 Edit `system/kustomize/metal-operator-remote/remote/upstream/webhooks/kustomization.yaml`:
  - Replace the `resources:` list contents with the single entry `- https://github.com/ironcore-dev/metal-operator//config/webhook/manifests.yaml?ref=v0.4.0` (the VWC manifest file directly, NOT the directory URL — the directory URL would re-pull `service.yaml`).
  - Remove the `- upstream-no-svc/`, `- system-namespace.yaml`, and `- webhook-service-stub.yaml` entries.
  - Keep the `webhook-injector.cloud.sap/managed: "true"` label patch on the VWC.
  - The resulting `webhooks/` directory contains a single file: `kustomization.yaml`.

- [x] 16.7 Verify build cleanliness: `kustomize build system/kustomize/metal-operator-remote/host/base/` and `kustomize build system/kustomize/metal-operator-remote/remote/` both succeed.

- [x] 16.8 Verify the host Service has the new admission port:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ \
    | yq 'select(.kind == "Service" and .metadata.name == "metal-operator-webhook-service") | .spec.ports'
  ```
  Expected: two entries, one with `port: 443` and one with `port: 9444`, both with explicit `name:` fields.

- [x] 16.9 Verify the sidecar args contain the four new flags:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ \
    | yq 'select(.kind == "Deployment" and .metadata.name == "controller-manager") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .args'
  ```
  Expected: includes `--external-host=metal-operator-webhook-service`, `--external-port=443`, `--admission-webhook-name=metal-operator-webhook-injector-mutator`, `--admission-external-port=9444`. The `--cert-sans` value is exactly `metal-operator-webhook-service` (no `.svc` variants).

- [x] 16.10 Verify the sidecar containerPorts include `9444`:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ \
    | yq 'select(.kind == "Deployment") | .spec.template.spec.initContainers[] | select(.name == "webhook-injector") | .ports'
  ```
  Expected: three entries (`metrics: 8082`, `health: 8083`, `admission: 9444`).

- [x] 16.11 Verify the workerless VWC ships in upstream Service form (build-time invariant; runtime form is set by admission):
  ```
  kustomize build system/kustomize/metal-operator-remote/remote/ \
    | yq 'select(.kind == "ValidatingWebhookConfiguration") | .webhooks[].clientConfig'
  ```
  Expected: every entry has a `service: { name, namespace, path }` field, and no entry has a `url` field. (This is the `kustomize-resource-splitting / Webhook delivery via Service→URL rewrite at admission time` requirement's build-time scenario.)

- [x] 16.12 Verify the VWC management label is preserved (existing requirement, regression check):
  ```
  kustomize build system/kustomize/metal-operator-remote/remote/ \
    | yq 'select(.kind == "ValidatingWebhookConfiguration") | .metadata.labels."webhook-injector.cloud.sap/managed"'
  ```
  Expected: `"true"`.

- [x] 16.13 Verify ExternalName + system-namespace + upstream-Service artifacts are all gone:
  - `! test -f system/kustomize/metal-operator-remote/remote/upstream/webhooks/webhook-service-stub.yaml`
  - `! test -f system/kustomize/metal-operator-remote/remote/upstream/webhooks/system-namespace.yaml`
  - `! test -d system/kustomize/metal-operator-remote/remote/upstream/webhooks/upstream-no-svc/`
  - `kustomize build system/kustomize/metal-operator-remote/remote/ | yq 'select(.kind == "Service")'` returns empty (no upstream `webhook-service` Service object in the build output).
  - `kustomize build system/kustomize/metal-operator-remote/remote/ | yq 'select(.kind == "Namespace" and .metadata.name == "system")'` returns empty.

- [x] 16.14 Document the cross-repo coordination note for `cc/kube-secrets` in this PR's description (and capture it in `design.md` Step 16 once that file is updated). The note SHALL cover:
  1. **RBAC widening**: the remote-kubeconfig identity needs `mutatingwebhookconfigurations` `create,get,list,watch,update,patch` (in addition to the existing `validatingwebhookconfigurations` `get,patch`). Recommended approach: consume upstream `https://github.com/SAP-cloud-infrastructure/webhook-injector//config/rbac.yaml?ref=<tag>` and override the binding's `.subjects` list. Drop upstream's host-side SA/Role/RoleBinding (irrelevant on workerless).
  2. **Pipeline gate**: insert a wait task between the `host/` apply job and the `remote/` apply job that polls for the bootstrapped admission MWC on the workerless cluster:
     ```
     kubectl --kubeconfig=$REMOTE_KUBECONFIG \
       wait --for=jsonpath='{.metadata.name}'=metal-operator-webhook-injector-mutator \
       mutatingwebhookconfiguration/metal-operator-webhook-injector-mutator \
       --timeout=5m
     ```
     This gate is idempotent (instant-return on subsequent runs once the MWC exists) and protects fresh-install fleet additions from the bootstrap-window failure mode described above.

- [x] 16.15 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean. (The spec deltas in `specs/kustomize-resource-splitting/spec.md` and `specs/kustomize-sidecar-injection/spec.md` have been updated in-place to describe the admission-webhook-bootstrap architecture; the previous ExternalName-routing requirements are removed.)

- [x] 16.16 Update `design.md` and `proposal.md` to reflect the architectural pivot:
  - `proposal.md` "What changes" section: replace the ExternalName-routing description with admission-webhook-bootstrap.
  - `design.md`: add a new top-level section "Why admission-webhook bootstrap, not ExternalName" referencing PR-10-v2's Q1 finding (`--external-host` mandatory, code @ `06b512f`) and k3s#6659 (ExternalName latent risk on Gardener).

- [x] 16.17 Commit on `poc/kustomize-metal-operator-remote`. Use `git add` for the specific paths only; no `git add -A`. Suggested message: `refactor(metal-operator-remote): pivot to PR-10-v2 admission-webhook bootstrap`. Push to origin.

- [x] 16.18 Update PR #11633 description's Scope 3 section: replace the ExternalName-routing paragraph with the admission-webhook-bootstrap paragraph; mention the cc/kube-secrets coordination note (RBAC widening + pipeline gate); update the cutover-gating paragraph if the gating reasoning has shifted (now also gated on cc/kube-secrets pipeline gate task being merged, in addition to the webhook-injector binary release).

## 17. Close helm-vs-kustomize equivalence gaps (post-PR-review finding)

This section captures gaps found by rendering the helm chart with `cc/kube-secrets`'s `a-qa-de-200`/k3s-admin values and diffing against `kustomize build host/base/`. Only **fleet-uniform** gaps belong here per the OQ10 transitivity argument applied to webhook-injector RBAC absorption (Section 16). Per-cluster operational decisions (image SHA selection) are out of scope for this section.

### Gap inventory (verified 2026-06-05)

| # | Gap | Disposition |
|---|---|---|
| 1 | Kustomize renders **1** NetworkPolicy; helm renders **5**. 4 NPs missing in kustomize: `metalapi-egress-to-ingress-nginx-controller-tcp-443`, `metalapi-ingress-from-kube-apiserver-9443`, `kube-apiserver-egress-to-metalapi`, `metalapi-ingress-from-kube-monitoring`. All fleet-uniform (no per-cluster values; verified by reading `system/metal-operator-remote/templates/networkpolicy.yaml`). | **fix in this repo** |
| 2 | The 1 NP that exists in kustomize lacks `spec.policyTypes`. K8s defaults to `["Ingress"]` when only Ingress rules are present (functionally equivalent), but explicit form is the helm chart's pattern and best-practice. | **fix in this repo** |
| 3 | Pod selector label mismatch: kustomize `app.kubernetes.io/name: metal-operator` vs helm `app.kubernetes.io/name: metal-operator-remote` (chart-fullname-prefixed). Internal consistency in the kustomize stack is preserved; mismatch only matters at cutover transition. | **decision required** (see 17.2 below) |
| 4 | Deployment name mismatch: kustomize `controller-manager` vs helm `metal-operator-controller-manager`. Same root cause as #3. | **decision required** (see 17.2 below) |
| 5 | Manager image SHA divergence (helm pin vs cc/kube-secrets per-cluster overlay pin). The kustomize base ships `:PLACEHOLDER` (literal) which the kube-secrets `images:` block substitutes per-cluster — this is correct architecture. The divergence observed is an operational artifact (which SHA to roll forward with), not a code gap. | **no code change** (operator decision, runbook material) |
| 6 | `metal-operator-remote-webhook-config` ConfigMap eliminated in kustomize. | **already correct** (Section 5) |
| 7 | webhook-injector Role rule `configmaps: get,list,watch` dropped in kustomize. | **already correct** (Section 5) |

### Tasks

- [x] 17.1 Add a new ADDED Requirement `Host base produces fleet-uniform NetworkPolicies for the manager Pod` to `specs/kustomize-resource-splitting/spec.md`. The requirement SHALL specify that the kustomize host base renders the same 5 NetworkPolicies that the helm chart renders (the existing `metalapi-ingress-to-metal-operator-metal-registry-service-tcp-10000` plus the 4 listed above), every NP SHALL declare `spec.policyTypes` explicitly, and the policies SHALL be fleet-uniform (no per-cluster value substitution required).

- [x] 17.2 **Decision: pod selector labels and Deployment name (items 3 + 4).** Choose ONE of:
  - **(a) Bridge with `commonLabels`** — Add `commonLabels: { app.kubernetes.io/name: metal-operator-remote }` to `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`. Keeps the kustomize-applied Service/NPs matching the helm-deployed Pod labels during cutover; eliminates orphan-endpoint risk (kustomize Service has zero endpoints if helm-deployed pods are still labeled `metal-operator-remote`). Requires a future cleanup commit post-cutover to drop the override and adopt upstream's bare name. Safer cutover, more long-term cruft.
  - **(b) Accept the rename + cutover runbook** — Keep the kustomize tree's bare name `metal-operator`. Document a tested cutover runbook in `cc/kube-secrets`: `kubectl scale deployment metal-operator-controller-manager --replicas=0` (helm-deployed) → `kubectl apply -k host/` (kustomize) → wait for kustomize Pods Ready (with new labels) → `kubectl apply -k remote/` → `helm uninstall metal-operator-remote`. Cleaner long-term naming, requires a tested runbook + maintenance window.
  - **(c) Bridging selector** — Service+NP selectors temporarily match both sets via `matchExpressions: [{key: app.kubernetes.io/name, operator: In, values: [metal-operator, metal-operator-remote]}]`. Most flexible but most temporary kustomize cruft.

  Document the choice in `design.md` (new section "Helm-vs-kustomize equivalence gap analysis" — see 17.8). Encode the consequence in `tasks.md` 17.3-17.5 below.

- [x] 17.3 (depends on 17.2 choice) Port the 4 missing NetworkPolicies into a new `system/kustomize/metal-operator-remote/host/base/networkpolicies.yaml` (or split into per-NP files for review clarity). The `podSelector.matchLabels` SHALL match whichever pod label scheme is chosen in 17.2 (option a → `app.kubernetes.io/name: metal-operator-remote, control-plane: controller-manager`; option b → `app.kubernetes.io/name: metal-operator, control-plane: controller-manager`; option c → use upstream's bare name and rely on `commonLabels` not being set).

- [x] 17.4 Edit the existing `system/kustomize/metal-operator-remote/host/base/networkpolicy.yaml` to add `spec.policyTypes: [Ingress]` to the existing `metalapi-ingress-to-metal-operator-metal-registry-service-tcp-10000` policy. Update its `podSelector.matchLabels` per 17.2 if the chosen option requires it.

- [x] 17.5 Add the new `networkpolicies.yaml` to `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`'s `resources:` list. (And, if option (a) was chosen in 17.2, add the `commonLabels:` block.)

- [x] 17.6 Verify `kustomize build host/base/` produces exactly 5 NetworkPolicies, each with explicit `spec.policyTypes`:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ \
    | yq -N 'select(.kind == "NetworkPolicy") | .metadata.name + " | policyTypes=" + (.spec.policyTypes | tostring)'
  ```
  Expected: 5 lines, every line ends with `policyTypes=[Ingress]` or `policyTypes=[Egress]` (no `[ABSENT]`).

- [x] 17.7 Verify pod-selector consistency:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ \
    | yq -N 'select(.kind == "NetworkPolicy" or .kind == "Service") | .metadata.name + " | " + (.spec.podSelector.matchLabels // .spec.selector | tostring)' \
    | sort -u
  ```
  Expected: every entry matches the pod label scheme chosen in 17.2 (with the exception of `kube-apiserver-egress-to-metalapi` whose `podSelector` targets the apiserver pod, not the manager pod).

- [x] 17.8 Add a new section "Helm-vs-kustomize equivalence gap analysis" to `design.md` documenting the 7-item gap inventory, the disposition table, and the chosen option for 17.2 with rationale.

- [x] 17.9 Update `proposal.md` "What changes" section briefly mentioning the additional 4 NetworkPolicies and the cutover decision (a/b/c).

- [x] 17.10 Update PR #11633 description: add a row to the Scope 3 "What changed" sub-section documenting the NP additions; add the cutover decision (a/b/c) and the documented runbook (or `commonLabels` bridge) to the "Pre-merge gates" or a new "Cutover runbook" sub-section.

- [ ] 17.11 Cross-repo: in the `cc/kube-secrets` companion PR's `verify.md`, add a "Helm-vs-kustomize equivalence verification (PASS WITH WARNINGS)" section that captures the comparison evidence (helm-rendered vs kustomize-built diff for `a-qa-de-200`/k3s-admin), lists the 7 gaps, and cross-links to this repo's `tasks.md` Section 17 + the eventual follow-up issues. Item 5 (image SHA) is explicitly flagged as operator-decision-time, not a code gap. **This task lives in the cc/kube-secrets PR; helm-charts only owns the cross-link target.**

- [x] 17.12 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean.

- [x] 17.13 Commit on `poc/kustomize-metal-operator-remote`. Suggested message: `feat(metal-operator-remote): close helm-vs-kustomize equivalence gaps (NPs + label/name decision)`. Push to origin.

## 18. Rebind upstream metal-operator RBAC subjects to Gardener-prefixed ServiceAccount (post-deploy finding)

This section captures a correctness fix found during live deploy on `a-qa-de-200`: after `kubectl apply -k <overlay>/remote/` lands the upstream RBAC verbatim, the controller-manager Pod logs a forever-loop of `forbidden` errors on every list/watch — because upstream's `manager-rolebinding`, `metrics-auth-rolebinding`, and `leader-election-rolebinding` bind to the unprefixed `controller-manager` SA, while the remote-kubeconfig token authenticates as the **Gardener-prefixed** SA `metal-operator-controller-manager`.

The fix mirrors the idiom already established by `remote/upstream/webhook-injector-rbac/` — override the binding `subjects` list to point at the prefixed SA. Targeted-subject patches only; NO `namePrefix:` (would also rename CRDs and break the manager's CRD watches), NO upstream-SA rename (the unprefixed SA stays in the build output, unused).

A TEST-PHASE block currently lives in `cc/kube-secrets//values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/remote/kustomization.yaml` carrying the same three patches; it must be removed in a follow-up commit there once Section 18 lands here.

### Tasks

- [x] 18.1 Add a new ADDED Requirement `Upstream metal-operator RBAC bindings rebound to Gardener-prefixed ServiceAccount` to `specs/kustomize-resource-splitting/spec.md` (already drafted alongside this task). The requirement SHALL specify the three binding names, the override subject (`{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}`), the patch idiom matching the sibling webhook-injector-rbac subtree, and the out-of-scope guardrails (no namePrefix, no SA rename, no apply-order change).

- [x] 18.2 Add a new section to `design.md` ("Three-namespaces-of-controller-manager problem") documenting the SA identity table (workerless unprefixed vs workerless Gardener-prefixed vs seed webhook-injector), the symptom (forbidden-loop), the root cause (helm chart's fullname template renames everything consistently; kustomize port loses this), and the fix idiom.

- [x] 18.3 Edit `system/kustomize/metal-operator-remote/remote/upstream/metal-operator-crds-and-rbac/kustomization.yaml`. Add a `patches:` block AFTER the existing `resources:` list with three entries, each using JSON Patch `op: replace` on `path: /subjects`:
  - `target: { kind: ClusterRoleBinding, name: manager-rolebinding }`
  - `target: { kind: ClusterRoleBinding, name: metrics-auth-rolebinding }`
  - `target: { kind: RoleBinding, name: leader-election-rolebinding }` (note: RoleBinding, not ClusterRoleBinding)

  Each patch's value SHALL be a single-element array `[{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}]`.

  Match the comment style and rationale-density of `remote/upstream/webhook-injector-rbac/kustomization.yaml`'s `webhook-injector-target` patch. Reference back to that file in a short comment so future readers see the precedent.

- [x] 18.4 Verify build:
  ```
  kustomize build system/kustomize/metal-operator-remote/remote/upstream/metal-operator-crds-and-rbac/ > /tmp/rendered.yaml
  ```
  Then verify the three bindings have the expected subject:
  ```
  for binding in manager-rolebinding metrics-auth-rolebinding leader-election-rolebinding; do
    echo "=== $binding ==="
    yq -N "select((.kind == \"ClusterRoleBinding\" or .kind == \"RoleBinding\") and .metadata.name == \"$binding\") | .subjects" /tmp/rendered.yaml
  done
  ```
  Expected: every binding shows exactly `[{kind: ServiceAccount, name: metal-operator-controller-manager, namespace: kube-system}]`.

- [x] 18.5 Verify the full `remote/` build still composes cleanly:
  ```
  kustomize build system/kustomize/metal-operator-remote/remote/ > /tmp/remote.yaml
  ```
  Spot-check that no other resource changed unexpectedly (compare resource counts to pre-change build; expect identical except for the 3 binding subjects).

- [x] 18.6 Update `proposal.md` "What changes" with a brief bullet documenting the subject-rebind fix.

- [x] 18.7 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean.

- [x] 18.8 Commit on `poc/kustomize-metal-operator-remote`. Suggested message: `fix(metal-operator-remote): rebind upstream RBAC subjects to Gardener-prefixed SA`. Push to origin.

- [x] 18.9 Update PR #11633 description: add a brief note under Scope 3 documenting the subject-rebind fix and its symptom (`forbidden`-loop on list/watch). Cross-link the cc/kube-secrets TEST-PHASE block that becomes redundant.

- [ ] 18.10 Cross-repo follow-up (in cc/kube-secrets, NOT this repo): once Section 18 merges to `poc/kustomize-metal-operator-remote`, the TEST-PHASE `patches:` block in `cc/kube-secrets//values/kustomize/admin-k3s/qa-de-1/a-qa-de-200/metal-operator-remote/remote/kustomization.yaml` becomes redundant. Remove it in a follow-up commit on the kube-secrets side. **This task lives in the cc/kube-secrets PR; helm-charts only owns the cross-link target.**

## 19. Rename kustomize Deployment to match helm chart's literal name (post-deploy parity)

This section closes Item 4 of the helm-vs-kustomize equivalence gap analysis (`design.md` "Helm-vs-kustomize equivalence gap analysis"). The kustomize port inherits upstream `ironcore-dev/metal-operator//config/manager?ref=v0.4.0`'s `metadata.name: controller-manager` (upstream's bare name); the helm chart's `templates/controller-manager.yaml` hard-codes `metadata.name: metal-operator-controller-manager` (literal — not templated through `fullname`). Helm-deployed production runtime clusters (verified 2026-06-10 against rt-eu-de-1 → shoot--cp--m-eu-de-1: live Deployment `metal-operator-controller-manager-9d4b46c95`) carry the prefixed name.

**Why rename:** in any Gardener seed CP namespace, several controller-managers coexist (`gardener-resource-manager`, `kube-controller-manager`, `ipam-capi-controller-manager`, this one). With the generic `controller-manager-<hash>-<random>` Pod name, identifying which controller-manager belongs to metal-operator-remote requires inspecting labels or images. Helm-deployed sister clusters get `metal-operator-controller-manager-<hash>-<random>` — clear at a glance. This rename closes that gap, brings kustomize-mode naming into parity with helm, and reduces the helm→kustomize cutover diff to "0 functional differences" on naming.

**Why this is non-trivial — cascading patch targets:** two existing strategic-merge patches identify the Deployment by `name: controller-manager` to apply customizations:

1. `host/base/manager-patch.yaml:4` — strategic-merge patch consumed via `host/base/kustomization.yaml`'s `patches: - path: manager-patch.yaml`. Customizes manager args, env, volumes, ports, securityContext, network labels.
2. `components/webhook-injector/sidecar.yaml:4` — strategic-merge patch consumed by the webhook-injector Component (referenced from `host/base/kustomization.yaml` via `components: - ../../components/webhook-injector`). Adds the webhook-injector sidecar initContainer, sets `serviceAccountName`, etc.

Both MUST continue matching the original `controller-manager` name after the rename, otherwise the manager would render without its customizations and without the webhook-injector sidecar. Kustomize's transformer order is: `resources:` → `components:` → `patches:` (in order). Therefore the rename JSON-patch MUST be the LAST entry in `patches:` — earlier strategic-merge patches run first against the original name; only the final entry transforms the name. Putting the rename earlier in the list breaks the manager-patch and sidecar.yaml matches.

`namePrefix:` / `nameSuffix:` directives are NOT acceptable here — global prefix would also rename `metal-operator-webhook-service` → `metal-operator-metal-operator-webhook-service` and mangle every other already-prefixed local resource. Targeted JSON-patch rename is the only correct approach.

### Tasks

- [ ] 19.1 Update spec delta in `specs/kustomize-resource-splitting/spec.md`: the existing scenario "Build host base overlay" already says `Deployment named controller-manager` — change to `Deployment named metal-operator-controller-manager` and add a brief note that this matches the helm chart's literal name. (Already drafted alongside this task.)

- [ ] 19.2 Update `design.md` "Helm-vs-kustomize equivalence gap analysis" Item 4 disposition from "decision required" to "fix in this repo (Section 19)". Add a note that the renamed Deployment removes the brief co-existence step from the Section 17 cutover runbook (since helm-deployed and kustomize-deployed clusters now use the same Deployment name, kubectl apply needs to manage the helm→kustomize handoff explicitly via helm uninstall first; Section 19 commits this update).

- [ ] 19.3 Update `proposal.md` "What changes" with a brief From/To/Reason/Impact bullet documenting the Deployment rename (kustomize-mode parity with helm; post-deploy operational clarity).

- [ ] 19.4 Edit `system/kustomize/metal-operator-remote/host/base/kustomization.yaml`. Append a new JSON-patch entry as the LAST item in `patches:`:
  ```yaml
  - target:
      kind: Deployment
      name: controller-manager
    patch: |
      - op: replace
        path: /metadata/name
        value: metal-operator-controller-manager
  ```
  Add a comment block above the entry explaining the patch-ordering invariant (the rename runs LAST so the two earlier strategic-merge patches still match `controller-manager`), why JSON-patch is the only kustomize-native way to rename (`metadata.name` is the strategic-merge match key; can't be changed via strategic-merge), why `namePrefix:` is unacceptable (would mangle all other already-prefixed local resources), and the downstream impact (kube-secrets per-cluster overlays must update their `patch.target.name` and `replacements.targets.select.name` references from `controller-manager` to `metal-operator-controller-manager`).

  Do NOT edit `manager-patch.yaml` or `components/webhook-injector/sidecar.yaml` — their `name: controller-manager` references are correct and intentional (they run before the rename).

- [ ] 19.5 Verify build:
  ```
  kustomize build system/kustomize/metal-operator-remote/host/base/ > /tmp/rendered.yaml
  ```
  Then verify three invariants:
  - **Renamed name:** `yq -N 'select(.kind == "Deployment") | .metadata.name' /tmp/rendered.yaml` → `metal-operator-controller-manager`
  - **Sidecar still merged:** `yq -N 'select(.kind == "Deployment") | .spec.template.spec.initContainers[].name' /tmp/rendered.yaml` → `webhook-injector`
  - **Manager-patch still merged:** `yq -N 'select(.kind == "Deployment") | .spec.template.spec.containers[] | select(.name == "manager") | .args[0]' /tmp/rendered.yaml` → `--mac-prefixes-file=/etc/macdb/macdb.yaml`

- [ ] 19.6 Verify the full `remote/` build is unaffected:
  ```
  kustomize build system/kustomize/metal-operator-remote/remote/ > /tmp/remote.yaml
  ```
  No remote/ resource references the host-side Deployment by name; build should be byte-identical to pre-rename.

- [ ] 19.7 Run `openspec validate replace-managedresource-with-dual-kustomize --strict`. Expected: clean.

- [ ] 19.8 Commit on `poc/kustomize-metal-operator-remote`. Suggested message: `metal-operator-remote: rename kustomize Deployment to match helm fullname`. Push to origin.

- [ ] 19.9 Update PR #11633 description: add a brief note under Scope 3 documenting the Deployment rename and the kube-secrets follow-up (per-cluster overlays' `patch.target.name` and `replacements.targets.select.name` references must switch from `controller-manager` to `metal-operator-controller-manager`).

- [ ] 19.10 Cross-repo follow-up (in cc/kube-secrets, NOT this repo): once Section 19 merges, the `a-qa-de-200` overlay's `host/kustomization.yaml` has three references to update (`replacements.targets.select.name` ~L46; `patches.target.name` ~L88; `patches.metadata.name` inside the patch body ~L93). Apply order in cc/kube-secrets per-cluster overlay: `kubectl delete -k host/` (removes old-name Deployment) → bump helm-charts ref or rebuild → bump the three name references → `kubectl apply -k host/` (creates new-name Deployment). **This task lives in the cc/kube-secrets PR; helm-charts only owns the cross-link target.**
