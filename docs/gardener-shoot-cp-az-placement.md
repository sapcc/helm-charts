# Pinning Gardener Shoot Control Planes to a Specific Availability Zone

> **Status:** Working notes for [`cc/unified-kubernetes#943`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/943) — "[Gardener] Dataplane clusters - Kubernetes API AZ local".
> Audience: engineers new to Gardener who need to understand both *why* this matters and *how* to do it.
>
> **See also:** [`gardener-architecture.md`](./gardener-architecture.md) —
> a standalone explanation of garden / runtime / seed / shoot and how
> our clusters are managed. Read that first if you are new to Gardener;
> this doc assumes those terms are already familiar.

---

## Table of contents

1. [Background: what Gardener is and how shoots are hosted](#1-background)
2. [The problem](#2-the-problem)
   - [2.1 How we got here: summary of the Slack alignment thread](#2-1-slack-summary)
3. [Our concrete setup](#3-our-concrete-setup)
4. [Landscape topology: virtual garden on the runtime seed](#4-landscape-topology)
5. [The upstream feature: `Seed.spec.settings.zoneSelection`](#5-upstream-feature)
   - [5.4 The zonal-ingress companion problem](#5-4-zonal-ingress)
6. [The remaining gap: workerless shoots](#6-the-gap)
7. [Decision matrix: which solution per cluster type](#7-decision-matrix)
8. [Operational runbook](#8-runbook)
9. [Verification, monitoring, and alerting](#9-verification)
10. [Open questions / follow-ups](#10-open-questions)
11. [Glossary](#11-glossary)
12. [References](#12-references)

---

## 1. Background <a id="1-background"></a>

### 1.1 The three layers of Gardener

Gardener is an open-source project (originated at SAP) for operating many
Kubernetes clusters at scale. It introduces three layers:

| Layer        | What it is                                                            | Analogy                              |
| ------------ | --------------------------------------------------------------------- | ------------------------------------ |
| **Garden**   | A central Kubernetes cluster that stores the configuration of all shoots. | The control room.                    |
| **Seed**     | A regular Kubernetes cluster that *hosts* shoot control planes as pods. | The data center floor.               |
| **Shoot**    | The end-user Kubernetes cluster.                                      | The customer's house.                |

The key insight: a shoot's control plane (kube-apiserver, etcd,
kube-controller-manager, kube-scheduler, …) does **not** run on dedicated VMs.
It runs as a set of pods inside a **namespace on a seed cluster**, named
something like `shoot--<project>--<shoot>`.

```
Garden cluster
   │
   └── Seed cluster   (a real k8s cluster, has its own nodes in AZ-a, AZ-b, AZ-c)
         │
         └── Namespace shoot--compute--cc-a0-eu-de-2
               ├── kube-apiserver  Pod    ┐
               ├── etcd-main       Pod    │  These pods together
               ├── etcd-events     Pod    │   = the control plane of
               ├── kube-scheduler  Pod    │     shoot "cc-a0-eu-de-2"
               └── …                      ┘

   (elsewhere, separate VMs in the IaaS)
   Worker nodes of shoot cc-a0-eu-de-2 in AZ eu-de-2a
```

### 1.2 Availability Zones (AZs)

A **region** (e.g. `eu-de-2`) is split into multiple **availability zones**
(`eu-de-2a`, `eu-de-2b`, `eu-de-2c`) — physically separate data centers with
independent power, cooling, and network. An AZ failure is a normal operational
event; the design goal is that a single AZ outage cannot take down a service.

A Gardener **Seed** can be:

- **single-AZ** — its worker nodes are all in one AZ, or
- **stretched / multi-AZ** — its worker nodes are spread across two or three AZs.

A Gardener **Shoot** can similarly be single-AZ or multi-AZ, and orthogonally
its control plane can be:

| `failureToleranceType`  | Effect on control plane                                          |
| ----------------------- | ---------------------------------------------------------------- |
| not set (non-HA)        | CP pods run in **one** AZ (single replica each).                 |
| `node`                  | CP pods are spread across **nodes** within one AZ (HA inside an AZ). |
| `zone`                  | CP pods are spread across **multiple AZs** (zone-redundant HA).  |

For non-HA and `node` HA shoots, Gardener has to pick **one** AZ in which to
run the control plane. By default that pick is random.

---

## 2. The problem <a id="2-the-problem"></a>

When a shoot's control plane is placed in a random AZ of the seed, three
things go wrong for an architecture that depends on AZ-locality:

1. **Cross-AZ latency.** Every kubelet on the shoot's worker nodes talks to
   the shoot's `kube-apiserver`. If the workers are in AZ-A and the apiserver
   is in AZ-C, every API call crosses the AZ boundary twice.

2. **Cross-AZ traffic.** This adds bandwidth cost and load on the inter-AZ
   links. At scale (many KVM hypervisors), it is significant.

3. **Blast radius escalation.** The point of putting all of a shoot's workers
   in one AZ is to ensure that an AZ outage only kills that one shoot. If the
   control plane is in a different AZ, an AZ-C outage **also** kills the AZ-A
   shoot (because its brain went down). The isolation guarantee is silently
   broken.

There is a related downstream effect: the shoot's external DNS record
(`api.<shoot>...`) is routed via the Istio ingress gateway in the AZ where
the control plane lives (because of `externalTrafficPolicy: Local` and zonal
ingress gateways). So a control plane in the wrong AZ also puts ingress in
the wrong AZ.

### Acceptance criteria for #943

- Find a way to steer Gardener deployments of the k8s API into the "correct" AZ.
- Document, per cluster type, how the control plane should be placed.

### 2.1 How we got here: summary of the Slack alignment thread <a id="2-1-slack-summary"></a>

The issue is short and gives almost no context on its own. The real
design discussion happened in the internal Slack channel
`#converged-cloud`, thread starting
[here](https://convergedcloud.slack.com/archives/C07C3T6GTEU/p1772466005684939).
This subsection distills that thread so future readers do not need to
find and re-read it.

**Cast of participants**

| Person             | Role in the thread                                                      |
| ------------------ | ----------------------------------------------------------------------- |
| **Fabian Ruff**    | KVM / Bedrock architect. Asked the original question, drives the requirement. |
| **Rafael Franzke** | Upstream Gardener maintainer. Proposed both the workaround and the upstream fix. |
| **Dimitar Mirchev**| Suggested that any new knob should live on the `Seed` API, not the `Shoot` API. |
| **Dmitri Fedotov** | Raised the linked "ingress AZ follows CP AZ" symptom and the storage/Ceph implications. |
| **Christian Hummel** | Confirmed that LoB NEO (customer factory landscapes) will need the same feature. |
| **Tim Usner**      | Upstream Gardener maintainer. Proposed alternative designs for the workerless case. |

**Chronological walk-through**

1. **The question.** Fabian: *"How do I pin a shoot's control plane
   pods to one specific AZ (for a non-HA shoot, or a shoot with
   `failureToleranceType: node`) when the seed is stretched across
   multiple AZs?"*
   His use case: KVM compute shoots are intentionally single-AZ so
   that an AZ outage cannot ripple beyond one shoot. If the shoot's
   control plane lands in a different AZ, that isolation is broken.

2. **Why Gardener didn't already offer this.** Rafael explained that
   Gardener deliberately randomizes the CP zone for two reasons:
   - Preventing customers from packing all their shoots into one zone
     of a shared seed.
   - On hyperscalers (AWS/Azure/GCP), AZ names are randomized per
     account, so pinning by name would be meaningless anyway. This
     feature only makes sense on infrastructures we control ourselves
     (OpenStack, metal, sovereign clouds).

3. **The short-term workaround.** Rafael suggested a *mutating
   admission policy* in the seed cluster that watches for shoot
   control-plane namespace creation and sets the
   `high-availability-config.resources.gardener.cloud/zones`
   annotation to the desired AZ. The gardener-resource-manager reads
   that annotation and translates it into node-affinity on every CP
   pod. Discussed limitations:
   - **Cannot cross-reference other resources.** A CEL-based mutating
     admission policy can only see the object under admission, so it
     cannot look up the shoot's worker-pool zones from the
     `Cluster` extension resource. A real mutating webhook can, but
     is more moving parts.
   - **Workable if the AZ is encoded in the namespace name.** Fabian's
     naming convention (`cc-a0-eu-de-2 → eu-de-2a`) makes the CEL
     approach viable.
   - **Cannot retroactively re-pin an existing CP** on a hyperscaler
     because etcd (and other) PVs are already bound to their zone —
     you'd need a backup-restore. **On Ceph-backed seeds** (our case)
     the volumes are not zone-bound, so re-pinning is safe.

4. **Where the knob should live.** Dimitar and Rafael converged that
   this should be a **Seed-level setting**, not a Shoot-level one, to
   avoid customer-driven zone hotspotting on BTP Gardener landscapes.

5. **Adjacent finding by Dmitri.** With
   `spec.settings.loadBalancerServices.zonalIngress.enabled: true` and
   `externalTrafficPolicy: Local`, the shoot's DNS record follows the
   AZ where its CP landed (via the zonal Istio ingress). So a
   misplaced CP silently misplaces ingress too. Fixing CP placement
   fixes both.

6. **Storage caveat.** Dmitri also flagged that the seed's Ceph
   storage today uses a single `StorageClass` / `CephBlockPool` with
   `failureDomain: host`, `subFailureDomain: host` — not AZ-aware.
   For stretched (multi-AZ) Ceph shoots we may eventually need
   per-AZ `StorageClasses` and `CephBlockPools`, or to lean on the
   Ceph arbiter. Tracked separately.

7. **Upstream feature lands.** A week later Rafael opened and merged
   [`gardener/gardener#14238`](https://github.com/gardener/gardener/pull/14238)
   ("Add zone selection setting to `Seed`s for AZ-aware control plane
   placement"). This is what §5 of this doc describes: the new
   `Seed.spec.settings.zoneSelection` field with `Prefer` and
   `Enforce` modes. It closes the workered-shoot case cleanly.

8. **The remaining gap becomes visible.** Dmitri then pointed out
   that the upstream fix does **not** cover **Lighthouse** clusters,
   which are workerless shoots (no worker pool → no zones to
   intersect with). Fabian confirmed that Lighthouse must be pinned
   the same way as its associated KVM shoots.

9. **Namespace-annotation workaround falls apart for KVM.** Fabian
   pointed out an important detail that had been implicit: the
   `high-availability-config.resources.gardener.cloud/zones`
   annotation Rafael originally referred to is on the *shoot control
   plane namespace* on the seed (e.g. `shoot--compute--cc-a0-eu-de-2`),
   **not** on the garden-project namespace on the garden. Multiple
   shoots in the same garden project (`garden-compute`) can therefore
   each have their own zone — so the workaround does work per shoot,
   which is what we need.

10. **Options on the table for workerless shoots.** Rafael and Tim
    Usner listed three candidate designs:
    - **(a)** A new `Shoot.spec.controlPlane.zone` field, honored
      only for workerless shoots. Cleanest separation.
    - **(b)** A `Shoot.spec.controlPlane.zone` field for **all**
      shoots, taking precedence over worker-derived selection.
      Enables planned-maintenance zone flips too (Dmitri's
      preference).
    - **(c)** Redesign the use case: either run one HA Lighthouse
      across AZs (Fabian rejected — defeats isolation) or run one
      seed per AZ (workable but 3× seed sprawl; not chosen).
    Direction leans toward **(b)**, tracked as an open follow-up
    (see §10.1).

**Net takeaway.** The Slack thread produced two concrete outcomes:

1. **A landed upstream feature** (`Seed.spec.settings.zoneSelection`)
   that solves the KVM compute case, and
2. **A recognized gap** (workerless Lighthouse shoots) that still
   needs either an admission-policy workaround downstream or a new
   upstream Shoot field.

Both outcomes are reflected in the runbook (§8) and the decision
matrix (§7).

---

## 3. Our concrete setup <a id="3-our-concrete-setup"></a>

The Bedrock / KVM dataplane deployment in each region looks like this:

```
Region eu-de-2
│
├── Seed   mgmt-eu-de-2                 (stretched: workers in 2a, 2b, 2c)
│     │
│     ├── Shoot  cc-a0-eu-de-2          (KVM compute,   workers ONLY in 2a)
│     ├── Shoot  cc-a1-eu-de-2          (KVM compute,   workers ONLY in 2a)
│     ├── Shoot  cc-b0-eu-de-2          (KVM compute,   workers ONLY in 2b)
│     ├── Shoot  cc-c0-eu-de-2          (KVM compute,   workers ONLY in 2c)
│     │
│     ├── Shoot  lh-eu-de-2a            (Lighthouse, workerless, serves 2a)
│     ├── Shoot  lh-eu-de-2b            (Lighthouse, workerless, serves 2b)
│     └── Shoot  lh-eu-de-2c            (Lighthouse, workerless, serves 2c)
│
└── (other shoots: regional Ceph storage clusters spanning all 3 AZs, etc.)
```

Key properties:

- **All KVM shoots live in the same Gardener project namespace** (`garden-compute`).
  Any solution that pins zone *at the project-namespace level* is unusable
  because different shoots in the same project must end up in different AZs.
- **Naming convention encodes the AZ** of each shoot (`cc-a0-eu-de-2 → 2a`,
  `lh-eu-de-2b → 2b`). This is exploitable by a simple workaround.
- **Seed storage is Ceph**, replicated across nodes with a single
  `StorageClass`. Volumes are **not** bound to one AZ, unlike AWS EBS or
  Azure Disk. This is operationally important: re-pinning an existing
  control plane to a different AZ does **not** require destroying and
  restoring etcd from backup.

---

## 4. Landscape topology: virtual garden on the runtime seed <a id="4-landscape-topology"></a>

> This section documents a landscape-specific reality that is easy to
> miss on a first read of the Gardener docs. Understanding it changes
> *where* several of the fixes in the [runbook](#8-runbook) have to be
> applied.

### 4.1 The naïve mental model (from the docs)

The Gardener docs describe three separate things:

- A **garden** (control room).
- A **seed** (data-center floor).
- A **shoot** (customer cluster).

Read literally, one would expect each of these to live in its own,
independent Kubernetes cluster. Especially: the *garden* — the central
API where you `kubectl apply -f shoot.yaml` — feels like it must be a
big, stand-alone cluster with its own nodes.

### 4.2 What actually happens on this landscape

The garden is not a stand-alone cluster. In the `qa-de-1` landscape the
**garden itself is a "virtual" Kubernetes cluster that runs as pods
inside the `rt-qa-de-1` seed.** In other words, the garden borrows the
runtime seed's nodes to host its own `kube-apiserver`, `etcd`,
controllers and gardener components.

Concretely:

- The kubeconfig context `g-qa-de-1` points at
  `https://api.virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap`. That
  endpoint is a Service inside `rt-qa-de-1`, exposed via its Istio
  ingress.
- Inside `rt-qa-de-1`, in the `garden` namespace, you can see the pods
  that back it: `virtual-garden-kube-apiserver`,
  `virtual-garden-etcd-main`, `virtual-garden-kube-controller-manager`,
  `gardener-apiserver`, `gardener-controller-manager`, and so on.
- A single `operator.gardener.cloud/v1alpha1` `Garden` custom resource
  named `garden` on the runtime cluster declares this whole setup. Its
  `spec.runtimeCluster` describes `rt-qa-de-1` itself; its
  `spec.virtualCluster` describes the "virtual" garden cluster that we
  reach as `g-qa-de-1`.

The technology behind this pattern is
[**`gardener-operator`**](https://github.com/gardener/gardener/blob/master/docs/concepts/operator.md).
Its job is to take one existing Kubernetes cluster (the *runtime*
cluster) and stand up a "virtual" Kubernetes API on top of it — with
its own etcd, its own apiserver, and the gardener control-plane
components — so that the whole garden lives as workloads inside that
existing cluster instead of needing dedicated hardware.

Baby-steps explanation of the same thing:

- Imagine you have one Kubernetes cluster with lots of spare capacity
  (`rt-qa-de-1`).
- Instead of buying a *second* cluster to be your garden, you deploy a
  set of pods on the first one that together *emulate* a second
  Kubernetes API server (its own etcd, its own apiserver, its own DNS
  name).
- Anyone who talks to that new DNS name gets what looks and feels like
  a separate Kubernetes cluster. That fake-but-fully-working cluster is
  the garden.
- The garden has no nodes of its own — it doesn't need any, because it
  only holds *declarations* (Shoot, Seed, Project, ManagedSeed
  resources), not running workloads.

### 4.3 The full picture of `qa-de-1`

Combining this with everything else on the landscape:

```
                ┌───────────────────────────────────────────────────┐
                │ Runtime seed:  rt-qa-de-1     (real k8s cluster)  │
                │  ─────────────────────────────────────────        │
                │  Provider: openstack    Zones: qa-de-1a, 1b       │
                │  Own nodes: kcp-* control-plane, worker-* workers │
                │                                                   │
                │  Namespace  garden/                               │
                │    ├── virtual-garden-kube-apiserver Pod ─┐       │
                │    ├── virtual-garden-etcd-main     Pod   │= the  │
                │    ├── virtual-garden-kcm           Pod   │  "g-  │
                │    ├── gardener-apiserver           Pod   │  qa-  │
                │    ├── gardener-controller-manager  Pod   │  de-1│
                │    ├── gardener-admission-controller Pod  │       │
                │    └── gardener-operator            Pod  ─┘       │
                │  Namespace  virtual-garden-istio-ingress          │
                │    └── istio-ingressgateway → exposes             │
                │        api.virtual-garden.rt-qa-de-1.…            │
                │                                                   │
                │  Namespace  garden/                               │
                │    └── gardenlet Pod (of rt-qa-de-1 seed)         │
                │                                                   │
                │  Shoot control planes it hosts (namespaces        │
                │  named shoot--…):                                 │
                │    - shoot--garden--mgmt-qa-de-1                  │
                │        (the *shoot* that becomes mgmt-qa-de-1)    │
                │    - shoot--garden--m-qa-de-1                     │
                │    - shoot--wire-api--nw-*-qa-de-* (× 4)          │
                └───────────────────────────────────────────────────┘

                                    │ virtual garden API endpoint
                                    │ https://api.virtual-garden.rt-qa-de-1.…
                                    ▼
                    ┌────────────────────────────────────┐
                    │ Virtual cluster:  g-qa-de-1        │
                    │ (no nodes of its own; pure API)    │
                    │                                    │
                    │  Namespace garden-compute/         │
                    │    Shoot cc-b0-qa-de-1  →seedName= mgmt-qa-de-1
                    │    Shoot cc-b1-qa-de-1  →seedName= mgmt-qa-de-1
                    │    Shoot cc-d0-qa-de-1  →seedName= mgmt-qa-de-1
                    │    Shoot lh-b-qa-de-1   →seedName= mgmt-qa-de-1
                    │                                    │
                    │  Namespace garden/                 │
                    │    Shoot mgmt-qa-de-1   →seedName= rt-qa-de-1
                    │    ManagedSeed mgmt-qa-de-1        │
                    │                                    │
                    │  Cluster-scoped:                   │
                    │    Seed mgmt-qa-de-1               │
                    │    Seed rt-qa-de-1                 │
                    │                                    │
                    │  Namespace seed-mgmt-qa-de-1/      │
                    │    ControllerInstallation × 12     │
                    │    seed-scoped Secrets, SAs        │
                    │                                    │
                    │  Namespace seed-rt-qa-de-1/        │
                    │    ControllerInstallation × 6…     │
                    └────────────────────────────────────┘
                                    │
                                    │ gardenlet on mgmt-qa-de-1 watches
                                    │ Shoot resources with
                                    │ spec.seedName=mgmt-qa-de-1
                                    ▼
                    ┌────────────────────────────────────┐
                    │ Metal seed:  mgmt-qa-de-1          │
                    │ (real k8s cluster, KVM/metal host) │
                    │  Provider: ironcore-metal          │
                    │  Zones: qa-de-1a, qa-de-1b         │
                    │                                    │
                    │  Namespace garden/                 │
                    │    ├── gardenlet Pod               │
                    │    ├── etcd-druid                  │
                    │    ├── gardener-resource-manager   │
                    │    └── extension-provider-*        │
                    │                                    │
                    │  Namespace shoot--compute--cc-b0-…│
                    │    ├── kube-apiserver Pod          │
                    │    ├── etcd-main, etcd-events      │
                    │    ├── kube-controller-manager     │
                    │    └── kube-scheduler              │
                    │  (same layout × 4 shoots)          │
                    └────────────────────────────────────┘
```

Three loops of "cluster inside cluster" are involved:

1. **Gardener-operator loop** — `rt-qa-de-1` hosts the *virtual garden*
   API (`g-qa-de-1`). No dedicated garden hardware exists; the garden
   is a workload on the runtime seed.
2. **ManagedSeed loop** — the `Shoot` named `mgmt-qa-de-1` (declared in
   the virtual garden, scheduled on the runtime seed `rt-qa-de-1`) is
   *itself* promoted to a `Seed` once it comes up. So `mgmt-qa-de-1` is
   both a shoot on `rt-qa-de-1` and a seed hosting other shoots.
3. **Regular shoot loop** — the KVM shoots and Lighthouse shoot declared
   in the virtual garden are scheduled onto `mgmt-qa-de-1`; their
   control planes are pods there; their workers are KVM hypervisors
   elsewhere.

### 4.4 Why this design exists

- **No dedicated hardware for the garden.** The garden used to require
  a separate physical or IaaS cluster with a full kube-apiserver, etcd,
  monitoring stack, and so on. `gardener-operator` collapses that into
  "just a set of pods on an existing seed cluster." One less cluster
  to build and to operate.
- **Uniform operations.** Because the garden runs inside a normal
  Kubernetes cluster (`rt-qa-de-1`), it inherits the same monitoring,
  logging, backup, and lifecycle tooling as any other workload. No
  special "garden ops" playbook.
- **Bootstrap simplicity.** In a green-field landscape, you first
  install one Kubernetes cluster (the runtime), then install
  `gardener-operator` on it, then apply one `Garden` resource. From
  that point on, Gardener bootstraps itself.
- **HA at low cost.** Because the virtual apiserver and etcd are just
  pods, they can be spread across the runtime seed's AZs without
  duplicating infrastructure.

### 4.5 Consequences for `#943` — where fixes must land

This topology changes where we need to act, per acceptance criterion of
the issue. Concretely:

| Acceptance criterion / change                              | Where to act                                                        | Why                                                                                                              |
| ---------------------------------------------------------- | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| Set `Seed.spec.settings.zoneSelection`                      | On the **virtual garden** (kubectl context `g-qa-de-1`).           | The `Seed` CR is stored on the garden API — same as it would be on any Gardener landscape.                       |
| Change the templated `ManagedSeed` for `mgmt-qa-de-1`      | Edit **`system/cc-shoots-mgmt/templates/managedseed.yaml`** in this repo (see §8.1.2). | The `ManagedSeed` is the source of truth. Its `spec.gardenlet.config.seedConfig.spec.settings` is what ends up in the `Seed` CR. Hand-editing the `Seed` is a no-op — it gets overwritten. |
| Install the workerless-CP mutating admission policy         | On the **metal seed `mgmt-qa-de-1`** (kubectl context `mgmt-qa-de-1`). | The `shoot--<project>--<shoot>` namespaces are created by the gardenlet running inside that seed. That is where the CP-zone annotation has to be intercepted. |
| Re-pin an existing misplaced CP (annotate + roll)           | On the **metal seed `mgmt-qa-de-1`**.                              | Namespace + pods live there.                                                                                     |
| Move the *virtual garden itself* into a specific AZ         | Edit `Garden` resource on `rt-qa-de-1` (via `gardener-operator`).   | Different scope; not part of #943. Documented in gardener-operator docs, not here.                              |
| Monitor drift (alerts, dashboards)                          | Prometheus scraping the **seed** cluster (`mgmt-qa-de-1`).          | Node labels and pod schedules live there.                                                                        |

The key insight for a new engineer: **almost every change to fix #943
lands on the `mgmt-qa-de-1` side** — either in this repo (Helm charts
that render the `ManagedSeed`) or directly on that seed cluster. The
virtual garden on `rt-qa-de-1` is only the place where you *read* the
resulting `Seed` CR to confirm the change took effect.

### 4.6 One-liner verifications used to write this section

For future auditors, the commands that established the facts above:

```bash
# g-qa-de-1's kubeconfig points to the virtual-garden endpoint on rt-qa-de-1
u8s kubectl config view --raw -o json \
  | jq -r '.clusters[] | select(.name|contains("g-qa-de-1")) | .cluster.server'
# → https://api.virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap

# The virtual-garden kube-apiserver pods actually run on rt-qa-de-1
u8s --context rt-qa-de-1 kubectl -n garden get pods -l app=kubernetes,role=apiserver \
  -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName
# → virtual-garden-kube-apiserver-…  worker-rt-qa-de-1-…

# The single Garden custom resource that declares this whole setup
u8s --context rt-qa-de-1 kubectl get garden
# → NAME=garden  RUNTIME=True  VIRTUAL=True  API SERVER=True  …

# The virtual garden domain configured inside the Garden CR
u8s --context rt-qa-de-1 kubectl get garden garden \
  -o jsonpath='{.spec.virtualCluster.dns.domains[0].name}'
# → virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap

# The Shoot `mgmt-qa-de-1` (which becomes the metal seed) is scheduled on rt-qa-de-1
u8s --context g-qa-de-1 kubectl -n garden get shoot mgmt-qa-de-1 \
  -o jsonpath='{.spec.seedName}'
# → rt-qa-de-1
```

---

## 5. The upstream feature: `Seed.spec.settings.zoneSelection` <a id="5-upstream-feature"></a>

In Gardener PR [`gardener/gardener#14238`](https://github.com/gardener/gardener/pull/14238)
(merged 2026-03-13) a new setting was added to the `Seed` API:

```yaml
apiVersion: core.gardener.cloud/v1beta1
kind: Seed
metadata:
  name: mgmt-eu-de-2
spec:
  provider:
    type: openstack
    region: eu-de-2
    zones:
      - eu-de-2a
      - eu-de-2b
      - eu-de-2c
  settings:
    zoneSelection: Enforce   # or Prefer (or unset = legacy random)
```

### 5.1 How it works

When a shoot's control plane namespace is created on the seed:

1. Gardener gathers the AZs declared in the shoot's worker pools.
2. It intersects that set with the seed's `spec.provider.zones`.
3. Depending on the mode:
   - **`Prefer`** — if the intersection is non-empty, pick a zone from it;
     otherwise fall back to random selection. Scheduling never fails.
   - **`Enforce`** — if the intersection is non-empty, pick a zone from it;
     otherwise refuse to schedule. The `gardener-scheduler` additionally
     pre-filters seeds with no zone overlap, so a Shoot can be blocked from
     landing on an incompatible seed in the first place.
4. The resulting zone is written as the value of the annotation
   `high-availability-config.resources.gardener.cloud/zones` on the shoot's
   control plane namespace. The `resource-manager` admission webhook
   propagates that into node-affinity rules on every CP pod.

### 5.2 Important caveats

| Caveat                          | Detail                                                                                                                             |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Only one zone is picked         | Even if the shoot's workers span multiple zones. Spreading a non-HA control plane across zones provides no benefit anyway.        |
| Only applies to non-HA / `node` | HA shoots with `failureToleranceType: zone` already spread across AZs by definition. `zoneSelection` is a no-op for them.          |
| One-shot                        | Zone assignment happens at shoot **creation** or restore on a new seed. Adding/changing worker zones later does **not** move the CP. |
| Needs worker zones to function  | Workerless shoots have no worker zones, so the intersection is always empty. `Prefer` falls back to random; `Enforce` will fail.   |
| Zone names must match           | The intersection is by string. On hyperscalers the AZ names are randomized per account, so the feature is mostly intended for OpenStack / metal / sovereign infrastructure where we own the naming. |

### 5.3 What `Prefer` vs `Enforce` means operationally

- **`Prefer`** is "best-effort." Safe to enable broadly. New shoots will
  prefer the right AZ; if they can't, they still get created.
- **`Enforce`** is "must be correct." Use it when an incorrectly placed CP
  is a real problem, not just a nuisance. Our KVM use case is in this
  category.

### 5.4 The zonal-ingress companion problem <a id="5-4-zonal-ingress"></a>

`zoneSelection` only decides **where the CP pods run**. It does *not*
by itself fix another closely related problem: **which load balancer
and which DNS entry are used to reach that CP from outside the
seed.** This is the "zonal ingress" problem raised in the Slack
thread (§2.1, step 5). Understanding the interaction matters for the
rollout plan.

#### Two ways Gardener can lay out Istio ingress on a stretched seed

**Layout A — one default gateway spanning all AZs** (`spec.settings.loadBalancerServices.zonalIngress.enabled: false`)

```
Seed  mgmt-<region>  (stretched across 1a, 1b, 1c)
─────────────────────────────────────────────────

     [   Istio ingress gateway (default)   ]    one LoadBalancer,
             /            |            \        one DNS entry
            /             |             \
       AZ 1a          AZ 1b          AZ 1c
```

- One LoadBalancer, one DNS entry.
- Traffic entering it can be routed to any AZ.
- Fewer moving parts, but not AZ-aware.

**Layout B — one gateway per AZ** (`zonalIngress.enabled: true`)

```
Seed  mgmt-<region>  (stretched across 1a, 1b, 1c)
─────────────────────────────────────────────────

Namespace istio-ingress-1a    Namespace istio-ingress-1b    Namespace istio-ingress-1c

    [ Istio 1a ]                [ Istio 1b ]                [ Istio 1c ]
        │                            │                            │
    LB in 1a                    LB in 1b                    LB in 1c
    DNS: shoot's DNS follows whichever AZ its CP lives in
```

- Three LoadBalancers, three DNS entries.
- Each shoot's public DNS (`api.<shoot>…`) resolves to *one* of these — the one in the same AZ as the shoot's CP.
- More infra to run, but AZ-aware end to end.

#### Why the two topics compound

In **Layout B**, Gardener picks the ingress gateway that lives in
the same AZ as the shoot's CP. So the CP's AZ transitively decides
the ingress AZ, which transitively decides the DNS record. A
misplaced CP therefore breaks **three** things at once, not just
one:

```
random CP placement    →    CP lands in AZ-C
                                 │
                                 ▼
                       Gardener picks the Istio in AZ-C
                                 │
                                 ▼
                       DNS record points at the AZ-C LB
                                 │
                                 ▼
Workers in AZ-A talking to their apiserver:
  DNS  →  AZ-C LoadBalancer  →  AZ-C kube-apiserver pod
     ↑          ↑                      ↑
   wrong     wrong                   wrong AZ
```

This is exactly what Dmitri Fedotov observed on `mgmt-eu-de-3`:
*"Shoot in AZ-A (with workers only in eu-de-3a) dnsrecord pointed to
an AZ-C istio ingress."* Rafael confirmed the root cause: *"The
control plane nodes were (randomly) placed in AZ-C, so they get
exposed via the AZ-C Istio."*

#### The value/regression matrix

The two settings are orthogonal but their combination decides how
much of the AZ-locality goal you actually reap:

| `zoneSelection`     | `zonalIngress` | Result                                                                                                       |
| ------------------- | -------------- | ------------------------------------------------------------------------------------------------------------ |
| unset (random)      | `false`        | Today's qa-de-1 default. Random CP, one shared LB per seed. Suboptimal but predictable.                     |
| unset (random)      | `true`         | **Worst state.** Random CP + random-AZ LB + random-AZ DNS. Every hop crosses AZ boundaries.                 |
| `Prefer`/`Enforce`  | `false`        | CP is in the right AZ. LB is still shared, so ingress hop may still cross AZs — but the CP itself is aligned. |
| `Prefer`/`Enforce`  | `true`         | **Full alignment.** CP + LB + DNS all in the same AZ.                                                        |

**One-sentence takeaway:** zonal ingress is **not an alternative to
`zoneSelection`; it is the layer that reaps `zoneSelection`'s
benefits**. Doing only one of the two is half a solution. Doing
both is the full picture.

#### Landscape state today

At time of writing:

| Seed          | `zoneSelection` | `zonalIngress.enabled` | Notes                                                                                              |
| ------------- | --------------- | ---------------------- | -------------------------------------------------------------------------------------------------- |
| `mgmt-qa-de-1`| unset           | `false`                | Layout A. Enabling `zoneSelection` here is safe — no zonal-ingress interaction.                    |
| `rt-qa-de-1`  | unset           | `false`                | Layout A. Same as above.                                                                            |
| `mgmt-eu-de-3`| unset           | `true`                 | **Layout B**. This is where Dmitri saw the "DNS in wrong AZ" symptom. Enabling `zoneSelection` here will also retroactively fix the ingress AZ on the next shoot reconcile. |

#### Consequences for the rollout plan

Because the two settings compound, the rollout is best done in
phases so each step has a clean cost/benefit story:

1. **Phase 1 (this PR)** — enable `zoneSelection: Prefer` on
   `mgmt-qa-de-1`. `zonalIngress` stays at `false`. Fixes CP
   placement for `cc-b*` shoots in isolation, zero interaction with
   ingress. Zero regression risk.
2. **Phase 2** — flip qa-de-1 from `Prefer` to `Enforce` once the
   `cc-d0-qa-de-1` zone-list gap is resolved (see
   `gardener-qa-de-1-cp-az-findings.md`).
3. **Phase 3** — separately design and enable `zonalIngress: true`
   on stretched seeds that already have `zoneSelection` on, to
   collect the ingress-side benefit. This is its own runbook because:
   - It multiplies the LoadBalancer count per seed (cost implications).
   - It introduces new DNS records and a migration/cache-flush plan.
   - Blast radius changes: per-AZ LB failure becomes a per-AZ shoot outage instead of a shared one.
4. **Phase 4** — for landscapes that already have `zonalIngress:
   true` (e.g. `mgmt-eu-de-3`), turning on `zoneSelection` also
   *retroactively fixes* the "DNS in wrong AZ" symptom on the next
   shoot reconcile. Handle these as a separate rollout wave.

This layered plan is why the first PR is scoped to just
`zoneSelection: Prefer` on qa-de-1: it's the piece with the
smallest blast radius and no interaction with the ingress layer,
which we can iterate on independently.

---

## 6. The remaining gap: workerless shoots <a id="6-the-gap"></a>

Lighthouse shoots have **no worker pools**, so `zoneSelection` cannot derive
a zone from them. As of writing (2026-06), the upstream design discussion is
still open. Two candidate designs are on the table:

- **Add `Shoot.spec.controlPlane.zone`** that is honored only for
  workerless shoots.
- **Add `Shoot.spec.controlPlane.zone`** that is honored for *all* shoots
  and overrides the worker-derived selection (allowing planned-maintenance
  zone flips, etc.).

Our preference is the second variant. Tracking the upstream discussion is
part of the follow-up work for #943.

Until that ships, we need a downstream workaround. See
[§8 Runbook](#8-runbook) for the concrete mechanism.

---

## 7. Decision matrix: which solution per cluster type <a id="7-decision-matrix"></a>

This is the per-cluster-type placement documentation required by acceptance
criterion #2 of [`#943`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/943).

| Cluster type                                          | Workers? | CP placement requirement              | Recommended mechanism                                                                          |
| ----------------------------------------------------- | -------- | ------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **KVM compute shoot** (`cc-*`)                        | Yes, one AZ          | CP must run in worker AZ              | `Seed.spec.settings.zoneSelection: Enforce`. (See §8.1.)                                       |
| **Lighthouse shoot** (`lh-*`)                         | None                 | CP must run in the AZ it serves       | Downstream mutating admission policy that sets the `…/zones` annotation from the namespace name. (See §8.2.) Long-term: upstream `Shoot.spec.controlPlane.zone`. |
| **Stretched Ceph storage shoot** (`st1-*` etc.)       | Yes, multiple AZs    | CP may live anywhere; `zone`-HA preferred | Set `failureToleranceType: zone` on the shoot; `zoneSelection` is a no-op. No action needed.    |
| **Regional regular shoot** (BTP, customer, …)         | Varies               | No AZ-locality requirement            | Leave default (random). Optionally `Prefer`.                                                   |
| **HA shoot with `failureToleranceType: zone`**        | n/a                  | Spread across AZs                     | `zoneSelection` has no effect on these. No action.                                             |

---

## 8. Operational runbook <a id="8-runbook"></a>

This section covers the concrete actions: how to enable the feature, how to
fix already-misplaced shoots, and how to handle workerless shoots.

### 8.1 Enable `zoneSelection: Enforce` on a stretched seed

#### 8.1.1 Pre-flight checklist

Before flipping the setting on a seed that already hosts running shoots:

1. **Identify shoots that would be rejected by `Enforce`.**
   List all shoots scheduled on the seed where the worker pool zones do not
   intersect the seed's zones, e.g.:

   ```bash
   kubectl --context garden get shoot --all-namespaces \
     -o json \
     | jq '.items[]
           | select(.spec.seedName == "mgmt-eu-de-2")
           | {ns:.metadata.namespace, name:.metadata.name,
              workerZones:[.spec.provider.workers[].zones[]] | unique,
              seedZones:["eu-de-2a","eu-de-2b","eu-de-2c"]}'
   ```

   Any shoot whose `workerZones` is empty (workerless) or has no overlap
   with `seedZones` would be blocked from re-scheduling under `Enforce`.
   Decide per shoot whether it is okay to leave untouched (CP already
   placed) or whether it needs a different mechanism.

2. **Confirm the seed zone list is correct.**
   `kubectl --context garden get seed mgmt-eu-de-2 -o yaml | yq '.spec.provider.zones'`

3. **Decide `Prefer` vs `Enforce`.**
   For a seed that exclusively hosts AZ-local shoots, `Enforce` is the right
   answer. For a seed that hosts a mix (KVM compute + regional shoots),
   `Prefer` is safer.

#### 8.1.2 Apply the setting

The `Seed` CR is generated from a `ManagedSeed` CR, which is in turn
generated by a Helm chart in this repo. **Do not hand-edit the `Seed`
CR** — the change would be overwritten on the next `gardener-operator`
/ `gardenlet` reconciliation.

The file to edit is **`system/cc-shoots-mgmt/templates/managedseed.yaml`**
in this repo. Add the `zoneSelection` field under
`spec.gardenlet.config.seedConfig.spec.settings`:

```yaml
# system/cc-shoots-mgmt/templates/managedseed.yaml
spec:
  gardenlet:
    config:
      seedConfig:
        spec:
          settings:
            # existing settings kept as-is
            excessCapacityReservation:
              enabled: false
            dependencyWatchdog:
              prober:
                enabled: false
            loadBalancerServices:
              externalTrafficPolicy: Local
              zonalIngress:
                enabled: false
            # NEW: pin shoot control-plane pods to the same AZ as
            # the shoot's worker pool (KVM compute case).
            zoneSelection: Enforce
```

After merging, the deployment pipeline for this chart applies the
change to every `mgmt-*` seed in every landscape. To scope the change
to specific landscapes only (e.g. roll out on QA first), template the
value from `.Values.mgmtShoots[<landscape>]` and add per-landscape
overrides in your values file.

Verify propagation on the target landscape:

```bash
# 1. ManagedSeed on the virtual garden shows the new setting
u8s --context g-<region> kubectl -n garden get managedseed mgmt-<region> \
  -o jsonpath='{.spec.gardenlet.config.seedConfig.spec.settings.zoneSelection}'
# expected: Enforce

# 2. Seed CR itself has been reconciled by gardener-operator
u8s --context g-<region> kubectl get seed mgmt-<region> \
  -o jsonpath='{.spec.settings.zoneSelection}'
# expected: Enforce
```

If step 1 shows `Enforce` but step 2 shows nothing, wait one reconcile
cycle (up to a few minutes) or force one:

```bash
u8s --context g-<region> kubectl -n garden annotate managedseed mgmt-<region> \
  gardener.cloud/operation=reconcile --overwrite
```

#### 8.1.3 Verify on a new shoot

```bash
# create a test shoot with workers only in eu-de-2a
kubectl --context garden -n garden-<project> apply -f test-shoot.yaml

# wait for shoot reconciliation
kubectl --context garden -n garden-<project> get shoot test-shoot -w

# check the CP namespace annotation on the seed
kubectl --context mgmt-eu-de-2 \
  get ns shoot--<project>--test-shoot \
  -o jsonpath='{.metadata.annotations.high-availability-config\.resources\.gardener\.cloud/zones}'
# expected: eu-de-2a

# check the actual node where kube-apiserver landed
kubectl --context mgmt-eu-de-2 \
  -n shoot--<project>--test-shoot \
  get pod -l app=kubernetes -l role=apiserver \
  -o jsonpath='{.items[*].spec.nodeName}' \
  | xargs -n1 kubectl --context mgmt-eu-de-2 get node -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}{"\n"}'
# expected: eu-de-2a
```

### 8.2 Pin a workerless shoot's CP to a specific AZ (interim solution)

Until an upstream `Shoot.spec.controlPlane.zone` field exists, use a
mutating admission policy in the **seed cluster** to set the
`…/zones` annotation on the shoot's control plane namespace at creation
time. Our naming convention encodes the AZ, so the policy can derive it
without reading other resources.

Naming convention assumed:

- `lh-eu-de-2a-…` → zone `eu-de-2a`
- `lh-eu-de-2b-…` → zone `eu-de-2b`
- `lh-eu-de-2c-…` → zone `eu-de-2c`

#### 8.2.1 The mutating admission policy

```yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingAdmissionPolicy
metadata:
  name: pin-lighthouse-cp-zone
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups:   [""]
        apiVersions: ["v1"]
        operations:  ["CREATE"]
        resources:   ["namespaces"]
  matchConditions:
    # only act on shoot control plane namespaces …
    - name: is-shoot-ns
      expression: "object.metadata.name.startsWith('shoot--')"
    # … that belong to a Lighthouse shoot
    - name: is-lighthouse
      expression: "object.metadata.name.contains('--lh-')"
  mutations:
    - patchType: ApplyConfiguration
      applyConfiguration:
        expression: |
          Object{
            metadata: Object.metadata{
              annotations: {
                "high-availability-config.resources.gardener.cloud/zones":
                  // extract eu-de-2a / -2b / -2c from a name like
                  // shoot--<project>--lh-eu-de-2a-foo
                  object.metadata.name.find("eu-de-[0-9]+[a-z]")
              }
            }
          }
```

> **Note:** `MutatingAdmissionPolicy` (CEL-based, no webhook) requires
> Kubernetes ≥ 1.32 with the `MutatingAdmissionPolicy` feature gate enabled.
> If the seed runs an older version, deploy this as a small mutating
> admission **webhook** instead — same logic, more moving parts.

#### 8.2.2 Apply the policy and a binding

```yaml
apiVersion: admissionregistration.k8s.io/v1beta1
kind: MutatingAdmissionPolicyBinding
metadata:
  name: pin-lighthouse-cp-zone
spec:
  policyName: pin-lighthouse-cp-zone
  validationActions: [Deny]
```

(Install both into the **seed cluster**, not the garden cluster.)

#### 8.2.3 Test before relying on it

```bash
# dry-run namespace creation to confirm the annotation is added
kubectl --context mgmt-eu-de-2 create ns shoot--compute--lh-eu-de-2b-test \
  --dry-run=server -o yaml \
  | yq '.metadata.annotations'
# expected to contain:
#   high-availability-config.resources.gardener.cloud/zones: eu-de-2b
```

Only after this is confirmed should Lighthouse shoots be (re)created.

### 8.3 Fix a control plane that is already in the wrong AZ

The general Gardener answer: re-pinning an existing CP usually requires
destroying etcd volumes and restoring from backup, because etcd's PVs are
bound to one AZ on hyperscaler storage.

**In our environment, etcd lives on Ceph**, which is not AZ-bound. We can
therefore do an in-place re-pin:

```bash
# 1. set the new zone on the CP namespace
kubectl --context mgmt-eu-de-2 annotate ns shoot--compute--cc-a0-eu-de-2 \
  high-availability-config.resources.gardener.cloud/zones=eu-de-2a \
  --overwrite

# 2. roll the control plane so the new node-affinity takes effect
kubectl --context mgmt-eu-de-2 -n shoot--compute--cc-a0-eu-de-2 \
  rollout restart deploy

# 3. trigger a reconciliation so Gardener re-renders dependent resources
kubectl --context garden -n garden-compute annotate shoot cc-a0-eu-de-2 \
  gardener.cloud/operation=reconcile --overwrite

# 4. verify CP pods are in the right zone (see §8.1.3 for the check)
```

> **Do not do this on a hyperscaler-backed seed without first verifying
> that the underlying storage is zone-agnostic.** On AWS/Azure/GCP this
> procedure will fail or cause data loss; you'd need an etcd backup-restore
> dance instead.

### 8.4 Migration plan for the existing landscape

1. **Identify all stretched seeds hosting AZ-local KVM shoots.**
2. **For each seed:**
   - Apply the §8.1 pre-flight checklist.
   - Set `zoneSelection: Enforce` via the Helm chart for that seed.
   - Roll out and wait until the next reconciliation window.
3. **For each existing KVM shoot currently in the wrong AZ:** apply §8.3.
4. **Deploy the mutating admission policy from §8.2 on every seed that
   hosts Lighthouse shoots.**
5. **Re-create Lighthouse shoots** (or, if they exist, apply §8.3 to them
   too).
6. **Run the verification checks from §9** and confirm all alerts are green.

---

## 9. Verification, monitoring, and alerting <a id="9-verification"></a>

### 9.1 One-off verification commands

```bash
# Across all shoots on a seed, print: shoot name | expected zone | actual zone
kubectl --context mgmt-eu-de-2 get ns -o json \
  | jq -r '.items[]
           | select(.metadata.name | startswith("shoot--"))
           | "\(.metadata.name)\t\(.metadata.annotations["high-availability-config.resources.gardener.cloud/zones"] // "RANDOM")"'
```

For each shoot, look up the actual AZ of its `kube-apiserver` pod:

```bash
for ns in $(kubectl --context mgmt-eu-de-2 get ns -o name \
              | grep '^namespace/shoot--' \
              | cut -d/ -f2); do
  zone=$(kubectl --context mgmt-eu-de-2 -n "$ns" \
           get pod -l role=apiserver \
           -o jsonpath='{.items[0].spec.nodeName}' 2>/dev/null \
         | xargs -I{} kubectl --context mgmt-eu-de-2 get node {} \
           -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' 2>/dev/null)
  expected=$(kubectl --context mgmt-eu-de-2 get ns "$ns" \
              -o jsonpath='{.metadata.annotations.high-availability-config\.resources\.gardener\.cloud/zones}')
  echo "$ns	expected=$expected	actual=$zone"
done
```

### 9.2 Prometheus alert

A drift alert: fire when a `kube-apiserver` pod's actual AZ does not match
the AZ encoded in its namespace's annotation.

```yaml
groups:
  - name: shoot-cp-az-placement
    rules:
      - alert: ShootControlPlaneInWrongAZ
        expr: |
          (
            label_replace(
              kube_pod_info{namespace=~"shoot--.*", pod=~"kube-apiserver-.*"}
              * on(node) group_left(label_topology_kubernetes_io_zone)
              kube_node_labels,
              "actual_zone", "$1", "label_topology_kubernetes_io_zone", "(.*)"
            )
          )
          unless on(namespace, actual_zone) (
            label_replace(
              kube_namespace_annotations{
                annotation_high_availability_config_resources_gardener_cloud_zones!=""
              },
              "actual_zone", "$1",
              "annotation_high_availability_config_resources_gardener_cloud_zones", "(.*)"
            )
          )
        for: 15m
        labels:
          severity: warning
          service: gardener
        annotations:
          summary: "Shoot control plane is not in its expected AZ"
          description: |
            Pod {{ $labels.pod }} in namespace {{ $labels.namespace }}
            is running in {{ $labels.actual_zone }} but the namespace
            annotation pins it to a different zone.
```

> The exact PromQL depends on the labels exposed by `kube-state-metrics` in
> the seed. Treat the rule above as a template — adapt to whichever
> exporter is in use on the landscape.

### 9.3 Other monitoring touchpoints

- **Istio ingress symmetry.** Verify each shoot's DNS record resolves to
  the ingress LB in the expected AZ. The Slack thread on #943 documents
  this as the original visible symptom.
- **Seed condition.** When `zoneSelection: Enforce` rejects a shoot, the
  seed surfaces a condition / event. Surface those in the standard
  Gardener dashboards.

---

## 10. Open questions / follow-ups <a id="10-open-questions"></a>

These are not blockers for the current rollout but must be tracked.

1. **Upstream `Shoot.spec.controlPlane.zone`.**
   Drive the upstream discussion (Rafael Franzke / Tim Usner). Aim for the
   "field allowed for all shoots, overrides worker-derived selection"
   variant, because it also enables planned-maintenance zone flips.
   Once merged, migrate all Lighthouse shoots off the admission-policy
   workaround.

2. **Ceph zone semantics for dual-AZ shoots.**
   Open question from the Slack thread: in a seed where Ceph spans all AZs
   with a single StorageClass, what does "zone failure" actually mean for
   shoot volumes? Do we need per-AZ StorageClasses + per-AZ CephBlockPools,
   or is the Ceph arbiter design sufficient? This is orthogonal to #943 but
   is on the same critical path for Bedrock.

3. **Migration of stretched Ceph storage shoots.**
   These are HA-zone shoots and not in scope for `zoneSelection`. But the
   doc must explicitly state that they are intentionally exempt, so future
   operators don't try to "fix" them.

4. **Naming convention enforcement.**
   The §8.2 admission policy depends on the AZ being in the shoot name. A
   companion **validating** admission policy in the garden cluster should
   reject Lighthouse shoots without a parseable name, so the runtime policy
   is never silently wrong.

5. **Workerless KVM-control-plane shoots beyond Lighthouse.**
   Anticipate other workerless single-AZ use cases (e.g. per-AZ tenant
   APIs). The §8.2 policy already covers them as long as the naming
   convention extends.

---

## 11. Glossary <a id="11-glossary"></a>

| Term                                | Definition                                                                                                            |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Annotation**                      | A free-form `key=value` attached to a Kubernetes object's metadata. Used here on the seed-side namespace.            |
| **AZ (Availability Zone)**          | A physically independent data center within a cloud region.                                                           |
| **Bedrock**                         | Internal codename of the external-customer dataplane initiative driving #943.                                         |
| **Ceph**                            | A distributed storage system that replicates data across many nodes. Not bound to a single AZ in our setup.           |
| **etcd**                            | The key-value database underpinning every Kubernetes cluster. Persistent, pinned to a disk, hence usually to an AZ.   |
| **Failure tolerance type**          | `node` or `zone`. Controls whether a Gardener shoot's control plane survives a node loss or a zone loss.              |
| **Garden cluster**                  | The central Kubernetes cluster where all `Shoot` and `Seed` resources live.                                           |
| **Istio ingress gateway**           | The front door for traffic entering a shoot's apiserver. One per AZ in our setup ("zonal ingress").                   |
| **kubelet**                         | The node agent that pulls work from the apiserver. On the shoot's workers it talks to the shoot's apiserver.          |
| **Lighthouse cluster**              | A workerless Gardener shoot acting as a single API entry point per AZ for KVM compute clusters in that AZ.            |
| **Mutating admission policy / webhook** | A piece of code that intercepts Kubernetes resource creation and modifies the object before it is persisted.       |
| **Project namespace**               | The namespace in the garden cluster that owns a set of shoots (e.g. `garden-compute`). All KVM shoots share one.      |
| **Seed cluster**                    | A Kubernetes cluster that hosts shoot control planes as pods.                                                         |
| **Shoot cluster**                   | The end-user Kubernetes cluster. Its control plane lives in a seed; its workers live elsewhere.                       |
| **Stretched seed**                  | A seed whose worker nodes span multiple AZs.                                                                          |
| **Workerless shoot**                | A shoot with no worker pools. Only the control plane exists.                                                          |
| **Zone-pinning annotation**         | `high-availability-config.resources.gardener.cloud/zones` on the CP namespace. Sets node-affinity on every CP pod.    |

---

## 12. References <a id="12-references"></a>

- Issue: [`cc/unified-kubernetes#943`](https://github.wdf.sap.corp/cc/unified-kubernetes/issues/943)
- Upstream PR: [`gardener/gardener#14238`](https://github.com/gardener/gardener/pull/14238) — *Add zone selection setting to `Seed`s for AZ-aware control plane placement*
- Upstream docs: [`gardener/gardener` — Seed settings § Zone Selection](https://github.com/gardener/gardener/blob/master/docs/operations/seed_settings.md#zone-selection)
- Slack thread (internal): [`#converged-cloud`](https://convergedcloud.slack.com/archives/C07C3T6GTEU/p1772466005684939) — summarized in [§2.1](#2-1-slack-summary).
- Related: high-availability config — [`gardener/gardener` — high-availability of deployed components](https://github.com/gardener/gardener/blob/master/docs/development/high-availability-of-components.md)
