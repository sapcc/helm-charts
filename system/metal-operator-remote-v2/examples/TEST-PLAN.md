# Test Plan — metal-operator-remote-v2 via dual-deployment-operator

> **Goal:** Prove the `dual-deployment-operator` renders `metal-operator-remote-v2`
> twice (seed + shoot) and applies both renders correctly, using a **throwaway
> workerless shoot** so the production metal shoot `m-qa-de-1` is never touched.
>
> **Status:** planning. Nothing below has been executed.

---

## 0. Environment (validated facts)

| Thing | Value |
|---|---|
| Test shoot | `test-qa-de-1` (garden `g-qa-de-1`, project `cp`, ns `garden`), openstack, **workerless**, purpose `evaluation`, status **Succeeded** |
| Test shoot apiserver | `https://api.test-qa-de-1.cp.external.rt-qa-de-1.soil-garden.qa-de-1.cloud.sap` |
| Seed | `rt-qa-de-1` |
| Test shoot CP namespace (on seed) | `shoot--cp--test-qa-de-1` (exists) |
| Operator install namespace | `shoot--cp--test-qa-de-1` (the shoot CP namespace — see §2b for why, not a standalone ns) |
| secrets-injector on seed | present (`secrets-injector` ns) — resolves macdb `vault+kvv2://` |
| operator patch-render-scoping | must be ≥ `c37a676` (built into the image below) |

**Registry note (resolve before step 1):** the chart publish workflow
(`.github/workflows/helm-push-from-input.yaml`) pushes to **`ghcr.io/sapcc/helm-charts`**,
and the example CR points there. The task text says "push to keppel". Pick ONE and keep
the CR `spec.source.helm.repo` consistent with wherever the chart actually lands.
Options:
- **ghcr** (matches the repo workflow + example CR as-is): `oci://ghcr.io/sapcc/helm-charts`.
- **keppel** (manual): push to e.g. `oci://keppel.eu-de-1.cloud.sap/ccloud-helm` and
  set the CR repo to match. If keppel needs auth, the CR needs a `source.helm.authSecretRef`
  (a Secret with `username`/`password`/`token` in the CR's namespace).

---

## 1. Publish the `metal-operator-remote-v2` chart

**Where:** local workstation (has helm + registry creds) or the GitHub workflow.
**Target:** the OCI registry the CR will pull from (see Registry note).

### Option A — GitHub workflow (ghcr, no manual creds)
Trigger `helm-push-from-input.yaml` (workflow_dispatch) with `chartDir=system/metal-operator-remote-v2`.
It runs `helm dependency update → helm package → helm push` and bundles the subchart tarball.

### Option B — manual push (keppel or ghcr)
```bash
cd system/metal-operator-remote-v2
helm dependency update .                       # pulls metal-operator 0.6.2-crds into charts/
helm package .                                 # -> metal-operator-remote-v2-0.1.0.tgz (bundles subchart)
# ghcr:
helm push metal-operator-remote-v2-0.1.0.tgz oci://ghcr.io/sapcc/helm-charts
# OR keppel:
# helm push metal-operator-remote-v2-0.1.0.tgz oci://keppel.eu-de-1.cloud.sap/ccloud-helm
```

> **`helm push` URL = registry + NAMESPACE ONLY. Do NOT append the chart name or a `:tag`.**
> Helm derives BOTH the repo name and the tag from the `.tgz`'s own `Chart.yaml`
> (`name: metal-operator-remote-v2`, `version: 0.1.0`). So the command above pushes to
> `.../ccloud-helm/metal-operator-remote-v2:0.1.0` automatically.
> - ❌ `oci://.../ccloud-helm/metal-operator-remote-v2:0.0.1` → **"invalid tag"** (a tag in the
>   URL is illegal here) AND it would double the name (`.../metal-operator-remote-v2/metal-operator-remote-v2`).
> - The pushed tag is ALWAYS the chart `version` (`0.1.0`); any tag you type is ignored/rejected.
> - To publish a different version, bump `version:` in `Chart.yaml` and re-`helm package` —
>   not via the push URL.

**Verify:**
```bash
# repo = registry/namespace/<chart-name>; version = chart version (0.1.0)
helm show chart oci://<registry>/<namespace>/metal-operator-remote-v2 --version 0.1.0   # exit 0
# e.g. keppel: oci://keppel.eu-de-1.cloud.sap/ccloud-helm/metal-operator-remote-v2
```

**Gate:** chart pullable from the registry the CR references. The CR's
`spec.source.helm` must then be: `repo: oci://<registry>/<namespace>` (NO chart name),
`name: metal-operator-remote-v2`, `version: 0.1.0`. `charts/*.tgz` must NOT be
committed to git (gitignored); it only lives inside the pushed artifact.

---

## 2. Build + push the operator image, then install the operator on the seed

**Repo:** `dual-deployment-operator` (separate repo — NOT this one).
**Where:** operator image build on a workstation with docker + registry push; install
targets the **seed `rt-qa-de-1`**.

> **Install via the operator's Helm chart** (branch `feature/deployment-chart-helm`,
> path `chart/`). Prefer this over the raw `make deploy`/kustomize path — the chart
> already encodes the two things a seed CP-namespace deployment REQUIRES:
> 1. **Gardener egress pod labels** (`networking.gardener.cloud/to-dns`,
>    `to-public-networks`, `to-private-networks`) — without these the seed's deny-all
>    NetworkPolicy blocks the operator's OCI pulls + DNS.
> 2. **A writable scratch emptyDir** at `--source-scratch-dir=/var/run/ddo-source`
>    (root FS is read-only) for the chart/source loader.

