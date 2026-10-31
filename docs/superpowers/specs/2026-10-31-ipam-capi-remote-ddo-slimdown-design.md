# ipam-capi-remote-ddo overlay slim-down — design

**Status:** approved; implemented in draft migration PR #13218, release-gated
**Date:** 2026-10-31
**Author:** orchestrator (with D065300)
**Premise:** this change is **gated on DDO issue #58** (safe `source.kustomize`
remote-base support — prefetch + resolve-tag-to-SHA + cache + offline build)
landing. It does **not** ship until that operator feature exists. See
"Constraints" and "Non-goals".

Supersedes nothing; this is a follow-up refactor of the overlay delivered in
helm-charts PR #13218 (`system/kustomize/ipam-capi-remote-ddo`).

---

## 1. Intent / why

The `ipam-capi-remote-ddo` overlay is a DDO `source.kustomize` wrapper that
delivers the CAPI-IPAM-in-cluster provider across a seed/shoot split. Today it
**vendors all 7 CRDs by hand** into `shoot/crds/`:

| file | lines |
| --- | ---: |
| `clusters.yaml` | 5,243 |
| `ipaddressclaims.yaml` | 723 |
| `ipaddresses.yaml` | 387 |
| `globalinclusterippools.yaml` | 336 |
| `inclusterippools.yaml` | 330 |
| `globalinclusterprefixpools.yaml` | 169 |
| `inclusterprefixpools.yaml` | 165 |
| **total** | **7,453** |

That is **79 % of the whole 9,410-line overlay**, and it references upstream
**nowhere** — it is a point-in-time copy. This is the review/maintenance
objection raised against the overlay: there is no reviewable provenance, drift
from upstream is silent, and a bump is a manual re-capture of thousands of
lines (`clusters.yaml` alone is 5.2k).

The sibling Helm `-ddo` charts (metal/boot/argora) do **not** vendor — they
declare the upstream chart as a **pinned subchart dependency** and keep only
SAP additions. The kustomize-native equivalent of a pinned subchart is a
**`?ref=`-pinned remote base**. The goal is to make `ipam-capi-remote-ddo` a
**slim wrapper that references pinned upstream** and keeps only the genuine SAP
additions — the same principle the Helm charts already follow.

**Outcome:** drop all 7 hand-vendored CRDs (−7,453 lines), replace them with
pinned remote references, and re-apply the small SAP deltas as overlay patches.
The overlay shrinks to ~2,000 lines of genuine SAP work plus a handful of
pin/patch files.

---

## 2. Goals / non-goals / anti-goals

**Goals**
- Remove the hand-vendored `shoot/crds/*.yaml` (all 7) from the overlay.
- Source every CRD from **pinned upstream**, pinned by **resolved commit SHA**
  (not a mutable tag), reviewable as a small set of files.
- Preserve byte-for-byte the shoot objects DDO actually applies: all 7 CRDs
  still delivered, same schemas, **same conversion-webhook wiring** on the 4
  pool CRDs, same identities.
- Keep the change a **slim wrapper over origin** — reference, don't copy.

**Non-goals**
- Shipping before DDO issue #58 lands. This design is the plan to execute
  *once* safe remote-base support exists; it is not a request to merge now.
- Changing the controller version, image mirrors, RBAC, webhooks, seed
  Deployment/sidecar, pools, or any seed-side object. Only CRD *sourcing*
  changes.
- Touching the kube-secrets CR (#5683) or the cutover profile (#13167) beyond
  what the SHA-pin requires (none expected — the CR points at the overlay root,
  which is unchanged).

**Anti-goals**
- Pulling a whole upstream kustomize base that injects CRDs ipam does not own
  (see the CAPI core-base rejection in §4).
- Pinning to a tag or branch ref (mutable → non-reproducible renders / drift).
- Letting the conversion-webhook shim (URL + caBundle) be lost in the swap —
  that would break v1alpha1↔v1alpha2 conversion of live pools.

---

## 3. Constraints

- **DDO remote-base support is a hard precondition.** The current DDO
  `source.kustomize` renderer (`internal/source/kustomize.go` +
  `gitresolver.go`) clones only the one `?ref=`-pinned *root* repo and runs
  `krusty` offline against that local tree. A remote base in `resources:`
  triggers krusty's own in-seed git clone — unpinned by DDO, per-reconcile
  egress, outside DDO's fail-closed path. Issue #58 Option B (DDO prefetches +
  resolves-tag-to-SHA + caches + rewrites to local + builds offline) is the
  variant that makes remote bases safe and reproducible. **This design assumes
  #58 Option B behavior: a remote base pinned by `?ref=<commit-SHA>` is
  fetched once, cached SHA-keyed, and built offline.**
