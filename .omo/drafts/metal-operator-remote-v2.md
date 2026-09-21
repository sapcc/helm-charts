# metal-operator-remote-v2 — planning draft

intent: clear
review_required: false
status: plan-written (dual-approved round 9: Momus APPROVE + Oracle APPROVE); patch-render-scoping prerequisite now SHIPPED upstream — plan text de-staled 2026-08-05
pending_action: offer dual high-accuracy review OR handoff to $start-work — NO external blockers remain
plan_file: .omo/plans/metal-operator-remote-v2.md (16 todos + F1-F4; T17 was added then REVERTED — see operator_docs_UPDATE; Metis gaps folded in; Appendix A inlines all README + current-chart source facts so executor needs no external reads)
operator_docs_UPDATE (2026-08-05): the patch-render-scoping doc I drafted to paste is now OBSOLETE — do NOT paste it. The operator repo ALREADY has docs/patch-render-scoping.md (status: Implemented), docs/context.md Revision 10, docs/design.md §3.4.1/§3.4.4/§3.4.5 — all shipped. Pasting my "Proposed" draft would regress a shipped doc. The T17 plan todo (author that doc) was added then reverted; the plan is back to 16 todos + F1-F4.
operator_capability_UPDATE_1 (subchart-dep resolution): IMPLEMENTED on operator origin/main (commit 508334f, Rev 8/9). Constraints: oci:// (or file://) deps + committed Chart.lock. `-v2` doesn't depend on it either way (published pkg already vendors the subchart). Nothing to author.
operator_capability_UPDATE_2 (patch render-scoping / no-op-on-zero-match): NOW SHIPPED on operator main — archived OpenSpec change openspec/changes/archive/2026-08-05-patch-render-scoping/ (HEAD c37a676). Chosen shape = zero-match patch is a SILENT NO-OP (fail-loud guard removed from internal/transform/patch.go), NOT the backstop/scope-field alternatives (quarantined as rejected/deferred in the shipped doc). Spec scenario "Single-render-scoped patch no-ops on the non-matching render" (shoot-only VWC) + verify report confirm the EXACT -v2 case, verified end-to-end via the metal-operator equivalence fixture (RUN_EQUIVALENCE=1 PASS). => -v2's label patch is LEGAL on main today: matches the shoot VWC, no-ops the seed render; webhooks functional. My LOCAL operator working-tree patch.go copy still shows old fail-loud code = stale checkout behind c37a676; the archived change + verify report are authoritative. All stale "non-functional / PROPOSED / until it ships / errors on today's operator" language purged from the plan (grep-verified clean). Cutover now has ONE remaining external gate: metal-token-rotate kube-secrets namespace alignment. Other 4 assumptions (macdb secrets-injector, chart owns Deployment, URL-form webhooks caBundle-unset, mode/seedValues/shootValues) all CONFIRMED unchanged.
slug: metal-operator-remote-v2

## Request
User pointed at `system/metal-operator-remote-v2/README.md` and said "I'd like to work on this."
= implement the operator-native `-v2` chart per that design/handoff spec.

## Components ledger
- C1 Chart skeleton (Chart.yaml deps + vendored subchart, Chart.lock, values.yaml, _helpers.tpl mode guards + origin:additions) — status: planned
- C2 Seed-render templates (controller-manager, metal-registry Service, Ingress, NetworkPolicy, remote/rotate kubeconfig Secrets, remote-kubeconfig ConfigMap, webhook-config ConfigMap, dns-record-template ConfigMap, macdb ref) — status: planned
- C3 Shoot-render templates (upstream subchart CRDs/RBAC/webhooks via seedValues/shootValues enable flags, webhook-injector RBAC/SA, token-rotate RBAC/SA, oidc-ias ClusterRoleBindings, metal-api-viewer ClusterRole, dns-records ClusterRole, ValidatingWebhookConfiguration caBundle-unset, metal-servers Namespace) — status: planned
- C4 DualDeploymentOperator CR authoring + kube-secrets pipeline coordination (relocate per-cluster values into CR; provision standalone macdb Secret) — status: planned (scope boundary TBD in gate)
- C5 CI/verification (helm lint/template both modes, packaging with vendored subchart, no `mode` set, origin annotations, caBundle unset) — status: planned

