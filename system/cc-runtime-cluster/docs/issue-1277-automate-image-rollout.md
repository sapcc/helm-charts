# Issue context — automate rolling update on `IroncoreMetalMachineTemplate` image change

> Tracking ticket: [cc/unified-kubernetes#1277][issue-1277]
> Related: [cc/kube-secrets#4154][pr-4154] (the GardenLinux bump that exposed the problem)
>
> This document explains **why** the chart needs a change, **what** the
> change is, and **how** to implement it safely. Self-contained — no
> need to read other repos to understand the proposal.

[issue-1277]: https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1277
[pr-4154]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4154

---

## TL;DR

The chart currently renders `IroncoreMetalMachineTemplate` objects
with **fixed names** (one pair per cluster in `Values.clusters`):

```
controlplane-{{ $cluster.name }}
worker-{{ $cluster.name }}
```

When `Values.machineTemplate.image` changes (e.g. a GardenLinux
version bump), helm mutates the template's `.spec` **in place** under
the same name.

**Neither `KubeadmControlPlane` (KCP) nor `MachineDeployment` (MD)
detects this change** because both controllers look at the
`infrastructureRef.name`, not at the referenced template's `.spec`
contents.

Result: image bumps land but the existing machines keep running the
old image. Operators have to run `clusterctl alpha rollout restart`
manually on both controllers per region, every time. This is exactly
how PR #4154 (GardenLinux 1961 → 2150) played out — image was
deployed but worker machines never rolled until a manual nudge ~4
days later.

**The fix**: embed a hash of the image into the template object's
name. When the image changes, the hash changes, the template's name
changes, and KCP/MD both detect "infraRef changed" → rolling update
triggers automatically.

Matches what CAPA (AWS), CAPZ (Azure), Metal3 charts do. Documented
upstream as the [recommended pattern][capi-upgrade-images].

[capi-upgrade-images]: https://cluster-api.sigs.k8s.io/tasks/upgrading-clusters#how-to-upgrade-the-underlying-machine-image

---

## Why this chart needs to change

### How CAPI controllers actually decide to roll (code-verified)

I traced the upstream CAPI code at commit
[`d13ec498eafe065de594079589dd08608e932aa4`][capi-pin] (current `main`
as of 2026-06-22). Both controllers use the **same** mechanism: they
compare the *name* of the referenced infra template against what's
recorded on the existing infra machines, and ignore the template's
contents.

[capi-pin]: https://github.com/kubernetes-sigs/cluster-api/tree/d13ec498eafe065de594079589dd08608e932aa4

#### KCP — [`controlplane/kubeadm/internal/filters.go` L183–L227][kcp-filters]

```go
clonedFromName, ok1 := currentInfraMachine.GetAnnotations()[clusterv1.TemplateClonedFromNameAnnotation]
clonedFromGroupKind, ok2 := currentInfraMachine.GetAnnotations()[clusterv1.TemplateClonedFromGroupKindAnnotation]
...
// Check if the machine's infrastructure reference has been created from the current KCP infrastructure template.
if clonedFromName != kcp.Spec.MachineTemplate.Spec.InfrastructureRef.Name ||
    clonedFromGroupKind != kcp.Spec.MachineTemplate.Spec.InfrastructureRef.GroupKind().String() {
    return fmt.Sprintf("Infrastructure template on KCP rotated from %s %s to %s %s", ...),
        currentInfraMachine, desiredInfraMachine, false, nil
}
return "", currentInfraMachine, desiredInfraMachine, true, nil
```

KCP reads the `cluster.x-k8s.io/cloned-from-name` annotation that
CAPI writes onto each infra machine at creation time, and compares it
to the current value of `kcp.Spec.MachineTemplate.Spec.InfrastructureRef.Name`.
**Nothing in this function dereferences the InfraMachineTemplate to
read its `.spec`.**

[kcp-filters]: https://github.com/kubernetes-sigs/cluster-api/blob/d13ec498eafe065de594079589dd08608e932aa4/controlplane/kubeadm/internal/filters.go#L183-L227

#### MD — [`internal/controllers/machinedeployment/mdutil/util.go` L361–L410][md-uptodate]

```go
func MachineTemplateUpToDate(current, desired *clusterv1.MachineTemplateSpec) (bool, UpToDateResult) {
    ...
    currentCopy := MachineTemplateDeepCopyRolloutFields(current)
    desiredCopy := MachineTemplateDeepCopyRolloutFields(desired)
    ...
    if !reflect.DeepEqual(currentCopy.Spec.InfrastructureRef, desiredCopy.Spec.InfrastructureRef) {
        res.LogMessages = append(res.LogMessages, fmt.Sprintf("spec.infrastructureRef %s %s, %s %s required", ...))
        res.ConditionMessages = append(res.ConditionMessages, fmt.Sprintf("%s is not up-to-date", ...))
    }
    ...
}
```

`InfrastructureRef` is a Kubernetes object-reference struct
(`kind` / `apiGroup` / **`name`**). `DeepEqual` compares those fields,
not the contents of the template object the ref points at. The
companion function [`MachineTemplateDeepCopyRolloutFields`][md-rollout-fields]
explicitly drops in-place-mutable fields so they cannot trigger a
rollout.

[md-uptodate]: https://github.com/kubernetes-sigs/cluster-api/blob/d13ec498eafe065de594079589dd08608e932aa4/internal/controllers/machinedeployment/mdutil/util.go#L361-L410
[md-rollout-fields]: https://github.com/kubernetes-sigs/cluster-api/blob/d13ec498eafe065de594079589dd08608e932aa4/internal/controllers/machinedeployment/mdutil/util.go#L416-L446

#### Upstream in-tree comment confirming this

[`internal/controllers/machinedeployment/machinedeployment_rollout_planner.go` L227–L235][md-planner]:

```go
// Note: In previous Cluster API versions (< v1.4.0), the label value was the hash of the full machine
// template. Since the introduction of in-place mutation we are ignoring all in-place mutable fields,
// and using it as a info to be used for building a unique label selector. Instead, the rollout decision
// is not using the hash anymore.
templateHash, err := hash.Compute(mdutil.MachineTemplateDeepCopyRolloutFields(&deployment.Spec.Template))
```

[md-planner]: https://github.com/kubernetes-sigs/cluster-api/blob/d13ec498eafe065de594079589dd08608e932aa4/internal/controllers/machinedeployment/machinedeployment_rollout_planner.go#L227-L235

#### Upstream guidance

CAPI's official task guide is explicit:

> "MachineTemplate resources are immutable. The recommended approach
> is to copy the existing MachineTemplate, modify the values that
> need changing, create the new MachineTemplate on the management
> cluster, and modify the existing `KubeadmControlPlane` resource to
> reference the new MachineTemplate resource in the
> `infrastructureRef` field."
>
> — [Upgrading clusters → how to upgrade the underlying machine image][capi-upgrade-images]

### What this chart does today (the antipattern)

Reading `system/cc-runtime-cluster/templates/ironcoremetalmachinetemplate.yaml`:

```yaml
{{- range $cluster := .Values.clusters }}
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
kind: IroncoreMetalMachineTemplate
metadata:
  name: controlplane-{{ $cluster.name }}              # fixed name
  namespace: {{ $cluster.namespace }}
spec:
  template:
    spec:
      ...
      image: {{ $.Values.machineTemplate.image }}     # value that changes on every bump
{{- end }}
```

Same fixed-name pattern in `ironcoremetalmachinetemplate-worker.yaml`,
and `kubeadmcontrolplane.yaml` / `machinedeployment.yaml` both
reference the fixed name via `infrastructureRef`:

```yaml
# kubeadmcontrolplane.yaml
machineTemplate:
  spec:
    infrastructureRef:
      kind: IroncoreMetalMachineTemplate
      apiGroup: infrastructure.cluster.x-k8s.io
      name: controlplane-{{ $cluster.name }}          # fixed

# machinedeployment.yaml
template:
  spec:
    infrastructureRef:
      kind: IroncoreMetalMachineTemplate
      apiGroup: infrastructure.cluster.x-k8s.io
      name: worker-{{ $cluster.name }}                # fixed
```

When `Values.machineTemplate.image` changes:
- `IroncoreMetalMachineTemplate.spec.template.spec.image` is mutated in place.
- The template's `.metadata.name` stays the same.
- KCP and MD see no `infraRef.name` change → no rollout.

That's the bug we want to fix.

### Empirical evidence (PR #4154)

Cluster `a-qa-de-1`, 2026-06-22. PR #4154 bumped the image from
`gardenlinux-ccloud:1961.0.0-metal-capi-amd64-...` to
`gardenlinux-sci:2150.4.2-baremetal-capi-amd64-...`.

After helm-upgrade landed:

```
$ kubectl -n capi-runtime get ironcoremetalmachinetemplate -o jsonpath='{...image}'
# Template carries the NEW image ✓

$ kubectl -n capi-runtime get ironcoremetalmachine -o custom-columns=NAME,IMAGE
# All 10 machines still on the OLD image ✗
```

KCP and MD both reported `UP-TO-DATE = DESIRED` (false positive).
Manual `clusterctl alpha rollout restart` on both controllers was
required to actually pick up the new image. Workers were finally
rolled ~4 days after the PR merged.

---

## What the chart needs to change

### Goal

Make image changes flow through the chart and trigger an automatic
rolling update of both KCP and MD — without any manual `kubectl` or
`clusterctl` intervention.

### The mechanism — Option A

Embed a short hash of the image string into the `IroncoreMetalMachineTemplate`'s
`metadata.name`, and propagate that hashed name into the KCP and MD
`infrastructureRef.name` consumers.

When the image value changes:
1. Helm computes a new hash → renders a new template object name.
2. SSA creates the new `IroncoreMetalMachineTemplate` (the old one
   stays as an unreferenced orphan — see "Cleanup" below).
3. SSA updates `KCP.spec.machineTemplate.spec.infrastructureRef.name`
   and `MachineDeployment.spec.template.spec.infrastructureRef.name`
   to point at the new template.
4. KCP's `matchesInfraMachine` detects the rename → flags all CP
   machines as needing rollout → triggers a rolling update paced by
   `maxSurge` (currently 0 in the chart).
5. MD's `MachineTemplateUpToDate` detects the rename → creates a new
   `MachineSet` → triggers a rolling update paced by
   `maxSurge: 0, maxUnavailable: 1`.
6. Existing machines drain & are replaced one at a time, respecting
   etcd quorum (CP) and pod availability (workers).

### Concrete diff to the 4 files

Pseudo-diff against the current chart shape (multi-cluster, wrapped in
`{{- range $cluster := .Values.clusters }}`). Note that
`Values.machineTemplate.image` is currently a **single global value**
shared across all clusters in the release, so one hash applies to all
rendered pairs.

#### 1. `templates/ironcoremetalmachinetemplate.yaml`

```diff
+{{- $imageHash := $.Values.machineTemplate.image | sha256sum | trunc 8 }}
 {{- range $cluster := .Values.clusters }}
 ---
 apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
 kind: IroncoreMetalMachineTemplate
 metadata:
-  name: controlplane-{{ $cluster.name }}
+  name: controlplane-{{ $cluster.name }}-{{ $imageHash }}
   namespace: {{ $cluster.namespace }}
+  labels:
+    cc.sap/template-image-hash: {{ $imageHash }}
 spec:
   template:
     spec:
       serverSelector:
         matchLabels:
           kubernetes.metal.cloud.sap/cluster: {{ $cluster.name }}
           kubernetes.metal.cloud.sap/role: runtime-controlplane
       image: {{ $.Values.machineTemplate.image }}
       metadata:
 {{ toYaml $.Values.machineTemplate.metadata | indent 8 }}
       ipamConfig:
       - metadataKey: bond
         ipamRef:
           apiGroup: ipam.cluster.x-k8s.io
           kind: GlobalInClusterIPPool
           name: globalinclusterippool-{{ $cluster.name }}
 {{- end }}
```

#### 2. `templates/ironcoremetalmachinetemplate-worker.yaml`

Same hash-suffix idea:

```diff
+{{- $imageHash := $.Values.machineTemplate.image | sha256sum | trunc 8 }}
 {{- range $cluster := .Values.clusters }}
 ---
 apiVersion: infrastructure.cluster.x-k8s.io/v1alpha1
 kind: IroncoreMetalMachineTemplate
 metadata:
-  name: worker-{{ $cluster.name }}
+  name: worker-{{ $cluster.name }}-{{ $imageHash }}
   namespace: {{ $cluster.namespace }}
+  labels:
+    cc.sap/template-image-hash: {{ $imageHash }}
 spec:
   ...
 {{- end }}
```

#### 3. `templates/kubeadmcontrolplane.yaml`

Update the consumer reference:

```diff
+{{- $imageHash := $.Values.machineTemplate.image | sha256sum | trunc 8 }}
 {{- range $cluster := .Values.clusters }}
 ---
 kind: KubeadmControlPlane
 apiVersion: controlplane.cluster.x-k8s.io/v1beta2
 metadata:
   name: kcp-{{ $cluster.name }}
   namespace: {{ $cluster.namespace }}
 spec:
   ...
   machineTemplate:
     ...
     spec:
       infrastructureRef:
         kind: IroncoreMetalMachineTemplate
         apiGroup: infrastructure.cluster.x-k8s.io
-        name: controlplane-{{ $cluster.name }}
+        name: controlplane-{{ $cluster.name }}-{{ $imageHash }}
 {{- end }}
```

#### 4. `templates/machinedeployment.yaml`

Update the consumer reference:

```diff
+{{- $imageHash := $.Values.machineTemplate.image | sha256sum | trunc 8 }}
 {{- range $cluster := .Values.clusters }}
 ---
 apiVersion: cluster.x-k8s.io/v1beta2
 kind: MachineDeployment
 metadata:
   name: worker-{{ $cluster.name }}
   namespace: {{ $cluster.namespace }}
 spec:
   ...
   template:
     spec:
       bootstrap:
         ...
       infrastructureRef:
         kind: IroncoreMetalMachineTemplate
         apiGroup: infrastructure.cluster.x-k8s.io
-        name: worker-{{ $cluster.name }}
+        name: worker-{{ $cluster.name }}-{{ $imageHash }}
 {{- end }}
```

### A helper template (recommended)

The chart does not currently ship a `templates/_helpers.tpl` — this PR
should create one. Define the hash there so it's computed once and
imported in all 4 files (DRY — they MUST stay in sync or rollouts
break):

```yaml
# templates/_helpers.tpl  (new file)
{{- define "cc-runtime-cluster.imageHash" -}}
{{- .Values.machineTemplate.image | sha256sum | trunc 8 -}}
{{- end -}}

{{- define "cc-runtime-cluster.controlplaneInfraTemplateName" -}}
controlplane-{{ .cluster.name }}-{{ include "cc-runtime-cluster.imageHash" .root }}
{{- end -}}

{{- define "cc-runtime-cluster.workerInfraTemplateName" -}}
worker-{{ .cluster.name }}-{{ include "cc-runtime-cluster.imageHash" .root }}
{{- end -}}
```

Then inside each `range $cluster := .Values.clusters` loop, reference via:

```yaml
name: {{ include "cc-runtime-cluster.controlplaneInfraTemplateName" (dict "cluster" $cluster "root" $) }}
# or
name: {{ include "cc-runtime-cluster.workerInfraTemplateName" (dict "cluster" $cluster "root" $) }}
```

(The `dict` wrapper is needed because helper templates don't see the
`$cluster` loop variable directly; we pass it along with the root
context `$` so `.Values` remains reachable.)

This is the cleanest way to ensure the 4 files cannot drift.

### Design choices to document in the PR

| Decision | Rationale |
|---|---|
| Hash the **image string only**, not the whole template spec | Prevents unrelated changes (vlan, IPAM, additionalConfig) from forcing a rollout. The image is what users mean by "I want to roll my OS". |
| Use `sha256sum \| trunc 8` (8 hex chars) | ~4 billion buckets → effectively zero collision risk for our scale. Short suffix keeps total name well under the 253-char limit (current pattern `controlplane-<cluster.name>` is ~20–30 chars). |
| Add `cc.sap/template-image-hash` label | Enables `kubectl get -l cc.sap/template-image-hash=<hash>` lookups and selector-based cleanup. |
| Don't delete old templates automatically | Helm doesn't track object name changes. Old templates stay as unreferenced orphans (~10 KB each). Document cleanup; consider future automation. |

---

## What happens on the FIRST deploy of this PR

**Important: the first time this chart change is deployed to a
release, it will trigger one full rolling update of both KCP and MD
for every cluster in `Values.clusters`**, even if the image value
hasn't changed. This is unavoidable — the template name itself
changes from `controlplane-<cluster.name>` to
`controlplane-<cluster.name>-<hash>`, and KCP/MD detect that as
"infraRef rotated" exactly as they would for any other rename.

Subsequent image bumps trigger the same rolling update automatically,
but with no operator action.

### Communicate this to consumers of the chart

Any release notes or upgrade docs should call out:

> "Upgrading to chart version X.Y.Z triggers a one-time rolling
> update of the runtime cluster. The CP rollout takes ~30–45 min;
> the worker rollout takes ~60–90 min. Plan a maintenance window
> when deploying this chart version for the first time. After this
> upgrade, all future image bumps trigger an automatic rolling
> update through the same mechanism with no manual `clusterctl`
> intervention needed."

### Per-machine pacing (unchanged from today)

For our `cc-runtime-cluster` strategy:

| Resource | maxSurge | maxUnavailable | Procedure per machine |
|---|---|---|---|
| KCP | 0 | (implicit; etcd-quorum-based) | drain → remove etcd member → delete Machine → claim server → boot → kubeadm join → etcd member added |
| MD | 0 | 1 | drain → delete → claim server → boot → kubeadm join → Node Ready |

These properties are preserved: etcd quorum stays ≥ 2 of 3 throughout
CP rollout; worker capacity stays at (replicas − 1) throughout MD
rollout; PDBs respected during drain.

---

## Why we ruled out alternatives

| Option | Reason ruled out |
|---|---|
| **Wait for upstream in-place updates** | KEPs [`kubernetes-sigs/cluster-api#9489`][kep-9489] and [`#11029`][kep-11029] not yet GA. A full OS swap (kernel + partition rewrite) likely wouldn't qualify for "in-place" anyway. ironcore-metal upstream tracking issue [`ironcore-dev/cluster-api-provider-ironcore-metal#65`][icm-65] has been open since Feb 2025 with no implementation. |
| **Migrate to ClusterClass** | Large architectural change; ironcore-metal CAPI provider support may not be complete. Future option, not now. |
| **Pipeline post-step runs `clusterctl rollout`** | Lives in CI, not in the chart; doesn't help consumers who deploy outside the pipeline; `clusterctl rollout restart` always bumps `rollout.after = now` which is non-idempotent on re-run. |
| **Custom controller / mutating webhook** | Reinvents CAPI's own template-rotation mechanism. High maintenance burden. |
| **Image-tag-suffixed name** (instead of hash) | Image tags can be 50+ chars (e.g. `2150.4.2-baremetal-capi-amd64-2150-4-2-55909ef5`); produces long, unwieldy template names. Hash is shorter and safer. |

[kep-9489]: https://github.com/kubernetes-sigs/cluster-api/issues/9489
[kep-11029]: https://github.com/kubernetes-sigs/cluster-api/pull/11029
[icm-65]: https://github.com/ironcore-dev/cluster-api-provider-ironcore-metal/issues/65

---

## Equivalence to manual `clusterctl alpha rollout restart`

Functionally yes; operationally no.

The actual machine-replacement machinery (drain → delete → ServerClaim
→ boot → kubeadm join, paced by `maxSurge` / `maxUnavailable`) is
identical between Option A and what we do today with manual
`clusterctl rollout restart`.

What Option A adds over the manual path:

| Property | Manual `clusterctl rollout` | Option A |
|---|---|---|
| Human steps per image bump | 3 (helm-upgrade + 2× clusterctl) | 0 |
| Atomic across KCP + MD? | No (two separate invocations) | Yes (one helm-upgrade) |
| Risk of forgetting a step | Real (PR #4154's failure mode) | None |
| Idempotent on no-op re-run? | No (`rollout.after = now` always) | Yes (same hash = no-op) |
| On-cluster audit trail | No (need git history of values) | Yes (named template object per past image) |
| Cluster cruft over time | None | Orphan templates accumulate (~10 KB each) |

---

## Testing & validation

### Helm-side

Add `helm template` snapshot tests that assert:

1. The 4 files' `infrastructureRef.name` values all match each other
   for a given image.
2. The hash changes when the image value changes.
3. The hash does NOT change when other values change (vlan, IPAM,
   additionalConfig).

Example assertion:

```bash
# Test 1: all 4 manifests reference the same template name
helm template . --set machineTemplate.image=foo:1.0 \
  | yq '. | select(.kind == "IroncoreMetalMachineTemplate") | .metadata.name' | sort -u
# Expect: 2 unique names (one CP, one worker), both ending in the same hash
# Expect: KCP and MD infraRef names match those exactly
```

### Cluster-side (in QA)

Deploy to `a-qa-de-1` first. The actual replica counts there come
from the deploying pipeline's values override (chart defaults are
`controlplane.replicas: 3` and `worker.replicas: 3`; the QA region
runs with 3 CP and 7 workers per cluster). Verify:

1. **First deploy triggers a one-time rolling update** of KCP (3 CP
   machines) and MD (~7 worker machines) per cluster in
   `Values.clusters` — wall-clock ~90-120 min per cluster.
2. **`kubectl get ironcoremetalmachinetemplate -n capi-runtime`** shows
   the new hashed-name template(s) alongside the old fixed-name
   template (orphan).
3. **`kubectl get ironcoremetalmachine -o custom-columns=NAME,IMAGE`**
   shows all machines on the new image after rollout completes.
4. **Subsequent image bump** (test by editing values and re-deploying)
   triggers automatic rolling update with zero manual `kubectl`
   invocation.

### Sanity checks before rollout completes

```bash
# CP rollout in progress?
kubectl --context a-qa-de-1 -n capi-runtime get kcp -o jsonpath='{...status.conditions[?(@.type=="RollingOut")].status}'

# Worker rollout in progress?
kubectl --context a-qa-de-1 -n capi-runtime get machinedeployment -o jsonpath='{...status.updatedReplicas}'

# Etcd quorum healthy?
kubectl --context a-qa-de-1 -n capi-runtime get kcp -o jsonpath='{...status.conditions[?(@.type=="EtcdClusterHealthy")].status}'
```

---

## Rollout plan to production

1. **Merge** chart PR with snapshot tests + bumped chart version.
2. **`cc/kube-secrets`** pipeline picks up new chart via its
   `helm-charts.git` resource. The `cc-runtime-cluster-admin-k3s`
   pipeline on ci1 (team `services`) will apply the new chart to
   `a-qa-de-1` first (gate region), then other admin-k3s clusters
   per the gate-and-trigger configuration.
3. **`a-qa-de-1`** absorbs one rolling update. Verify per "Testing &
   validation" above.
4. **Soak** for at least 24h. Watch for any CAPI / boot-operator
   anomalies during steady-state.
5. **Promote** to prod admin-k3s clusters one at a time
   (`a-eu-de-1`, `a-eu-de-2`, `a-eu-de-3`, `a-na-us-2`, `a-ap-sg-1`,
   etc.) per the existing gate.
6. **Validate with a real image bump** — pick a routine GardenLinux
   patch and bump `Values.machineTemplate.image`. Confirm rolling
   update fires automatically.

---

## Cleanup of orphan templates

After the first Option A deploy, every cluster accumulates:

- `controlplane-<cluster.name>` — orphan from the pre-Option-A era
- `controlplane-<cluster.name>-<hash1>` — first Option A apply, may be active
- `controlplane-<cluster.name>-<hashN>` — current

Same for worker templates. Each is ~10 KB. They have no controller
watching them and don't affect cluster behavior.

### Manual cleanup

```bash
# List all infra templates and their hash labels
kubectl -n capi-runtime get ironcoremetalmachinetemplate \
  --show-labels | grep template-image-hash

# Find the current hash
CURRENT_HASH=$(kubectl -n capi-runtime get ironcoremetalmachinetemplate \
  -l 'cc.sap/template-image-hash' \
  -o jsonpath='{.items[0].metadata.labels.cc\.sap/template-image-hash}')
echo "Current: $CURRENT_HASH"

# Delete everything not on the current hash (dry-run first!)
kubectl -n capi-runtime delete ironcoremetalmachinetemplate \
  -l "cc.sap/template-image-hash,cc.sap/template-image-hash!=${CURRENT_HASH}" \
  --dry-run=client
```

Old pre-Option-A templates (no `cc.sap/template-image-hash` label)
need a separate delete by name.

### Automated cleanup (future enhancement)

If orphan count becomes a concern, candidate approaches:

- Helm pre-upgrade hook listing all templates and deleting unreferenced ones.
- A small standalone CronJob that scans `IroncoreMetalMachineTemplate`s in `capi-runtime` and deletes any not referenced by a KCP or MD.

Not blocking for the initial PR.

---

## Related notes & references

### Issues

- [cc/unified-kubernetes#1277][issue-1277] — the tracking ticket for this work
- [cc/unified-kubernetes#1268][issue-1268] — original GardenLinux bump that exposed the gap
- [cc/kube-secrets#4154][pr-4154] — the PR that successfully bumped the image but needed manual rollout for workers

[issue-1268]: https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1268

### Upstream

- [CAPI — Updating Machine Templates][capi-update-templates] — the canonical pattern recommendation
- [CAPI — Upgrading machine image][capi-upgrade-images] — same recommendation, image-specific
- [CAPI in-place updates KEP][kep-9489] — long-term solution (not GA)
- [ironcore-metal in-place updates tracking][icm-65] — provider-side waiting room

[capi-update-templates]: https://cluster-api.sigs.k8s.io/tasks/updating-machine-templates

### Reference implementations (other providers doing this correctly)

These charts already follow the "new template per image change" pattern — useful for comparison:

- `cluster-api-provider-aws` (CAPA) — uses `AWSMachineTemplate` with name based on values hash
- `cluster-api-provider-metal3` (CAPM3) — same pattern
- `cluster-api-provider-azure` (CAPZ) — same pattern

---

## Open questions for review

1. **Hash length** — 8 chars (~4B buckets) is safe for our scale. 12
   chars if anyone wants paranoia margin. Beyond 12 is pointless.
2. **Naming** — `controlplane-<cluster.name>-<hash>` vs
   `controlplane-<cluster.name>-<imagetag>`? Hash is shorter and avoids
   special-character sanitization headaches. Recommended: hash.
3. **Label key** — `cc.sap/template-image-hash` is the natural choice
   for SAP CC conventions. Alternative: scoped under a chart-specific
   prefix like `helm.sh/cc-runtime-cluster.image-hash`. Recommended:
   `cc.sap/...`.
4. **Cleanup automation** — defer to a follow-up issue? Yes.
5. **Helm chart version bump** — current `version: 0.8.1` (per
   `Chart.yaml`) bumped to `0.8.2` (patch). Note: the first deploy of
   this version triggers a one-time rolling update; communicate via
   release notes / maintenance window.
6. **`appVersion` change?** No — the chart logic changes but the
   "version of the system it deploys" doesn't.

---

## Pin: upstream code references

All upstream code links above are pinned to CAPI commit
`d13ec498eafe065de594079589dd08608e932aa4` (main as of 2026-06-22) so
they don't break if upstream rearranges files. To re-verify against
the latest CAPI:

```bash
git ls-remote https://github.com/kubernetes-sigs/cluster-api.git refs/heads/main
# Then sub the new SHA into the URLs above.
```

---

**Document date:** 2026-06-22 (drafted), validated 2026-06-24 against
`system/cc-runtime-cluster` at commit `615924bbc2` (Chart.yaml
`version: 0.8.1`).
**Author context:** Generated while working on PR cc/kube-secrets#4154,
during the manual `clusterctl rollout restart` workaround for the
worker rollout on `a-qa-de-1`.