- **ipam owns all 7 CRDs.** Legacy `system/ipam-capi-remote/managedresources/
  crds-rbac.yaml` defines every one (including `clusters.cluster.x-k8s.io`).
  The slim overlay must still deliver all 7 — none may silently drop.
- **CRD schema fidelity.** Prior spike proved the 4 pool CRDs' schema bodies are
  **byte-identical** to upstream provider `config/crd/bases@v1.1.1` (controller-gen
  v0.17.2 both sides), minus two SAP deltas (see §4). The 3 core CRD base files
  at the pinned CAPI SHA carry **no** `conversion:` block, no webhook strategy,
  no cert-manager annotation, no move-hierarchy label (verified) → they render
  as-is, no patch needed.
- **Pin by commit SHA.** Provider v1.1.1 → `7933583138cf1b5b16b6a1dd82a804729f83afab`.
  CAPI v1.14.2 → `5f7d58c9ad647f31bd342bf8de33092c27f7fc38`.
- **No upstream Helm chart exists** for CAPI-IPAM-in-cluster (kustomize/clusterctl
  only) — which is why ipam is a kustomize overlay, not a Helm subchart, in the
  first place.

---

## 4. Approaches

All three assume #58, pin by commit SHA, and re-apply the SAP deltas rather than
copying CRDs.

> **Core-CRD mechanism correction (2026-10-31, post builder-check):** the
> original Approach-C plan sourced the 3 core CRDs as per-file **git** resources
> (`//core/config/crd/bases/<file>?ref=<SHA>`). That does **not** work: kustomize
> v5.8.1's git getter only accepts a **directory** base and errors on a single
> remote file (`refers to file '…'; expecting directory`). Verified empirically.
> The legacy `system/kustomize/ipam-capi-remote` tree already solved this: it
> pulls the 3 core CRDs as **plain-HTTP `raw.githubusercontent.com` file URLs**,
> which route through kustomize's HTTP file loader (a different code path that
> *does* fetch single files). A raw URL pins the ref in its **path segment**, and
> a full **commit SHA** works there too (verified) — so the SHA-on-the-safe-side
> requirement still holds. The design below uses the raw-HTTP mechanism for the 3
> core CRDs.

**Approach A — full remote base (loose resources).**
`shoot/crds/` deleted. The 4 pool CRDs come from the provider's native
`config/crd` kustomization as one remote **git dir** base; the 3 core CRDs come
in as three **loose** `resources:` entries, each a SHA-pinned
`raw.githubusercontent.com` file URL. Conversion shim re-applied as
strategicMerge patches over the 4 pool CRDs. Maximum slim. Downside: the three
core pins are three scattered `resources:` lines mixed in with everything else —
less obviously a reviewable unit.

**Approach B — pool-only slim (partial, safe).**
Swap only the 4 pool CRDs to the provider remote base (−~1,000 lines). Keep the
3 core CRDs vendored — so `clusters.yaml` (5,243 lines, 56 % of the overlay)
**stays**. Lowest risk, lowest payoff; leaves the biggest file hand-vendored and
un-referenced, so it does not actually answer the maintenance objection.

**Approach C — pool base + thin in-repo CAPI kustomization (CHOSEN).**
`shoot/crds/` deleted entirely. The 4 pool CRDs come from the provider remote
git dir base. The 3 core CRDs come from a **small in-repo kustomization file**
that lists the three SHA-pinned `raw.githubusercontent.com` file URLs as one
named unit. Same full savings as A (drops all 7 vendored CRDs including
`clusters.yaml`), but the three core pins live in **one small reviewable file**
that is bumped as a unit. Matches the "slim wrapper that references origin"
intent best.