## Verified facts (with sources)
- Operator source at /Users/D065300/IdeaProjects/sapcc/dual-deployment-operator @ 33771d9 (github SAP-cloud-infrastructure/dual-deployment-operator).
- CONTRACT CONFIRMED = README: `mode` injection (seed/shoot) + spec.source.helm {values, seedValues, shootValues}; chart must NOT set `mode` (rejected in internal/source/helm.go:34-42). host/remote/shared split was REJECTED (older design).
- SUBCHART: operator does NOT run `helm dependency`; it pulls the chart .tgz and loader.Load()s it (internal/source/helmloader.go). => `-v2` MUST be published as a packaged .tgz with `metal-operator` subchart vendored in charts/. Chart.yaml dep alone is insufficient at operator runtime.
- SECRET INJECTION: HelmSource has values/seedValues/shootValues + AuthSecretRef (chart-pull only) + ShootAccess.SecretName (kubeconfig only). NO valuesFrom/secretRef for render values. => macdb BMC creds CANNOT be templated from CR (would commit secrets to git). Must be a standalone `macdb` Secret provisioned outside the render.
- macdb wiring: current macdb.yaml Secret has stringData `macdb.yaml` = toYaml .Values.macdb (whole macPrefixes[].defaultCredentials structure incl vault-resolved user/pass), mounted /etc/macdb/, consumed via `--mac-prefixes-file=/etc/macdb/macdb.yaml`. controller-manager.yaml:62-64,96-99.
- caBundle: operator strips webhook + CRD-conversion caBundle unconditionally (internal/deliver/cabundle.go). Chart emits WebhookConfiguration caBundle-unset + injector label. Delivery kind-agnostic SSA ForceOwnership (applier.go:69-74).
- remote.ca: overlay supplies base64 CA; remote-kubeconfig Secret already carries Gardener annotation `serviceaccount.resources.gardener.cloud/inject-ca-bundle: "true"`. Knowledge: client-go handles CA rotation natively with path-form kubeconfig. => remote.ca likely unnecessary in -v2 (rely on injected bundle). CONFIRM as owner-decision.
- Current chart deps: owner-info + metal-operator 0.6.2-crds (alias metal-operator-core) from oci://ghcr.io/ironcore-dev/charts. Chart.lock digest recorded.
- kube-secrets pipeline: HelmChartPipeline, vault_enabled, ns shoot--cp--m-$REGION, overlay values/helm/runtime/<region>/<cluster>/metal-operator-remote.yaml. No DualDeploymentOperator CR templated yet.
- Makefile build-metal-operator-remote (system/Makefile:156-187) does helm template|sed|yq pre-render + sidecar inject + webhook URL rewrite + version bump. To be DELETED for -v2.

## Owner-decisions — RESOLVED (user answered + verified)
1. macdb secret path — RESOLVED: chart TEMPLATES the `macdb` Secret carrying `{{ resolve "vault+kvv2:///..." }}` placeholders as an ordinary CR value. These are vault REFERENCES, not secrets, safe in git-committed CR. In-cluster `secrets-injector.cloud.sap` (cluster-scoped mutating webhook, runs on the seed clusters, opt-out only) resolves them on SSA apply into shoot--cp--m-<region>. VERIFIED chain in a-qa-de-200/prt-q-eu-de-1: macdb lands in seed CP ns directly (templates/, not ManagedResource); secrets-injector present on seed; fires. => NO operator secret-values change needed. Preserves today's behavior.
2. Mode-gating — RESOLVED: README hybrid. Chart-side `mode` guards (dual.seed/dual.shoot) for OUR addition templates + CR seedValues/shootValues for upstream subchart *.enable flags.
3. Subchart packaging — RESOLVED (two-track): DEFAULT = vendor `metal-operator` into charts/ (helm dep build) + publish -v2 as packaged .tgz, keep upstream 0.6.2-crds (no bump). PLUS write a docs/ PROPOSAL in dual-deployment-operator for Enhancement 1 (loader resolves subchart deps, ~35-40 LOC in internal/source/helmloader.go before loader.Load, via chartutil.Expand + downloader.Manager.Build). User directive: operator changes -> docs/ only, not code. "when it makes sense we can still push the change" => proposal now, implementation later.
4. remote.ca — RESOLVED: DROP. Rely on Gardener inject-ca-bundle on the remote-kubeconfig Secret; client-go handles CA rotation with path-form kubeconfig.
5. Scope — RESOLVED: CHART ONLY (user chose). In helm-charts: build -v2 chart + an example DualDeploymentOperator CR (illustrative, in-repo) + a docs proposal for the operator dep-resolution enhancement. NO kube-secrets pipeline.rb edits in this plan (coordinated follow-up elsewhere).
6. Test strategy — RESOLVED: TDD-style (fixtures FIRST). Write mode=seed / mode=shoot render-assertion fixtures, watch them fail, then port templates to green. Agent-executed QA always included: helm lint + helm template both modes; assert per-mode object sets, origin:additions, caBundle unset, subchart enable flags per mode, `mode` never in values, macdb Secret carries resolve-placeholders + no cloud.sap/inject-secrets:false opt-out.