### 2a. Build + push the image
The chart image defaults to `ghcr.io/SAP-cloud-infrastructure/dual-deployment-operator`
(tag = Chart appVersion). Build a real image the seed can pull:
```bash
cd <dual-deployment-operator>
git checkout feature/deployment-chart-helm
git log --oneline -1          # confirm the branch includes patch render-scoping (>= c37a676)
export IMG=keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator:<tag>
make docker-build IMG=$IMG    # linux/amd64 image, stamps the source_repository label Keppel requires
make docker-push  IMG=$IMG    # docker push $IMG
```
(Use a registry the seed can pull from; keppel dev repo mirrors the metal images.)

> **Two things the `docker-build` target handles for you** (a plain `docker build -t $IMG .`
> does NOT — use `make`):
> 1. **Platform** — builds `linux/amd64` (`PLATFORM ?= linux/amd64`; override with
>    `make docker-build PLATFORM=...`). The seeds are amd64, so on an arm64 dev machine a
>    plain `docker build` produces an arm64 image the seed CANNOT pull
>    (`no matching manifest for linux/amd64`).
> 2. **Registry policy** — stamps the `source_repository` OCI label
>    (`SOURCE_REPO ?=` default; override with `make docker-build SOURCE_REPO=...`). Keppel's
>    `cloud-infrastructure-dev` account rejects any push lacking that label (or an in-toto
>    attestation layer): `... does not satisfy validation rule: 'source_repository' in labels
>    || layers.exists(...)`.
>
> The target builds with `docker buildx --builder default --load` (the plain docker driver +
> containerd image store cross-loads amd64 fast). A `docker-container` builder makes `--load`
> crawl on the tarball round-trip; the `--builder default` pin avoids that.

### 2b. Install the operator chart on the seed — INTO the shoot CP namespace
Install into the shoot CP namespace **`shoot--cp--test-qa-de-1`** (NOT a standalone
`dual-deployment-operator-system`), **always via the u8s alias layer (`ukc` + `uhup`)** so it targets the right
cluster (u8s owns the kubeconfig + auth for `rt-qa-de-1`).

> **Why the shoot CP namespace, not a dedicated one:**
> - This mirrors production: `metal-operator-remote` runs per-shoot in `shoot--cp--m-<region>`
>   on the seed. The operator is meant to run in the same CP namespace it manages.
> - **NetworkPolicy egress only works there.** The CP namespace has a `deny-all` policy plus
>   Gardener label-gated allow policies (`allow-to-dns`, `allow-to-public-networks`,
>   `allow-to-private-networks`). The operator chart's pod labels
>   (`networking.gardener.cloud/to-dns|to-public-networks|to-private-networks: allowed`)
>   are designed to match exactly those — so its OCI pulls + DNS succeed. A standalone
>   namespace has none of those allow policies.
> - The `shootAccess` Secret `metal-operator-remote-kubeconfig` is read from the CR's
>   namespace; co-locating operator + CR + Secret + seed-render objects in one namespace
>   keeps the flow coherent.
>
> Install via the u8s oh-my-zsh alias layer: `ukc` sets the session context, then the
> `uh*` helm aliases inherit it. `uhup` = `u8s helm -- upgrade`, `uh` = `u8s helm --`.
> (`u8s helm` cannot take a `--context` flag, so the context is set on the session via `ukc`.)
```bash
cd <dual-deployment-operator>/chart
ukc rt-qa-de-1                       # set session context to the seed (u8s set --context)
# If a prior install left a crashlooping release (e.g. installed without
# ENABLE_WEBHOOKS=false), remove it first for a clean slate:
#   uhun -n shoot--cp--test-qa-de-1 dual-deployment-operator   # CRD is kept (crd.keep=true)
uhup --install dual-deployment-operator . \
  --namespace shoot--cp--test-qa-de-1 \
  --set manager.image.repository=keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator \
  --set manager.image.tag=<tag> \
  --set manager.envOverrides.ENABLE_WEBHOOKS=false
# The CP namespace already exists (Gardener-managed) — no --create-namespace.
# CRD is installed by the chart (crd.enabled=true, crd.keep=true).
# rbac.namespaced=false (default) → ClusterRole/Binding so the operator can SSA-apply
# cluster-scoped shoot objects (VWC, ClusterRoles, Namespace) — keep it false.
```
> **`ENABLE_WEBHOOKS=false` is REQUIRED with `certManager.enabled=false` (the default).**
> The operator binary enables its own validating-admission webhook unless
> `ENABLE_WEBHOOKS=false` (`cmd/main.go:208`), and the webhook server needs a TLS cert at
> `/tmp/k8s-webhook-server/serving-certs/tls.crt`. With cert-manager off, no cert is
> mounted → the manager exits with `open .../tls.crt: no such file or directory` →
> **CrashLoopBackOff**. The operator's own admission webhook is just CR validation and is
> not needed to test dual-deployment rendering, so disable it. (Alternative: install
> cert-manager and `--set certManager.enabled=true` — only if you specifically want the
> admission webhook.)
> Fallback without the alias plugin: `U8S_CONTEXT=rt-qa-de-1 u8s helm3 upgrade --install
> dual-deployment-operator . --namespace shoot--cp--test-qa-de-1 --set ...`