**Rejected mechanism (applies to A and C both):** pulling CAPI's whole
`core/config/crd` git kustomization. It bundles **all 13** core CAPI CRDs
(clusterclasses, clusters, machines, machinesets, machinedeployments,
machinedrainrules, machinepools, clusterresourcesets,
clusterresourcesetbindings, machinehealthchecks, extensionconfigs, ipaddresses,
ipaddressclaims) and wires conversion patches. ipam owns only 3 of those 13;
the whole base would inject 10 unwanted CRDs into the ipam shoot. Non-starter —
and the per-file **git** reference that would avoid it is unsupported by
kustomize — hence the raw-HTTP file URLs.

**Also rejected:** per-file **git** references
(`//core/config/crd/bases/<file>?ref=<SHA>`). Unsupported by kustomize v5.8.1
(git getter demands a directory). The raw-HTTP file URL is the working
equivalent and is what legacy ipam-capi-remote uses.

**Decision: Approach C.** Full savings, pins grouped into one reviewable
in-repo file, using the raw-HTTP file mechanism legacy already proves works.

---

## 5. The design (Approach C, decided parts)

### 5.1 Layout after the change

```
system/kustomize/ipam-capi-remote-ddo/
  shoot/
    kustomization.yaml          # resources: ../base, ../additions/shoot,
                                 #   pool-crds (remote base),
                                 #   core-crds/ (in-repo kustomization),
                                 #   rbac.yaml, webhooks.yaml
                                 # patches: 4 pool conversion-shim patches
    core-crds/
      kustomization.yaml         # 3 SHA-pinned raw.githubusercontent.com file URLs
    crds/                        # DELETED (all 7 vendored files removed)
    rbac.yaml                    # unchanged
    webhooks.yaml                # unchanged
  base/ additions/ seed/ ...     # unchanged
```

### 5.2 Pool CRDs — provider remote base

`shoot/kustomization.yaml` `resources:` gains the provider base in place of the
4 vendored pool files:

```
https://github.com/kubernetes-sigs/cluster-api-ipam-provider-in-cluster//config/crd?ref=7933583138cf1b5b16b6a1dd82a804729f83afab
```