## Operator docs proposal (Enhancement 1) — target repo dual-deployment-operator, docs/ only
- New file e.g. docs/proposals/subchart-dependency-resolution.md
- Problem: loader pulls .tgz + loader.Load, does NOT run helm dependency; charts declaring deps must vendor .tgz. -v2 wants to declare metal-operator dep.
- Proposed: in internal/source/helmloader.go Load(), after pull, chartutil.Expand the tgz, run downloader.Manager{ChartPath, Getters: getter.All(settings), RepositoryConfig/Cache from settings, RegistryClient}.Build(), then loader.Load(chartDir). ~35-40 LOC.
- Risks to document: (a) single authSecretRef can't auth a subchart in a DIFFERENT private registry; (b) egress NetworkPolicy to subchart repo at reconcile; (c) missing Chart.lock -> Update() semver resolution + network. 
- Decision framing: proposal only; -v2 ships vendored .tgz until/unless adopted. LOCATION (updated): the proposal doc lives in THIS helm-charts repo at system/metal-operator-remote-v2/docs/proposals/subchart-dependency-resolution.md, linked from the chart README. NO file is created in the dual-deployment-operator repo.

## Review receipts
review_required: true (user opted in for dual high-accuracy review)
ROUND 1: Momus (bg_e80da8e1) REQUEST-CHANGES + Oracle (bg_89164417) REQUEST-CHANGES. Both converged on: stale r7 webhook model (ported old --webhook-config-name/ConfigMap-delivery instead of target-patch mode); T14 CR missing shootAccess/shootNamespace; F3 not agent-executable; T8 remote.ca removal under-specified; macdb CR-leak guard; Appendix A.1.5/A.6 stale.
FIXES APPLIED (verified from operator+injector source): 
- r7 target-patch contract inlined (A.1.5/5a/5b): operator applies VWC direct+caBundle-unset; injector sidecar `--target-label`+`--cert-sans`, NO `--webhook-config-name`; seed webhook-config ConfigMap DEAD. Injector image pinned keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/webhook-injector:20c495f (user-provided). T4/T9/T13 rewritten; T9 drops the ConfigMap; T13 uses target-label + URL-form.
- A.8 added: exact CR required fields (source/shootAccess/shootNamespace); T14 rewritten complete, no transforms.
- F3 rewritten agent-executable (kind/name set equality + guards), then reframed to LOCAL ad-hoc (no ci/) per user "no CI".
- T8 rewritten: exact keys (inject-ca-bundle + bundle.crt) + must identify metal-token-rotate-kubeconfig consumer; no empty-CA/insecure kubeconfig.
- T5 macdb leak-guard added.
USER REFINEMENTS folded in after round 1:
- "subchart vendored but no need to check in" => T2 declares oci:// dep + commits Chart.lock; charts/*.tgz gitignored, bundled at publish by helm-push-from-input.yaml; verified repo pattern. T16 (now T15) + Related-work note rewritten to vendored-at-publish.
- "no CI, will test locally in real cluster" + "keep TDD-style local" => deleted T15 CI todo; T3 harness dropped; verification strategy = local ad-hoc helm template/yq (TDD RED->GREEN by hand) + real-cluster deploy = user's out-of-plan acceptance gate. Renumbered T16->T15. All ci/ references removed.
ROUND 2: Momus (bg_3cef313e) REQUEST-CHANGES + Oracle (bg_285dbfb5) REQUEST-CHANGES. Both narrowed sharply (r7 webhook contract, T14 CR, vendored-at-publish, F3 confirmed correct in principle). Remaining blockers (ALL NOW FIXED in plan):
- No-CI residual contradictions: line 32 "pass in CI" + T2 line105 "CI guard" -> rewritten to local ad-hoc. DONE.
- Stale seed webhook-config ConfigMap still in Must-have list (line 27) -> removed. DONE.
- T8 rotate-kubeconfig not decision-complete -> GROUNDED (metal-token-rotate = Gardener token-requestor, targetSecretName metal-token-rotate-kubeconfig, ns shoot--ccloud--metal-operator) and rewritten to a DECIDED shape: inject-ca-bundle:true + certificate-authority-data:"" placeholder Gardener fills at runtime (same mechanism as remote-kubeconfig). DONE.
- Oracle#1 webhook TLS SAN mismatch: VWC URL host = short `metal-operator-remote-webhook-service` but --cert-sans was the .svc FQDN -> fixed A.5a + T4 to short name (matches current chart's proven value + URL host). DONE.
- Oracle#3 SSA + stringData: added Appendix A.9 (proven pattern in current helm-deployed chart; operator SSA path flagged as real-cluster confirm step in T5/T8). DONE.
- Success criteria + commit strategy wording corrected (vendored-in-published-artifact-not-git; no operator-repo change). DONE.
CONFIRMED-CORRECT by both reviewers: r7 target-patch (--target-label/--cert-sans, --webhook-config-name optional, patches caBundle only); operator strips caBundle; rewriteWebhookURL leaves URL-form untouched; pinned image 20c495f = target-patch build; vendored-at-publish model; macdb refs safe-in-git.

