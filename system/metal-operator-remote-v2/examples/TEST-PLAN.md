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
| Operator install namespace | `dual-deployment-operator-system` (from `config/default` kustomize) |
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
make docker-build IMG=$IMG    # docker build -t $IMG .
make docker-push  IMG=$IMG    # docker push $IMG
```
(Use a registry the seed can pull from; keppel dev repo mirrors the metal images.)

### 2b. Install the operator chart on the seed
Install into a dedicated namespace on the seed `rt-qa-de-1`. Point helm at the seed
kubeconfig/context (u8s reaches `rt-qa-de-1`).
```bash
cd <dual-deployment-operator>/chart
helm upgrade --install dual-deployment-operator . \
  --kube-context rt-qa-de-1 \
  --namespace dual-deployment-operator-system --create-namespace \
  --set manager.image.repository=keppel.eu-de-1.cloud.sap/cloud-infrastructure-dev/dual-deployment-operator \
  --set manager.image.tag=<tag>
# CRD is installed by the chart (crd.enabled=true, crd.keep=true).
# rbac.namespaced=false (default) → ClusterRole/Binding so the operator can SSA-apply
# cluster-scoped shoot objects (VWC, ClusterRoles, Namespace) — keep it false.
```
> If `helm --kube-context rt-qa-de-1` isn't wired, export the seed kubeconfig first:
> `KUBECONFIG=$(u8s env | sed -n 's/^export U8S_KUBECONFIG=//p') helm --kube-context rt-qa-de-1 ...`

**Verify:**
```bash
u8s kubectl --context rt-qa-de-1 get crd | grep dualdeployment
u8s kubectl --context rt-qa-de-1 -n dual-deployment-operator-system get deploy,pod
# controller pod Running/Ready; egress pod-labels present; scratch volume mounted
u8s kubectl --context rt-qa-de-1 -n dual-deployment-operator-system logs deploy/dual-deployment-operator-controller-manager | tail -20
helm --kube-context rt-qa-de-1 -n dual-deployment-operator-system status dual-deployment-operator
```

**Gate:** CRD `dualdeploymentoperators.dual-deployment-operator.cc.sap` present; controller
Running (no crashloop, no egress/DNS errors in logs); ClusterRole present (rbac.namespaced=false).

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
u8s kubectl --context rt-qa-de-1 -n dual-deployment-operator-system logs -f deploy/dual-deployment-operator-controller-manager
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
#    helm --kube-context rt-qa-de-1 -n dual-deployment-operator-system uninstall dual-deployment-operator
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
5. **Does helm reach `rt-qa-de-1`?** Use `helm --kube-context rt-qa-de-1`, or export the
   u8s seed kubeconfig (`KUBECONFIG=$(u8s env | sed -n 's/^export U8S_KUBECONFIG=//p')`).
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