**Verify:**
```bash
u8s kubectl --context rt-qa-de-1 get crd | grep dualdeployment
u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1 get deploy,pod -l app.kubernetes.io/name=dual-deployment-operator
# controller pod Running/Ready; egress pod-labels present; scratch volume mounted; no DNS/egress errors
u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1 logs deploy/dual-deployment-operator-controller-manager | tail -20
uh -n shoot--cp--test-qa-de-1 status dual-deployment-operator   # uh = u8s helm --
```

**Gate:** CRD `dualdeploymentoperators.dual-deployment-operator.cc.sap` present; controller
Running in `shoot--cp--test-qa-de-1` (no crashloop, no egress/DNS errors in logs); ClusterRole
present (rbac.namespaced=false).

---

## 3. Apply the DualDeploymentOperator CR (targeting the test shoot)

**Where:** the seed `rt-qa-de-1`, into the test shoot's CP namespace
`shoot--cp--test-qa-de-1`.

### 3a. Prepare the CR
Copy `examples/dualdeploymentoperator-a-qa-de-200.yaml` and swap the cluster-identity
fields for `test-qa-de-1`:

| Field | Value for the test |
|---|---|
| `metadata.namespace` | `shoot--cp--test-qa-de-1` |
| `spec.shootAccess.server` | `https://api.test-qa-de-1.cp.external.rt-qa-de-1.soil-garden.qa-de-1.cloud.sap` |
| `values.controllerManager.manager.env.KUBERNETES_SERVICE_HOST` | `api.test-qa-de-1.cp.external.rt-qa-de-1.soil-garden.qa-de-1.cloud.sap` |
| `spec.source.helm.repo` | must match where step 1 pushed the chart |
| `spec.source.helm.version` | `0.1.0` |
| `virtualGardenLBIP` | the test seed's virtual-garden LB IP (read from the seed) |
| `spec.shootNamespace` | `kube-system` (unchanged — load-bearing) |
| `spec.applyOrder` | `SeedFirst` (unchanged — mandatory) |

Keep `macdb` as `vault+kvv2://` refs (secrets-injector resolves on the seed).
If the registry needs auth, add `spec.source.helm.authSecretRef` + create that Secret in
`shoot--cp--test-qa-de-1`.

### 3b. Apply + watch
```bash
u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1 apply -f dualdeploymentoperator-test-qa-de-1.yaml
u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1 get dualdeploymentoperator -w
u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1 logs -f deploy/dual-deployment-operator-controller-manager
```

---

## 4. Verify — seed render (on `rt-qa-de-1`, ns `shoot--cp--test-qa-de-1`)

```bash
S="u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1"
$S get deploy metal-operator-controller-manager           # 1/1, sidecar present
$S get deploy metal-operator-controller-manager -o yaml | grep -A2 initContainers   # webhook-injector
$S get secret macdb -o jsonpath='{.data.macdb\.yaml}' | base64 -d | grep -c vault+kvv2   # 0 = resolved by secrets-injector (creds present, no vault refs left)
$S get secret metal-operator-remote-kubeconfig -o jsonpath='{.data.token}' | wc -c       # >0 = Gardener minted the token
$S get svc metal-operator-remote-webhook-service metal-operator-metal-registry-service
$S get ingress metal-operator-metal-registry-ingress
$S get networkpolicy | wc -l                              # 6 (+header)
$S get cm remote-kubeconfig
```
**Expect:** exactly the A.2 seed set; NO shoot-only objects; NO `metal-token-rotate*`.

---

## 5. Verify — shoot render (on the test shoot `test-qa-de-1`)

