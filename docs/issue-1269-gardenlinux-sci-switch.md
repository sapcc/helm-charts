# Issue context — switch Gardener Shoot machine images to `gardenlinux-sci`

> Tracking ticket: [cc/unified-kubernetes#1269][issue-1269]
> Sibling (CAPI path): [cc/unified-kubernetes#1268][issue-1268] / [#1277][issue-1277]
>
> This document explains **what** the switch is, **how** the two-repo
> transition works, **what has been done**, **how to verify it**, and **how
> it differs** from the CAPI-path switch. Self-contained — no need to read
> other repos to understand it.

[issue-1269]: https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1269
[issue-1268]: https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1268
[issue-1277]: https://github.wdf.sap.corp/cc/unified-kubernetes/issues/1277
[pr-4163]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4163
[pr-4171]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4171
[pr-4232]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4232
[pr-4336]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4336
[pr-4445]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4445
[pr-4154]: https://github.wdf.sap.corp/cc/kube-secrets/pull/4154

---

## TL;DR

The Garden Linux team renamed the OS-image OCI repository
`gardenlinux-ccloud` → `gardenlinux-sci` and asked us to move onto a
supported stable release line. Issue #1269 switches the **Gardener Shoot**
machine images (management, controlplane, storage) to the new repo.
(`compute` is handled separately by the KVM team.)

Rather than a hard cutover, the rollout runs **both repos in parallel** via
two `machineImageUpdates` entries. `cloud-profile-sync` scans both shelves
and **merges every discovered version into one `gardenlinux` machine image**
in the `ironcore-metal` CloudProfile. Shoots then pick a specific version
(the `scibase-usi` flavor) from that merged menu.

**Status:** all three worker shoots reconciled onto the new
`2150.6.0-...-scibase-usi` image; the dual-repo config is live in prod. Still
open: the eventual consolidation back to a single `sci` repo, and confirming
whether management should also converge to `2150.6.0`.

---

## Background: repo vs. flavor (the #1 source of confusion)

A Garden Linux version string encodes **two independent axes**:

```
2150.6.0-baremetal-capi-amd64-2150-6-0-297ce257
└──┬───┘ └───────┬────────┘
 release        FLAVOR (build variant / feature packs)
```

- **Repository** — *which shelf the artifact sits on*: `gardenlinux-ccloud`
  (old) vs `gardenlinux-sci` (new). This is what #1269 switches.
- **Flavor** — *which build variant*: `capi`, `sci-usi`, `sci-usidev`,
  `sci-pxe`, `scibase-usi`, … Published **inside** whichever repo.

These are orthogonal. The rename `ccloud → sci` moved **all** flavors along
(including `capi`), so both repos contain `capi`-flavored builds — the old
shelf holds the older ones, the new shelf the newer ones.

> **Why you see `-capi-` versions in the Gardener CloudProfile even though
> this is a Gardener switch:** there is no separate "CAPI feed". There are two
> *repo* feeds (`ccloud` + `sci`); the `capi` flavor happens to live in both.
> The Gardener shoots do **not** consume `capi` flavors — those belong to the
> CAPI path (#1268/#1277, the admin-k3s `a-*` runtime clusters). Both paths
> share the same `ironcore-metal` CloudProfile, so every flavor from both
> feeds lands in one menu and each consumer picks the flavor meant for it.
> Gardener shoots pick `scibase-usi`.

---

## How the machinery fits together

Two different lists in `cc-gardener.yaml` (under `extensions.metal`) do two
different jobs:

### 1. `machineImageUpdates` — the "where to shop" feeds (input)

Not a version list. A set of instructions telling `cloud-profile-sync` which
OCI registry/repository to **scan** for `gardenlinux` versions. During the
transition there are **two** entries, both `imageName: gardenlinux`:

```yaml
machineImageUpdates:
- imageName: gardenlinux            # OLD shelf
  source:
    oci:
      registry: keppel.eu-de-1.cloud.sap
      repository: ccloud-ghcr-io-mirror/gardenlinux/gardenlinux-ccloud
  provider:
    ironcoreMetal:
      registry: keppel.global.cloud.sap
      repository: ccloud-ghcr-io-mirror/gardenlinux/gardenlinux-ccloud
- imageName: gardenlinux            # NEW shelf
  source:
    oci:
      registry: keppel.eu-de-1.cloud.sap
      repository: ccloud-ghcr-io-mirror/gardenlinux/gardenlinux-sci
  provider:
    ironcoreMetal:
      registry: keppel.global.cloud.sap
      repository: ccloud-ghcr-io-mirror/gardenlinux/gardenlinux-sci
```

- `source.oci` — where `cloud-profile-sync` **reads** the version list.
- `provider.ironcoreMetal` — where the nodes actually **pull** the image at boot.

**Merge behavior (verified in QA):** two entries with the same
`imageName: gardenlinux` do **not** create two machine images. `cloud-profile-sync`
finds the existing `gardenlinux` entry created by the first feed and
**accumulates the second feed's versions into the same list**. Result: one
`gardenlinux` machine image whose `versions` are the union of both shelves.

### 2. `providerConfig.machineImages` — hand-pinned versions

A handful of explicitly pinned versions with exact image URLs (e.g.
`1912.0.0-sci`, `1872.0.0-sci-usi`). These coexist with the auto-discovered
versions in the same combined menu.

### 3. The CloudProfile — the merged output

`cloud-profile-sync` reconciles a `ManagedCloudProfile`
(`cloudprofilesync.cobaltcore.dev/v1alpha1`) into a cluster-scoped Gardener
`CloudProfile` (`core.gardener.cloud/v1beta1`) named **`ironcore-metal`**,
living in the **virtual garden** cluster. The merged version list lands in:

- `spec.machineImages` — core Gardener image menu.
- `spec.providerConfig.machineImages` — provider-specific image→URL mapping.

### End-to-end flow

```
cc-gardener.yaml (machineImageUpdates: ccloud + sci)
        │  helm values (kube-secrets) → ManagedCloudProfile (helm-charts)
        ▼
cloud-profile-sync  ── scans both OCI repos ──►  merges versions
        ▼
CloudProfile "ironcore-metal"  (spec.machineImages: one gardenlinux list)
        ▼
Shoot picks imageVersion  (e.g. 2150.6.0-...-scibase-usi)
        ▼
Gardener MCM rolls the worker nodes onto the new image
```

---

## What has been done

### cloud-profile-sync — dual-repo parallel support (done, in prod)

Strategy: run both repos in parallel for a smooth staged transition, then
reduce back to a single repo later.

- [PR #4163][pr-4163] — added the `gardenlinux-sci` second entry to
  `admin-k3s` and the QA runtime config; **merged**.
- QA test confirmed the merge: *"the second entry with the same imageName:
  gardenlinux will find the gardenlinux entry already created by the first
  entry and add its versions into the same list."*
- [PR #4171][pr-4171] — promoted the `sci` entry to the shared/prod runtime
  base (`runtime/cc-gardener.yaml`) and removed the now-redundant QA-region
  copy (QA inherits from the shared base); **merged** 2026-06-26.

### Worker shoot image updates — all three done

Rolled out one at a time, starting with the lowest-risk shoot:

- **Management** (`mgmt-qa-de-1`, chosen first for test/soak): [PR #4232][pr-4232],
  then latest bump [PR #4336][pr-4336]. Tested and soaked.
- **Controlplane**: [PR #4445][pr-4445] — verified all nodes transitioned
  from Garden Linux `2024.0.0` → `2150.6.0`.
- **Storage**: [PR #4445][pr-4445] — **merged** 2026-07-15.
- Final confirmation (2026-07-15): *"Reconcile succeeded on all worker shoots
  (management, controlplane, storage)."*

### Current live image versions (`values/helm/garden/`)

| Shoot         | `imageVersion`                                              | Flavor / notes                    |
|---------------|-------------------------------------------------------------|-----------------------------------|
| controlplane  | `2150.6.0-baremetal-scibase-usi-amd64-2150-6-0-297ce257`    | sci stable line ✅                |
| storage       | `2150.6.0-baremetal-scibase-usi-amd64-2150-6-0-297ce257`    | sci stable line ✅                |
| management    | `2024.0.0-metal-scibase-usi-amd64-2024.0.0-d1baca65-amd64`  | sci flavor, older `2024.0.0` line |

---

## How to verify (via `u8s`)

The CloudProfile lives in the **virtual garden** cluster. Context naming:
`g-<region>` = virtual garden (CloudProfiles live here); `rt-<region>` =
runtime cluster (does **not** expose `cloudprofiles`).

```bash
# 1. Find the garden context for your landscape
u8s kubectl config get-contexts | grep -iE "g-|rt-"

# 2. Confirm cloud-profile-sync succeeded (the INPUT side)
u8s --context g-qa-de-1 kubectl get managedcloudprofiles
#    STATUS must be "Succeeded"

# 3. Inspect the merged OUTPUT — the core Gardener image menu
u8s --context g-qa-de-1 kubectl get cloudprofile ironcore-metal \
    -o jsonpath='{.spec.machineImages}' | python3 -m json.tool

# 4. (Optional) provider-specific image→URL mapping
u8s --context g-qa-de-1 kubectl get cloudprofile ironcore-metal \
    -o jsonpath='{.spec.providerConfig.machineImages}' | python3 -m json.tool

# 5. See only the flavors of interest (sci-usi vs the along-for-the-ride capi)
u8s --context g-qa-de-1 kubectl get cloudprofile ironcore-metal \
    -o jsonpath='{.spec.machineImages[0].versions[*].version}' \
    | tr ' ' '\n' | grep -E "sci-usi|-capi-"
```

### QA verification result (2026-07-21, `g-qa-de-1`)

- `managedcloudprofiles/ironcore-metal` → **`STATUS: Succeeded`**.
- The single `gardenlinux` machine image held **~100 versions** merged from
  both shelves — `-sci-{pxe,usi,usidev}` and `-scibase-usi` families **and**
  `-capi-amd64` builds sitting side by side under one image, proving the two
  feeds accumulated into one list.
- The controlplane/storage target
  `2150.6.0-baremetal-scibase-usi-amd64-2150-6-0-297ce257` is present and
  pickable. ✅

---

## Comparison with the CAPI-path switch (#1268 / #1277)

Same chore (`ccloud → sci`, stable line), different provisioning path. The
CAPI path was materially harder:

| Aspect                     | CAPI runtime (#1268/#1277 — done)                          | Gardener Shoots (#1269 — nearly done)                     |
|----------------------------|------------------------------------------------------------|------------------------------------------------------------|
| Which clusters             | admin-k3s `a-*` runtime clusters                           | management, controlplane, storage shoots                   |
| Controller                 | Cluster API (KCP / MachineDeployment)                      | Gardener Machine Controller Manager (MCM)                  |
| Rollout on image change    | **Blind** — controllers ignore template `.spec` changes    | **Native** — MCM rolls nodes automatically                |
| Workaround needed          | Hash image string into template *name* to force rollout ([#1277]) | None                                             |
| Bootstrap format           | Ignition **v2.3.0** → needs `_legacy` GardenLinux flavor   | cloud-init / OS extension — no Ignition v2 constraint      |
| Flavor consumed            | `metal-capi` / `baremetal-capi-amd64` (`_legacy` feature pack) | `baremetal-scibase-usi`                                 |
| Repo switch style          | Direct bump to sci `2150.4.2` ([PR #4154][pr-4154])        | Dual-repo parallel, then consolidate                       |

**Key insight:** the painful CAPI gotchas — the template name-hashing hack and
the Ignition-v2 `_legacy` flavor — do **not** apply to Gardener. MCM detects
image-version changes natively, which is exactly why "reconcile succeeded on
all worker shoots" worked without any template tricks.

---

## Outstanding / open items

The issue is still **open**, consistent with two loose ends:

1. **Management version gap.** Controlplane and storage are on `2150.6.0`;
   management is still on the older `2024.0.0` (sci flavor). Confirm whether
   this is intentional or needs a bump to converge.
2. **Parallel-repo consolidation.** The dual-repo setup is intentionally
   temporary ("run both, then reduce to a single one again"). Both
   `machineImageUpdates` entries (`ccloud` + `sci`) are still present. Once the
   fleet is fully on `sci`, drop the `ccloud` entry — at which point the old
   `ccloud`-sourced versions (including its `capi` builds) stop appearing in
   the merged CloudProfile.