This base emits the 4 pool CRDs with controller-gen v0.17.2 schemas
(byte-identical to today's vendored bodies) **plus** two upstream artifacts we
must correct:

1. **move-hierarchy label** `clusterctl.cluster.x-k8s.io/move-hierarchy: ""` on
   each pool CRD — retain it to preserve today's exact delivered metadata.
2. **conversion clientConfig is SERVICE-ref upstream** (`{namespace: system,
   name: webhook-service, path: /convert}`); ipam needs **URL-ref + concrete
   caBundle** (the webhook-injector endpoint). **Re-apply via patch** (§5.4).

### 5.3 Core CRDs — thin in-repo kustomization (raw-HTTP file URLs)

`shoot/core-crds/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/cluster.x-k8s.io_clusters.yaml
  - https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/ipam.cluster.x-k8s.io_ipaddresses.yaml
  - https://raw.githubusercontent.com/kubernetes-sigs/cluster-api/5f7d58c9ad647f31bd342bf8de33092c27f7fc38/core/config/crd/bases/ipam.cluster.x-k8s.io_ipaddressclaims.yaml
```

**Mechanism note:** these are plain-HTTP `raw.githubusercontent.com` file URLs,
**not** git `//path?ref=` references. Kustomize's git getter only loads a
**directory** base (a single remote file errors with `expecting directory`);
its HTTP file loader fetches a single file. The ref is pinned in the raw URL's
**path segment** — a full **commit SHA** works there (verified), so the pin is
immutable despite not using `?ref=`. This is exactly the mechanism the legacy
`system/kustomize/ipam-capi-remote/managedresources/kustomization.yaml` already
uses for these same 3 core CRDs (it pins the `v1.14.2` tag; we pin the SHA).

These 3 base files carry no conversion block, webhook strategy, cert-manager
annotation or move-hierarchy label. Execution-time parity verification found
the existing bundle explicitly records `conversion: {strategy: None}`; restore
that default with one scoped JSON patch in core-crds. No schemas or pins change.

`shoot/kustomization.yaml` references `core-crds` as a single resource.

### 5.4 Conversion-webhook shim re-apply (the one load-bearing patch)

Each of the 4 pool CRDs must end up with:

```yaml
spec:
  conversion:
    strategy: Webhook
    webhook:
      clientConfig:
        url: https://ipam-capi-remote-webhook-service:443/convert
        caBundle: <base64 webhook-injector cert>
      conversionReviewVersions: [v1]
```

re-applied as a **strategicMerge patch** over the remote-base output (one patch
per CRD name, or one multi-doc patch). This replaces the upstream SERVICE-ref
clientConfig with the URL-ref + caBundle that the DDO/webhook-injector design
uses everywhere else.

**strategicMerge gotcha (builder-check):** strategicMerge *merges* maps, so
setting `clientConfig.url` + `caBundle` alone leaves the upstream
`clientConfig.service` in place — the rendered CRD would carry **both** a
service-ref and a url-ref. The patch MUST explicitly null the service ref:

```yaml
spec:
  conversion:
    webhook:
      clientConfig:
        service: null
        url: https://ipam-capi-remote-webhook-service:443/convert
        caBundle: <base64 webhook-injector cert>
```

**caBundle placement (decided): keep it static in the overlay patch**, matching
how the 4 vendored pool CRDs carry it today. Rationale: it is the
webhook-injector's self-signed CA (`CN=webhook-injector`), identical across the
renders, and already lives in-repo today — moving it to a per-cluster
kube-secrets transformation (the Finding #2 pattern) is a larger change with no
benefit here, since the cert is not per-cluster. If a future cluster needs a
different injector CA, that is a per-cluster CR transformation added then, not
a reason to complicate this refactor. (Builder may revisit if the injector cert
turns out to be per-cluster — see §7.)

### 5.5 What does NOT change

seed overlay (Deployment, r7 sidecar, webhook Service, injector RBAC/metrics/
servicemonitor, token-requestor Secret, remote-kubeconfig ConfigMap, images:
transformer), `shoot/rbac.yaml`, `shoot/webhooks.yaml`, `additions/shoot/
pools.example.yaml`, the kube-secrets CR (#5683) and cutover profile (#13167).

### 5.6 Tests

- `crd_diff_test.sh` is repurposed: instead of diffing vendored files against a
  live capture, it renders `kustomize build shoot/` and asserts the 7 CRDs are
  present with the expected schemas **and** that the 4 pool CRDs carry the
  URL-ref conversion clientConfig + caBundle after the patch (not the upstream
  SERVICE-ref). This is the gate proving the remote base + patch reproduce the
  byte-equivalent delivered shape.
- `render_test.sh` mode-isolation gate is unchanged in intent (shoot has 7
  CRDs; seed has none) but now exercises the remote-base path.
- A render from a fresh/offline checkout must still produce all 7 CRDs (proves
  the pins resolve and the in-repo core kustomization is wired).

### 5.7 Maximize-upstream audit — why only CRDs are fetched

The slim-down principle is *fetch from pinned upstream, vendor only genuine SAP
changes*. Applying it to **every** vendored file (not just CRDs), the fetch
surface turns out to be exactly the 7 CRDs. Each other vendored file was checked
against its upstream origin:

- **`shoot/rbac.yaml` (258 lines) — stays vendored.** The legacy tree fetched
  `//config/rbac?ref=v1.1.1`, so it looks fetchable. But at the pinned SHA that
  directory's `kustomization.yaml` emits (under `namePrefix: ipam-capi-`): SA,
  `manager-role` (= `role.yaml`, byte-identical to vendored lines 8-70), its
  binding, `metrics-reader`, `proxy-role` — **plus an auth-proxy set**
  (`auth_proxy_service`, `auth_proxy_role_binding`,
  `auth_proxy_client_clusterrole`) that is **absent from the live m-qa-de-200
  bundle**, and a **namespaced** `leader-election-role` where live uses a
  **cluster-scoped** `ipam-capi-remote-leader-election-role` (SAP variant).
  Fetching `//config/rbac` wholesale would therefore inject 3 objects not on the
  live cluster and install the wrong-scope leader-election role — breaking the
  `rbac_fidelity_test.sh` live-match guarantee. The remaining 8 objects (metal
  cross-operator bindings, `manager-admin-role`, cluster-scoped leader-election
  role + binding, webhook-injector role + binding) are pure SAP additions with
  no upstream source. Reconciling the divergence would need a `//config/rbac`
  fetch + kustomize `$patch: delete` for the 3 auth-proxy objects + a
  leader-election-scope override + the SAP additions as patches — strictly more
  moving parts that fight the live-match guarantee. Net: vendoring the single
  normalized `shoot/rbac.yaml` is both simpler and safer, so RBAC stays vendored.
- **`shoot/webhooks.yaml` — stays vendored.** It has no upstream origin: the
  legacy tree **intentionally omitted** `config/webhook`, and the
  Mutating/Validating webhook configurations are SAP url-based (the
  webhook-injector endpoint), not the upstream SERVICE-ref form.
- **`additions/seed/*` — stays vendored.** All SAP: the controller Deployment,
  r7 webhook-injector sidecar, webhook Service, injector RBAC/metrics/
  servicemonitor, token-requestor Secret, remote-kubeconfig ConfigMap. No
  upstream counterpart.
- **`additions/shoot/pools.example.yaml` — stays vendored.** SAP example, not
  referenced by the a-qa-de-200 overlay.

Conclusion: the 7 CRDs are the whole upstream-fetch surface; approach C already
captures the entire ~7,453-line (79%) reduction. Everything else is either
genuinely SAP-authored or diverges from upstream in a way that fetching would
make *less* safe, not slimmer.

---

## 6. Merge / rollout

Single helm-charts PR against `system/kustomize/ipam-capi-remote-ddo`. **Must
not merge until DDO issue #58 Option B is released and the operand clusters run
a DDO build that supports safe remote bases** — otherwise the live render
breaks (krusty in-seed clone, unpinned). Because the overlay *root* path and the
seed/shoot subdir names are unchanged, the kube-secrets CR (#5683) needs no
change to its source path. User's execution-time override is to fold this into
the existing PR #13218 and keep it draft/blocked, rather than a separate
follow-up. Related kube-secrets PR #5683 also remains draft and retains the
complete four-entry transformation list. The admin DDO chart's Helm-only CR
renderer additionally needs source.kustomize support before delivery; that
platform prerequisite is not implemented by this CRD-sourcing refactor.

---

## 7. Left to the builder

- **move-hierarchy label:** today's vendored pool CRDs *carry*
  `clusterctl.cluster.x-k8s.io/move-hierarchy: ""`; the provider remote base
  also emits it. Simplest faithful behavior = **leave it** (no patch, matches
  today). Dropping it is optional cleanup — builder decides, but "leave it"
  keeps the delivered shape identical to today.
- **Patch form:** one strategicMerge patch per pool CRD vs. a single multi-doc
  patch — builder's call; assert the result in `crd_diff_test.sh`.
- **caBundle source of truth:** confirm the webhook-injector CA is not
  per-cluster (it is a self-signed `CN=webhook-injector` cert minted by the
  injector sidecar). If it turns out per-cluster, move the caBundle to a
  per-cluster kube-secrets CR transformation instead of the static overlay
  patch; otherwise keep it static (§5.4 default).
- **Exact `patches:` vs `patchesStrategicMerge` syntax** for the installed
  kustomize version (v5.x uses `patches:` with inline or file `path`).
- **DDO #58 acceptance:** before merge, verify the released DDO build actually
  prefetches + SHA-pins + caches + builds offline for the two remote mechanisms
  this overlay uses: (a) a **git dir base** (`?ref=<SHA>` provider `config/crd`)
  and (b) **plain-HTTP `raw.githubusercontent.com` file URLs** (the 3 core CRDs).
  Note #58's original framing mentioned "per-file git base" — that is NOT what
  this overlay uses (kustomize can't do it); the core CRDs are HTTP file fetches,
  so #58's prefetch/cache must cover **HTTP file resources**, not just git bases.
  Also note: raw URLs cannot carry `authSecretRef` (fine — these are public
  repos, and legacy already relies on this exact public HTTP fetch). If #58
  shipped a narrower variant that doesn't cover HTTP file resources, re-scope.
- **Drift-check CI (optional, nice-to-have):** a CI job that re-renders and
  diffs the pool-CRD schemas against the pinned provider commit, so an upstream
  bump that changes schemas is loud. Lower priority than the refactor itself.