```bash
H="kubectl --kubeconfig test-qa-de-1.kubeconfig"    # u8s can't reach the shoot; see open item 6
$H get crd | grep metal.ironcore.dev                       # upstream CRDs
$H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o yaml \
  | grep -E 'url:|caBundle:|labels:' | head                # url rewritten to metal-operator-remote-webhook-service:443
$H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration -o yaml \
  | yq '.metadata.labels."dual-deployment-operator.cc.sap/webhook-injector"'   # == metal-operator  (label patch landed)
$H -n kube-system get sa metal-operator-controller-manager # SA in kube-system (shootNamespace)
$H get clusterrole metal-api-viewer metal-operator-dns-records metal-operator-webhook-injector
$H get clusterrolebinding | grep 'cc:oidc-ias'             # 4 bindings
$H get ns metal-servers
```
**Expect:** the A.3 shoot set; VWC present with the injector label AND caBundle patched
by the webhook-injector (the real end-to-end proof that r7 target-patch works); NO seed
objects; NO `metal-token-rotate` RBAC.

### 5a. The critical end-to-end check (why the whole test exists)
```bash
# caBundle must become non-empty after the injector patches it (proves target-patch mode +
# the label patch + operator >= c37a676 all work together):
$H get validatingwebhookconfiguration metal-operator-validating-webhook-configuration \
  -o jsonpath='{.webhooks[0].clientConfig.caBundle}' | wc -c    # >0 after injector runs
```

---

## 6. Adversarial / negative checks

- **applyOrder bootstrap:** confirm the seed render applied first (the `metal-operator-remote-kubeconfig`
  Secret existed before the operator read shootAccess). If it deadlocked, `applyOrder` is wrong.
- **No prod impact:** `u8s kubectl --context rt-qa-de-1 -n shoot--cp--m-qa-de-1 get deploy metal-operator-controller-manager`
  still the live v55 release, untouched; `m-qa-de-1` VWC/Servers unchanged.
- **macdb self-heal:** delete the resolved macdb Secret; operator re-applies stringData;
  secrets-injector re-resolves. (A.9 live-cluster behavior.)
- **Idempotent reconcile:** re-trigger reconcile; no duplicate objects, no churn.

---

## 7. Teardown (ORDER MATTERS)

```bash
# 1. Delete the CR FIRST so the operator tears down what it applied (seed + shoot).
u8s kubectl --context rt-qa-de-1 -n shoot--cp--test-qa-de-1 delete dualdeploymentoperator <name>
# 2. Confirm seed + shoot objects are gone.
# 3. Uninstall the operator (optional if the seed is disposable):
#    uhun -n shoot--cp--test-qa-de-1 dual-deployment-operator   # uhun = u8s helm -- uninstall (ukc rt-qa-de-1 first)
#    (CRD is kept by default: crd.keep=true — delete it manually if you want a clean slate.)
# 4. Delete the test shoot from the Gardener dashboard (g-qa-de-1 / garden / test-qa-de-1).
# 5. Optional: remove the pushed chart version + operator image if they were throwaway.
```

---

## Open items to resolve before executing

1. **Registry decision:** ghcr (workflow, matches CR) vs keppel (manual). Keep CR repo consistent.
2. **Operator image registry:** which registry can `rt-qa-de-1` pull the operator image from + tag.
3. **`virtualGardenLBIP`** for the test seed — read the real value.
4. **Registry auth:** if the chart registry is private, create the `authSecretRef` Secret in
   `shoot--cp--test-qa-de-1`.
5. **Seed access = always u8s.** Target `rt-qa-de-1` via `u8s kubectl --context rt-qa-de-1`
   and `U8S_CONTEXT=rt-qa-de-1 u8s helm3 ...` (helm3 takes context via env var, not `--context`).
   Never use a raw `helm`/`kubectl` — u8s owns the seed kubeconfig + auth.
6. **Test-shoot access:** `u8s` does NOT know `test-qa-de-1` (not registry-enrolled). Reach it
   via a Gardener admin kubeconfig from `g-qa-de-1`:
   ```bash
   printf '%s' '{"apiVersion":"authentication.gardener.cloud/v1alpha1","kind":"AdminKubeconfigRequest","spec":{"expirationSeconds":3600}}' \
     | u8s kubectl --context g-qa-de-1 create -f - \
       --raw /apis/core.gardener.cloud/v1beta1/namespaces/garden/shoots/test-qa-de-1/adminkubeconfig \
     | yq -r '.status.kubeconfig' | base64 -d > test-qa-de-1.kubeconfig
   # then: kubectl --kubeconfig test-qa-de-1.kubeconfig get ns
   ```
   Use this kubeconfig for the §5 shoot-render checks (the operator itself reaches the shoot
   via its own Gardener token-requestor `shootAccess`, independent of this).
