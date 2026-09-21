# `metal-token-rotate` decommission — what happened & impact on `metal-operator-remote-v2`

**Date of finding:** 2026-08-06
**Author of finding:** investigation during `metal-operator-remote-v2` planning review
**One-line:** `metal-token-rotate` was removed from `metal-operator-remote` upstream (PR #12502, 2026-08-05) and replaced by Gardener **WorkloadIdentity** auth. The `-v2` plan was written against the pre-decommission chart, so its `metal-token-rotate` work (T8 rotate Secret, T11 RBAC, the namespace-alignment cutover gate) is obsolete and must NOT be ported.

---

## 1. What `metal-token-rotate` was

`metal-token-rotate` ([ironcore-dev/metal-token-rotate](https://github.com/ironcore-dev/metal-token-rotate)) was a controller that issued short-lived ServiceAccount tokens (via the TokenRequest API) so the remote metal control-plane controllers — **metal-operator**, argora, boot-operator, capi ipam — could authenticate against the workerless `metalapi` shoot. The tokens were delivered as static JWTs in Gardener token-requestor Secrets and propagated via Garden/Seed secrets.

Inside the `metal-operator-remote` chart it manifested as two things:

1. **`templates/rotate-kubeconfig.yaml`** — a Gardener token-requestor Secret `metal-token-rotate-kubeconfig` (embedded kubeconfig, `token: ""` filled by Gardener, CA baked from `.Values.remote.ca`).
2. **`metal-token-rotate` RBAC** in `managedresources/rbac.yaml` — SA + Role + RoleBinding + ClusterRole + ClusterRoleBinding.

Plus a standalone `system/metal-token-rotate/` chart (the controller deployment itself) and per-shoot secrets in `cc-shoots{,-compute,-storage}`.

## 2. What replaced it

**Gardener Workload Identity** — projected, auto-rotated ServiceAccount tokens. Instead of a controller minting static JWTs into etcd-stored Secrets, the Kubelet on the seed requests short-lived tokens from the shoot `kube-apiserver` (TokenRequest API) and projects them directly into the consuming pod's filesystem. This eliminates long-lived tokens in etcd, removes the rotation controller, and aligns with the security standard.

## 3. The decommission — who & when

**Primary owner: Anton Paulovich** (`C5412600` on github.wdf.sap.corp / `anton-paulovich` on github.com).

| Person | Login(s) | Role |
|---|---|---|
| **Anton Paulovich** | `C5412600`, `anton-paulovich` | Lead. Built the WorkloadIdentity auth (#1181), authored the QA migration/cleanup (#1209), authored & merged the chart-removal PR #12502. |
| **Dmitri Fedotov** | `c5267192` | Opened the evaluation (#1168); co-assignee on #1209; drove the qa-de-200 LAB rollout (#1288). |
| **Fabian Ruff** | `d062284` | Assignee on the evaluation (#1168) and the WorkloadIdentity auth feature (#1181). |

### Tracking issues (github.wdf.sap.corp/cc/unified-kubernetes)

1. **[#1168](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1168)** "[Metal] Evaluate replacing metal-token-rotate with structured authentication" — Dmitri Fedotov, closed 2026-05-28. The evaluation: replace the static-token flow with structured/WorkloadIdentity auth for the remote controllers (argora, boot-operator, **metal-operator**, capi ipam).
2. **[#1181](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1181)** "Support WorkloadIdentity-based authentication for metal-api" — Anton Paulovich, closed 2026-06-11. Builds the replacement: Gardener Workload Identity via projected SA tokens, eliminating static JWTs in etcd.
3. **[#1209](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1209)** "Migrate metal-token-rotate to Kubernetes Workload Identity on QA" — Anton Paulovich + Dmitri Fedotov, closed 2026-07-20. Depends on #1181; platform/trust setup + rollout to shoots + **final cleanup**.
4. **Still open:** [#1351](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1351) "Migrate ironcore-metal infra to use new auth flow against metalAPI in **Prod**" — QA is done, Prod is in flight.

### The code removal — PR #12502

**[sapcc/helm-charts#12502](https://github.com/sapcc/helm-charts/pull/12502)** "metal-token-rotate decomission" — Anton Paulovich, merged **2026-08-05 13:08 UTC**.
PR body: *"At this point we use WorkloadIdentity authentication for metal infra."*
Git commit: `5d9a933f8ae2108d96936e79bee6eda28f96caff` on `origin/master`. It bumped `metal-operator-remote` `0.6.30`→`0.6.31` and deleted:

- `system/metal-operator-remote/templates/rotate-kubeconfig.yaml` (31 lines)
- the `metal-token-rotate` block in `system/metal-operator-remote/managedresources/rbac.yaml` (60 lines)
- the entire `system/metal-token-rotate/` chart
- token-rotate secrets in `system/cc-shoots/`, `cc-shoots-compute/`, `cc-shoots-storage/`

(19 files changed, +4 / −457.)

## 4. Live-cluster evidence (via u8s)

Confirmed against QA on 2026-08-06:

| Cluster / namespace | Chart version | `metal-token-rotate` objects |
|---|---|---|
| `rt-qa-de-1` / `shoot--cp--m-qa-de-1` | **0.6.31** (post-decommission, re-rolled 8h prior) | **ZERO** — no rotate Secret, no token-rotate RBAC |
| `a-qa-de-200` / `shoot--cp--m-qa-de-200` | **0.6.30** (not yet re-rolled) | Stale `metal-token-rotate-kubeconfig` Secret + `mr-*-metal-token-rotate` RBAC still present |

The decoded helm release manifest for `rt-qa-de-1` v55 (0.6.31) has **0** occurrences of `metal-token-rotate`; `a-qa-de-200` v26 (0.6.30) still has it. The difference is purely the chart-version bump from #12502 — `a-qa-de-200` will lose these objects on its next re-roll.

> Note on the earlier (pre-decommission) namespace concern: the plan claimed a mismatch between a kube-secrets target `shoot--ccloud--metal-operator` and the operator apply namespace `shoot--cp--m-<region>`. The live release actually deployed into `shoot--cp--m-qa-de-200` (= `cr.Namespace`), so even absent the decommission the "mismatch" did not reflect the cluster. The decommission makes it fully moot.

## 5. `a-qa-de-200` token-requestor Secret details

Read-only `u8s` inspection on 2026-08-06 confirmed that the relevant objects live in the **seed/control-plane namespace** for the shoot:

- Context: `a-qa-de-200`
- Namespace: `shoot--cp--m-qa-de-200`
- Helm release still present: `metal-operator-remote` chart **0.6.30**

The metal-related token-requestor Secrets in that namespace are:

| Secret | Helm release | Requested shoot ServiceAccount | Data shape | Status |
|---|---|---|---|---|
| `metal-operator-remote-kubeconfig` | `metal-operator-remote` | `kube-system/metal-operator-controller-manager` | `token`, `bundle.crt` | Still valid for the current chart; remains the single token-requestor Secret in the `-v2` plan. |
| `metal-token-rotate-kubeconfig` | `metal-operator-remote` | `kube-system/metal-token-rotate` | embedded `kubeconfig` | Stale pre-decommission object; removed by chart 0.6.31+. |

Both Secrets are marked as Gardener token-requestors by the same label pair:

```yaml
resources.gardener.cloud/purpose: token-requestor
resources.gardener.cloud/class: shoot
```

The live annotations show which ServiceAccount token Gardener should request and that Gardener has already renewed/injected the data:

```yaml
serviceaccount.resources.gardener.cloud/name: <serviceaccount-name>
serviceaccount.resources.gardener.cloud/namespace: kube-system
serviceaccount.resources.gardener.cloud/token-renew-timestamp: <timestamp>
cloud.sap/injected-refs: <redacted injected token/CA references>
```

For `metal-operator-remote-kubeconfig`, the chart template is `system/metal-operator-remote/templates/remote-kubeconfig.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: metal-operator-remote-kubeconfig
  labels:
    resources.gardener.cloud/purpose: token-requestor
    resources.gardener.cloud/class: shoot
  annotations:
    serviceaccount.resources.gardener.cloud/name: metal-operator-controller-manager
    serviceaccount.resources.gardener.cloud/namespace: kube-system
    serviceaccount.resources.gardener.cloud/inject-ca-bundle: "true"
stringData:
  token: ""
  bundle.crt: ""
```

For `metal-token-rotate-kubeconfig`, the old pre-decommission template is `system/metal-operator-remote/templates/rotate-kubeconfig.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: metal-token-rotate-kubeconfig
  labels:
    resources.gardener.cloud/purpose: token-requestor
    resources.gardener.cloud/class: shoot
  annotations:
    serviceaccount.resources.gardener.cloud/name: metal-token-rotate
    serviceaccount.resources.gardener.cloud/namespace: kube-system
stringData:
  kubeconfig: |
    users:
    - name: metal-token-rotate
      user:
        token: ""
```

Generation flow:

1. Helm renders the placeholder Secret into `shoot--cp--m-qa-de-200`.
2. Gardener resource-manager detects `resources.gardener.cloud/purpose: token-requestor` and `resources.gardener.cloud/class: shoot`.
3. It reads the `serviceaccount.resources.gardener.cloud/*` annotations to identify the shoot ServiceAccount.
4. It calls the shoot kube-apiserver TokenRequest API for that ServiceAccount.
5. It writes the generated token, and CA bundle when requested, back into the Secret data and updates `serviceaccount.resources.gardener.cloud/token-renew-timestamp`.

Do not confuse the token-requestor Secrets with the `mr-*-metal-token-rotate` Secrets seen in the same namespace. The `mr-*` Secrets contain `objects.yaml` ManagedResource payloads for ServiceAccounts/Roles/Bindings/ClusterRoles; they are Helm-managed object bundles, not generated ServiceAccount tokens.

## 6. Why the `-v2` plan was wrong about this

The `-v2` plan (`.omo/plans/metal-operator-remote-v2.md`) lives on branch `metal-operator-remote-v2-redesign-report`, which **forked before** commit `5d9a933f8a`. So it captured a snapshot of `metal-operator-remote` that still contained `metal-token-rotate`, and faithfully planned to port it:

- **T8** — port `rotate-kubeconfig.yaml` (add `inject-ca-bundle:"true"`, set `certificate-authority-data:""`, drop `remote.ca`).
- **T11** — emit the `metal-token-rotate` SA/Role/RoleBinding/ClusterRole/ClusterRoleBinding.
- **Related work / Success criteria** — a "kube-secrets namespace-alignment hard pre-cutover gate".

All three are obsolete: the source template + RBAC no longer exist, and WorkloadIdentity means there is no static-token Secret to rotate or align.

## 7. Corrective actions taken in the plan

Edited `.omo/plans/metal-operator-remote-v2.md`:

- **TL;DR / Decisions** — added a "⚠️ DECOMMISSION - READ FIRST" banner + rebase prerequisite; changed "both token-requestor Secrets" → the single `metal-operator-remote-kubeconfig`.
- **Scope (Must have / Must NOT have)** — seed set now lists one token-requestor Secret; shoot set drops token-rotate RBAC; added an explicit "MUST NOT port `metal-token-rotate`" rule.
- **T8** — rewritten to emit only `remote-kubeconfig` ConfigMap + `metal-operator-remote-kubeconfig` Secret; acceptance asserts `grep -R 'metal-token-rotate' templates` is EMPTY.
- **T11** — retitled/rescoped to webhook-injector RBAC only; drops `token-rotate-rbac.yaml`.
- **F3 / A.2 / A.3 / A.6** — removed `metal-token-rotate` from the expected seed/shoot object sets and appendix facts; `rotate-kubeconfig.yaml` marked DELETED-upstream.
- **T14 / T16 / A.10** — removed the namespace-alignment header comments.
- **Success criteria CUTOVER + Related work** — replaced the namespace-alignment gate with the decommission provenance (PR #12502, tracking issues, cluster evidence) and a rebase instruction.

## 8. Recommended next steps (not yet done)

1. **Rebase** `metal-operator-remote-v2-redesign-report` onto `origin/master` (which includes `5d9a933f8a`) before implementing `-v2`, so the working-tree `metal-operator-remote` matches the post-decommission source.
2. When implementing, verify `grep -R 'metal-token-rotate' system/metal-operator-remote-v2/` is empty.
3. Coordinate with **Anton Paulovich** / **Dmitri Fedotov** if any `-v2` cutover timing interacts with the in-flight Prod WorkloadIdentity migration (#1351).

## 9. Sources

- PR: https://github.com/sapcc/helm-charts/pull/12502 (commit `5d9a933f8a`)
- Issues: cc/unified-kubernetes #1168, #1181, #1209, #1351 (github.wdf.sap.corp)
- Live clusters (u8s): `rt-qa-de-1` / `shoot--cp--m-qa-de-1`, `a-qa-de-200` / `shoot--cp--m-qa-de-200`
- Plan: `.omo/plans/metal-operator-remote-v2.md`