ROUND 3: Momus (bg_680c3c2a) REQUEST-CHANGES + Oracle (bg_d1f18cc5) REQUEST-CHANGES. Everything else confirmed correct by BOTH (webhook SAN short-name, r7 target-patch, vendored-at-publish, no-CI, macdb, CR shape, SSA/stringData framing acceptable). Remaining blockers ALL in T8 + 2 mechanical (NOW FIXED):
- T8 rotate-kubeconfig contradictory shape (bundle.crt AND embedded-kubeconfig-empty-CA AND stray token:"" AND "no empty CA" vs "certificate-authority-data: ''"). Oracle gave authoritative Gardener behavior: token-requestor writes token+CA INTO .data.kubeconfig when a kubeconfig key is present (NOT bundle.crt). FIXED to ONE shape: metal-token-rotate-kubeconfig = inject-ca-bundle:"true" + embedded kubeconfig certificate-authority-data:"" (Gardener fills at runtime), NO top-level bundle.crt/token. remote-kubeconfig stays token-only shape (bundle.crt:""+token:""). T8 bullet/Must-NOT/acceptance/QA + A.6 line290 + A.9 all realigned.
- Leak-guard grep used PCRE negative-lookahead (?!...) - not BSD/POSIX. FIXED to two-step `grep -REi '(username|password):' | grep -vF 'vault+kvv2://'` must be EMPTY (T5; T14 reuses it).
- A.9 "MUST include" vs T5 "already verified" contradiction. FIXED: SSA/stringData live-cluster confirm is the user's out-of-plan gate; T5/T8 local acceptance verify only the render; A.9 reworded (token-only vs kubeconfig-embedded Gardener behavior).
Verified: grep confirms no stale (?!, "MUST include", "path-form CA like", "both...carry bundle.crt", stray token:"".

ROUND 4: Momus (bg_81d5742c) REQUEST-CHANGES + Oracle (bg_df794e43) REQUEST-CHANGES. ALL round-3 items confirmed resolved by both; each raised ONE internal-consistency omission (NOW FIXED):
- Momus: Scope line 30 "both kubeconfig Secrets rely on Gardener-injected CA bundle (path-form)" - false for rotate. FIXED: Scope now distinguishes the two shapes (remote-kubeconfig token-only path-form; rotate embedded-kubeconfig CA).
- Oracle: seed webhook-injector RBAC (SA/Role/RoleBinding metal-operator-webhook-injector, the Deployment serviceAccountName) emitted by T11 but MISSING from Scope must-have + A.2 seed set + F3 expected seed set. FIXED: added to all three; T11 retitled "SEED SA/Role/RoleBinding + SHOOT ClusterRole" + acceptance asserts seed SA/Role/RoleBinding present & no ClusterRole in seed; wave-2 line updated.
Everything else APPROVED by both (T8 one shape confirmed correct vs Gardener docs, POSIX leak-guard, SSA/stringData framing, r7 target-patch, vendored-at-publish, CR shape, caBundle strip).

ROUND 5: Momus (bg_0597ff44) REQUEST-CHANGES + Oracle (bg_08659db3) REQUEST-CHANGES. Round-4 items resolved. Remaining (NOW FIXED):
- Oracle#1 DUPLICATE VWC: shoot enabled upstream metal-operator-core.webhook.enable=true AND T13 hand-authors the same VWC -> duplicate. FIXED: shoot enables crd+rbac ONLY, webhook.enable STAYS FALSE (chart authors VWC in T13). Propagated to Scope, A.3, T10, T13, T14, F3.
- Oracle#2: F3 "set equals" could miss duplicate manifests. FIXED: added uniq -d duplicate-object guard + "exactly ONE VWC in shoot".
- Oracle#3: exact RBAC names. FIXED: ClusterRole/metal-operator-dns-records + ClusterRoleBinding/metal-operator-dns-records-rolebinding, explicit oidc/ldap names in A.3+F3.
- Momus#1: T4 acceptance cross-referenced T13 VWC url (later wave). FIXED: T4 asserts literal host; sidecar<->VWC equality moved to F3.

NEW SCOPE (user, after round 5): "also include the template to add CR" -> add a TEMPLATED DualDeploymentOperator CR INSIDE the -v2 chart, but values.yaml leaves it EMPTY/disabled; kube-secrets supplies the actual CR values per cluster. CIRCULARITY CARVE-OUT: the operator renders -v2 (mode=seed/shoot) to make seed/shoot objects; the CR points AT -v2, so the CR template MUST NOT render under either operator mode. Gate it on `{{- if and (not .Values.mode) .Values.dualDeploymentOperatorCR.enabled }}` - renders ONLY on a direct `helm install` (mode unset; operator is the only thing that injects mode) AND when kube-secrets enables it. Default values.yaml: `dualDeploymentOperatorCR: {enabled: false}` + empty value stubs. This becomes a NEW todo; renumber (was T15 README note -> T16; new CR-template todo). T14 static examples/ CR stays as filled reference.

ROUND 6 (PENDING - dispatch after adding the CR-template todo): resubmit Momus + independent Oracle fresh. Both must return unconditional APPROVE. Do NOT hand off until both APPROVE (review_required=true).

=== PER-SHOOT ALIGNMENT FINDING (user: "check existing per-shoot deployments, stay aligned") ===
Surveyed helm-charts + kube-secrets + operator repo. Key facts:
- Per-shoot convention: release `<op>-remote`; namespace `shoot--cp--m-$REGION` set by kube-secrets pipeline.rb via --namespace (NOT values); per-cluster values under kube-secrets values/helm/<class>/<region>/<cluster>/<release>.yaml; KUBERNETES_SERVICE_HOST per-cluster there. -v2 is the FIRST operator-native deploy (sets pattern).
- AUTHORITATIVE per-shoot CR shape = operator repo testdata/fixtures/metal-operator/cr.yaml:
    metadata.namespace: shoot--cp--m-<region>; spec.shootNamespace: kube-system (NOT metal-servers);
    source.helm{repo oci://ghcr.io/ironcore-dev/charts, name metal-operator, version 0.6.2-crds,
      shootValues{controllerManager:false, rbac:true, crd:true, webhook:TRUE, certmanager:false},
      seedValues{controllerManager:true, rest false}};
    shootAccess{secretName metal-operator-remote-kubeconfig, server https://api.m-<region>.internal};
    transformations: [ rewriteWebhookURL{urlPrefix "https://metal-operator-remote-webhook-service:443"} ].

*** WEBHOOK FORK - REVERSES ROUND-5 DECISION ***
Round-5 fix said: chart authors the VWC (templates/webhooks.yaml), shootValues.webhook.enable=FALSE, no transform (to avoid duplicate VWC).
The operator's OWN fixture does the OPPOSITE: shootValues.webhook.enable=TRUE (upstream subchart emits the VWC) + CR rewriteWebhookURL transform rewrites service->URL (the yq step the makefile did today). This is the operator team's tested/canonical pattern and there is NO duplicate because the chart does NOT author its own VWC.
=> ALIGNMENT DECISION (pending user confirm): ADOPT the fixture pattern.
  - T13: do NOT hand-author templates/webhooks.yaml / VWC. DROP the chart-authored VWC.
  - T10/T14/A.3/scope: shoot enables crd+rbac+WEBHOOK (webhook.enable=TRUE); upstream subchart emits the VWC.
  - CR (T14 example + T16 template): add transformations:[rewriteWebhookURL{urlPrefix https://metal-operator-remote-webhook-service:443}].
  - Injector target-label on the (now upstream-emitted) VWC: needs a CR `patch` transform stamping dual-deployment-operator.cc.sap/webhook-injector=metal-operator on the VWC (design.md ~330-360 shows label via patch). VERIFY metal-operator VWC needs the injector at all (metal has webhooks; caBundle must be patched) -> yes, keep the label patch. NOTE design.md line 315 also shows shootNamespace: metal-operator in one example but the metal fixture uses kube-system -> use kube-system per the fixture (authoritative).
  - metal-servers Namespace: still a chart addition (mode=shoot), separate from shootNamespace.
  - This UNDOES round-5 F3 "exactly one chart-authored VWC / webhook.enable=false" asserts -> now assert exactly one VWC total (upstream's, rewritten to URL) + it carries the injector label + caBundle unset.
Other alignment fixes regardless of fork: shootNamespace=kube-system (not metal-servers); shootAccess.server = internal apiserver URL form; example CR name `metal-operator-remote`, namespace shoot--cp--m-<region>.

NEXT ACTION on resume: (1) get user confirm on the webhook fork (adopt fixture: upstream webhook + rewriteWebhookURL + label patch, vs chart-authored VWC). (2) apply the alignment fixes across scope/A.3/A.6/A.8/A.10/T10/T13/T14/T16/F3. (3) THEN dispatch round 6 dual review. Do NOT hand off until both APPROVE.

=== PLAN REWRITTEN (user: "too long, make it short/readable") ===
Wholesale rewrite of .omo/plans/metal-operator-remote-v2.md - dropped round-by-round scar tissue, kept final decided state only. ~130-line body + tight Appendix A.1-A.10. 16 todos + F1-F4. Webhook fork RESOLVED (user chose fixture pattern): upstream subchart emits VWC (shootValues.webhook.enable=true) + CR rewriteWebhookURL{urlPrefix https://metal-operator-remote-webhook-service:443} + patch(injector label); chart does NOT author a VWC. Per-shoot alignment folded in: shootNamespace=kube-system, CR namespace shoot--cp--m-<region>, shootAccess{secretName metal-operator-remote-kubeconfig, server https://api.m-<region>.internal}. All prior fixes preserved: T8 rotate-kubeconfig one shape (inject-ca-bundle + embedded kubeconfig ca-data:""), POSIX leak-guard, r7 sidecar pinned image + short-name --cert-sans, seed injector RBAC in all sets, exact RBAC names, vendored-at-publish, disabled-by-default CR template (A.10), no committed CI, SSA/stringData = live-cluster gate (A.9), duplicate-object guard in F3.

ROUND 6 (dispatch now): resubmit Momus + independent Oracle fresh against the REWRITTEN plan. Both must return unconditional APPROVE. If REQUEST-CHANGES, fix + repeat. Do NOT hand off until both APPROVE (review_required=true).

=== ROUND 6 RESULT: Momus (bg_6afe3f69) + Oracle (bg_6bbbdb31) BOTH REQUEST-CHANGES ===
Rewrite is coherent; 4 issues (2 are real correctness bugs from the webhook-fork realignment):

FIX 1 (both reviewers) - T14 seedValues REGRESSION: rewrite copied the upstream fixture's seedValues{controllerManager:true} which CONTRADICTS "chart owns the Deployment / subchart controllerManager stays false". => T14 seedValues must be ALL metal-operator-core.*.enable=false (chart owns the controller-manager Deployment). The fixture enables it because the fixture lets the SUBCHART render the Deployment; -v2 does NOT (we own it). Fix T14 + A.8 fixture-shape note.

FIX 2 (the big one - Oracle, GROUNDED) - the injector-label mechanism is BROKEN as written and this REVERSES the webhook fork back to chart-authored VWC:
  - operator `patch` transform FAILS on zero matches (internal/transform/patch.go:53-55: `matched==0 -> error "no matching resource for patch target selector"`).
  - transforms run PER-RENDER, applied to BOTH seed and shoot independently (internal/controller/dualdeploymentoperator_controller.go:131-140). A `patch` targeting the VWC errors on the SEED render (no VWC there).
  - upstream metal-operator 0.6.2-crds VWC template has NO values hook for custom labels (only chart.labels helper). So the chart canNOT get the injector label onto the upstream-emitted VWC via values.
  - rewriteWebhookURL is a safe no-op on zero matches (rewrite_webhook_url.go) - but it only rewrites service->URL, it canNOT add a label.
  - operator design.md §3.4.4: label is "stamped by the chart/kustomization on the upstream webhook objects" - but a Helm wrapper canNOT edit the subchart's rendered VWC.
  => CONCLUSION: the ONLY working mechanism is CHART-AUTHORS-THE-VWC (round-5 design): chart emits templates/webhooks.yaml (VWC, URL-form clientConfig to https://metal-operator-remote-webhook-service:443/..., caBundle UNSET, injector target-label stamped), and shootValues keeps metal-operator-core.webhook.enable=FALSE (so no upstream VWC -> no duplicate). NO rewriteWebhookURL transform, NO patch transform in the CR.
  => THIS REVERTS the "align to fixture (upstream webhook + rewriteWebhookURL)" decision the user picked. The fixture's approach cannot carry the injector label. MUST re-confirm with user OR just adopt chart-authored VWC (round-5) since it is the only correct path. RECOMMEND: chart-authored VWC (round-5), and note the fixture diverges because it predates/omits the label requirement.
  Revert across: TL;DR decisions, Scope shoot bullet, A.1.5, A.3, A.5/A.6 webhook facts, A.8 (drop the two transforms from the CR; CR has NO transformations), T10 (shoot enables crd+rbac ONLY, webhook.enable=FALSE), T13 (chart AUTHORS templates/webhooks.yaml VWC + metal-servers Namespace), T14 (no transformations), F3 (SHOOT set has the CHART-authored VWC; assert webhook.enable false so no upstream VWC; exactly one VWC).

FIX 3 (Oracle) - T4 sidecar MISSING `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig`: without it the injector target-patch mode watches the SEED, not the shoot VWC (README:152 defaults in-cluster; current sidecar tpl:7 sets it). ADD `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig` to the r7 sidecar args in T4 + A.5 + A.6 sidecar facts + F3 assertion.

FIX 4 (Oracle) - upstream-VWC parity check is MOOT once we revert to chart-authored VWC (the chart ships the 7 webhooks verbatim). But KEEP a T13/F3 assertion that the chart-authored VWC has exactly the 7 webhooks (vbiossettings, vbiosversion, vbmcsecret, vbmcsettings, vbmcversion, vendpoint, vserver) with their paths/rules/failurePolicy:Fail/sideEffects:None per A.6 (re-commit chart-root webhooks.yaml or author inline). NOTE: reverting to chart-authored VWC means T9's "no chart-root webhooks.yaml" and the A.4 "chart-root webhooks.yaml gone" statements ALSO revert - the chart DOES ship webhooks.yaml (via .Files.Get) OR authors the VWC inline in templates/webhooks.yaml.

VERIFIED-CORRECT by round 6 (keep as-is): rewriteWebhookURL semantics; T8 rotate-kubeconfig one-shape (inject-ca-bundle + embedded kubeconfig ca-data:""); vendored-at-publish; POSIX leak-guard; disabled-by-default CR template A.10; injector patches caBundle on labeled shoot VWC once label present + --target-kubeconfig points at shoot.

NEXT ACTION on resume:
1. RE-CONFIRM webhook approach with user: the fixture path (upstream webhook + rewriteWebhookURL) CANNOT carry the injector label (per-render patch error); the only correct path is CHART-AUTHORS-THE-VWC (round-5). Recommend adopting chart-authored VWC. [This is a genuine fork reversal - user picked fixture-align last time based on my incorrect claim the fixture carried a label patch; it does not.]
2. Apply FIX 1 (T14 seedValues all false) + FIX 3 (--target-kubeconfig) + FIX 4 (VWC 7-webhook parity assertion) regardless.
3. Apply FIX 2 (revert to chart-authored VWC across all the listed sections) once user confirms.
4. THEN dispatch round 7 dual review. Do NOT hand off until both APPROVE (review_required=true).

=== WEBHOOK DECISION (user, resume): CR PATCH + PREREQUISITE OPERATOR ENHANCEMENT ===
User chose: keep the CR `patch` to stamp the injector label, and make it viable via an OPERATOR ENHANCEMENT (render-scoped OR no-op-on-zero-match patch) - written up as a docs/ PROPOSAL in the dual-deployment-operator repo (same "separate, prerequisite, done first" category as subchart-resolution). This ALIGNS -v2 to the operator fixture: upstream subchart emits the VWC (shootValues.webhook.enable=TRUE) + CR rewriteWebhookURL{urlPrefix https://metal-operator-remote-webhook-service:443} + CR patch{target VWC, add label dual-deployment-operator.cc.sap/webhook-injector: metal-operator}.
=> So webhook fork lands on FIXTURE-ALIGN (NOT chart-authored VWC). This keeps the round-6-rewrite webhook direction (upstream emits VWC), the ONLY change vs the current plan text is that the label patch is now explicitly gated on the prerequisite operator enhancement.
SCOPE CONSEQUENCE (must be explicit in plan): -v2 webhooks do NOT function until the operator patch-scoping enhancement ships (the label patch would error on the seed render on today's operator). Plan must state this dependency in TL;DR + Related work + the relevant todos, and the example/template CR must carry both transforms with a comment that the patch requires the enhancement.

APPLY NOW (all four round-6 fixes, with the webhook fork = fixture-align + prerequisite enhancement):
- FIX 1: T14 + A.8 seedValues = all metal-operator-core.*.enable=false (chart owns the controller-manager Deployment; do NOT copy the fixture's controllerManager:true, which is for the subchart-renders-Deployment model we do NOT use). shootValues = crd+rbac+webhook true.
- FIX 2 (per user = fixture-align, NOT revert): KEEP upstream-emits-VWC. A.8/T14 CR transformations = [rewriteWebhookURL{...}, patch{target: {kind: ValidatingWebhookConfiguration}, strategicMerge: add metadata.labels dual-deployment-operator.cc.sap/webhook-injector: metal-operator}]. Add explicit note (A.1.5, A.8, T10, T14, TL;DR, Related-work): the `patch` requires the operator render-scoping/no-op-zero-match enhancement (prereq); on today's operator it errors on the seed render. T13 = metal-servers Namespace ONLY (does NOT author a VWC). F3 SHOOT set = upstream VWC (labeled + URL-rewritten), assert exactly one VWC + it carries the injector label + caBundle unset.
- FIX 3: T4 + A.5 + A.6 sidecar args ADD `--target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig` (else injector watches seed not shoot). F3 assert sidecar args include it.
- FIX 4: T1 + F3 assert the (upstream-emitted) VWC has the 7 webhooks (vbiossettings, vbiosversion, vbmcsecret, vbmcsettings, vbmcversion, vendpoint, vserver) with paths/rules/failurePolicy:Fail/sideEffects:None per A.6 (parity vs today's committed webhooks.yaml). Since upstream emits it, this is a parity check on the subchart output, not on a chart-authored file.
- NEW: add an operator docs/ proposal to the "Related / prerequisite work" section: "patch render-scoping / no-op-on-zero-match" enhancement in dual-deployment-operator (docs-only proposal, like subchart-resolution). This plan does NOT implement it; references it as the gate for -v2 webhooks.

=== ROUND 6 FIXES APPLIED (all four; webhook = fixture-align + prerequisite operator enhancement) ===
FIX1 DONE: T14/A.8 seedValues = all metal-operator-core.*.enable=false (documented divergence from fixture's controllerManager:true).
FIX2 DONE: upstream emits VWC + CR rewriteWebhookURL + label patch; label patch gated on PREREQUISITE operator enhancement (TL;DR, machine-TL;DR, A.1.5, A.8, T10, Related-work 2nd item). -v2 webhooks non-functional until it ships.
FIX3 DONE: --target-kubeconfig=/var/run/remote-kubeconfig/kubeconfig added to T4 + A.6 sidecar fact + F3.
FIX4 DONE: 7-webhook VWC parity check in T1 + F3.
Verified: no stale seedValues{controllerManager:true} / chart-authored-VWC contradiction.

ROUND 7 (dispatched): Momus + independent Oracle fresh against the plan with round-6 fixes. Both must return unconditional APPROVE. If REQUEST-CHANGES, fix + repeat. Do NOT hand off until both APPROVE (review_required=true).

=== ROUND 7 RESULT: Momus (bg_c5c209b9) APPROVE + Oracle (bg_40da61e3) REQUEST-CHANGES ===
Momus approved. Oracle raised 3 (all cutover/consistency text, no design flaw) - ALL FIXED:
- Oracle#1 token-rotate namespace mismatch: operator applies SEED into cr.Namespace (controller.go:114) = shoot--cp--m-<region>, but kube-secrets metal-token-rotate targets shoot--ccloud--metal-operator. FIXED: added a "metal-token-rotate namespace alignment" kube-secrets cutover-prerequisite item in Related work + a note in T14; hard pre-cutover gate, not a kube-secrets edit in this plan.
- Oracle#2 success criteria overstated end state: FIXED: split Success criteria into IN-PLAN (chart renders/verifies offline) vs CUTOVER (gated on the two prerequisites: operator patch enhancement deployed + token-rotate namespace aligned).
- Oracle#3 T14 "functional" misleading: FIXED: retitled T14 "enhanced-operator", header comment states the label patch fails on today's operator + the namespace-alignment note; Must-NOT "imply it works on the un-enhanced operator".
Oracle VERIFIED-OK: seedValues all-false; webhook prerequisite honest + no chart-authored VWC; --target-kubeconfig correct + matches mounted volume; 7-webhook parity; strategicMerge label patch on typed VWC works; rewriteWebhookURL/patch ordering fine.

ROUND 8 (dispatched): resubmit Momus + independent Oracle fresh. Both must return unconditional APPROVE. If REQUEST-CHANGES, fix + repeat. Do NOT hand off until both APPROVE (review_required=true).

ROUND 8 PARTIAL: Momus (bg_bfe8307d) = APPROVE (round-7 fixes landed: token-rotate ns cutover prereq, success-criteria in-plan/cutover split, T14 enhanced-operator scoping; nothing regressed). Oracle (bg_294b51fe) = RUNNING (not stuck - normal 4-16min Oracle runtime; last tool read). Awaiting Oracle verdict. If Oracle APPROVE -> dual review SATISFIED (both approve) -> present final summary, stop for user go-ahead to $start-work. If REQUEST-CHANGES -> fix + resubmit both fresh (round 9).

=== ROUND 8 RESULT: Momus APPROVE + Oracle (bg_294b51fe) REQUEST-CHANGES ===
Oracle verified all 3 round-7 items resolved; found ONE new bootstrap bug (code-grounded) + 2 related tightenings - ALL FIXED:
- Bootstrap deadlock: shootAccess Secret is SEED-rendered (T8) but operator defaults shoot-first (controller.go:165) and reads shootAccess before seed apply (:331-337), skipping seed apply if Secret missing (:186-207) -> deadlock. FIX: CR MUST set spec.applyOrder: SeedFirst. Applied to T14 + T16 (+ acceptance `.spec.applyOrder=="SeedFirst"`), A.8 (mandatory-for-v2 rationale), A.10.
- T16 CR namespace: metadata.namespace MUST be seed CP ns shoot--cp--m-<region> (operator applies seed into cr.Namespace; must match token-rotate target). FIX: T16 sources namespace from dualDeploymentOperatorCR.namespace fallback .Release.Namespace + acceptance asserts `.metadata.namespace==shoot--cp--m-qa-de-1`; A.10 documents it.
- applyOrder default in values: T16 values.yaml ships applyOrder: SeedFirst (the one non-empty default; a fixed correctness value).
Oracle VERIFIED-OK: token-rotate ns prereq correct; success criteria split; T14 enhanced-operator; no OTHER seed-object namespace blocker (macdb/kubeconfigs/Services/Ingress/NetworkPolicies are seed-local; shootNamespace=kube-system only affects unqualified shoot objects).
Verified applyOrder: SeedFirst threaded through T14/T16/A.8/A.10 consistently.

ROUND 9 (dispatched): resubmit Momus + independent Oracle fresh. Both must return unconditional APPROVE. If REQUEST-CHANGES, fix + repeat. Do NOT hand off until both APPROVE (review_required=true).