# Gardener Architecture Explained — Garden, Runtime, Seed, Shoot

> **Audience:** engineers new to Gardener (and specifically to SAP's
> flavor of Gardener) who want to understand what the layers *actually
> are*, where they run, and how "a working cluster" is really managed.
>
> **Style:** plain language, layman analogies first, verified facts
> second. Every non-obvious claim has a `kubectl` command you can run
> to see it for yourself. All examples use the `qa-de-1` landscape.

---

## Table of contents

1. [Why this doc exists](#1-why)
2. [The 30-second summary](#2-30sec)
3. [The four layers and what each is for](#3-four-layers)
4. [How a shoot goes from YAML to running cluster](#4-lifecycle)
5. [The special case: garden as a workload (virtual garden)](#5-virtual-garden)
6. [The special case: seed as a shoot (ManagedSeed)](#6-managedseed)
7. [Where every resource lives — the map](#7-resource-map)
8. [The controllers doing the work](#8-controllers)
9. [`qa-de-1` walkthrough — a fully worked example](#9-qa-de-1-walkthrough)
10. [Common misconceptions](#10-misconceptions)
11. [Glossary](#11-glossary)
12. [References](#12-references)

---

## 1. Why this doc exists <a id="1-why"></a>

Gardener's docs use words like **garden**, **seed**, **shoot**,
**runtime cluster**, **managed seed**, **virtual garden**. Each has a
crisp definition, but the terms are close enough that many engineers
end up with a fuzzy picture. Especially:

- People think the **garden** is a big, separate physical cluster.
  It usually is not.
- People think a **seed** always runs on dedicated infrastructure.
  It usually does not.
- People think a **shoot** is completely independent from a seed.
  It is not — its brain (control plane) runs inside a seed.
- People think **management cluster** is a formal Gardener term.
  It is not — it is SAP shorthand.

This doc pins down each term with a verified example so the picture
becomes unambiguous. It is not a replacement for the upstream
Gardener docs; it is a *ground-truth companion* for our landscape.

---

## 2. The 30-second summary <a id="2-30sec"></a>

- Gardener manages many Kubernetes clusters at scale.
- It splits the world into three logical layers: **garden** (control
  room), **seed** (hosting substrate), **shoot** (customer cluster).
- On SAP landscapes, all three layers are themselves Kubernetes
  clusters — and they run *inside each other* in a Russian-doll
  arrangement:
  - The **runtime cluster** is a plain Kubernetes cluster we install
    once. It has real nodes.
  - `gardener-operator` runs on the runtime cluster and stands up a
    **virtual garden** — a set of pods that together *look and feel
    like* a separate Kubernetes API. That is "the garden."
  - The **seed** clusters (like `mgmt-qa-de-1`) are shoots that
    Gardener created *and then promoted* to be seeds via a
    `ManagedSeed`. So a seed is itself a shoot managed by Gardener.
  - The **shoots** (like `cc-b0-qa-de-1`, `lh-b-qa-de-1`) have their
    control planes hosted as pods on a seed. Their worker nodes live
    on the underlying infrastructure (bare metal, OpenStack, …).
- A daemon called **`gardenlet`** runs inside every seed and does
  the actual work of creating and reconciling shoot control planes.
- The garden holds the *declarations*; the seeds hold the *running
  workloads*; the runtime holds *the garden itself*.

That is the whole picture. The rest of the doc unpacks each part.

---

## 3. The four layers and what each is for <a id="3-four-layers"></a>

The mental model that finally makes everything click:

| Layer               | What it is                                                          | Analogy                                     | Kubernetes cluster? |
| ------------------- | ------------------------------------------------------------------- | ------------------------------------------- | ------------------- |
| **Runtime cluster** | A plain Kubernetes cluster where `gardener-operator` runs. It hosts the pods that together form the garden. | The building the control room is in.        | Yes — with real nodes. |
| **Garden (virtual cluster)** | An API-only Kubernetes cluster that stores all Gardener declarations (Shoots, Seeds, Projects, …). No nodes of its own; its pods live inside the runtime. | The control room itself. Full of clipboards. | Yes — but its "nodes" are borrowed from the runtime. |
| **Seed cluster**    | A Kubernetes cluster whose job is to *host* shoot control planes as pods. | A hotel building. Each guest is a shoot. Each hotel room is a `shoot--…` namespace. | Yes — real nodes. |
| **Shoot cluster**   | The customer-facing Kubernetes cluster. Its control plane lives in a seed; its worker nodes live on real infrastructure. | The guest staying at the hotel. Their brain (CP) sleeps in the hotel; their body (workers) roams the city. | Yes — real nodes for workers; CP is pods in the seed. |

### Concise diagram

```
┌────────────────────────────────────────────────────────────────┐
│  Runtime cluster  (real k8s, real nodes)                       │
│                                                                │
│   ┌────────────────────────────────────────────────────────┐   │
│   │  Virtual garden  (k8s API, no nodes of its own)        │   │
│   │  - kube-apiserver, etcd, gardener-apiserver (as pods)  │   │
│   │  - Shoots, Seeds, Projects, ManagedSeeds live here     │   │
│   └────────────────────────────────────────────────────────┘   │
│                                                                │
│   (also: shoot CPs of shoots whose seedName = the runtime)     │
└────────────────────────────────────────────────────────────────┘

              ┌────────────────────────────────────────┐
              │  Seed cluster  (real k8s, real nodes) │
              │                                        │
              │   namespace garden/                    │
              │     ├── gardenlet                      │
              │     ├── extension controllers          │
              │     └── etcd-druid, resource-manager   │
              │                                        │
              │   namespace shoot--project--shoot1/    │
              │     ├── kube-apiserver Pod             │
              │     ├── etcd Pods                      │
              │     └── kube-scheduler, KCM, …         │
              │                                        │
              │   namespace shoot--project--shoot2/    │
              │     └── …                              │
              └────────────────────────────────────────┘

              ┌────────────────────────────────────────┐
              │  Shoot cluster  (customer-facing)      │
              │  - Worker nodes on IaaS / bare metal   │
              │  - Control plane = pods in a seed      │
              └────────────────────────────────────────┘
```

### Why we need all four

You could imagine collapsing some of these into one. Historically
Gardener did:

- Very old: garden was a dedicated cluster with its own hardware. Seed
  was a dedicated cluster. Every shoot had its own dedicated CP infra.
- Modern: `gardener-operator` collapses the garden onto an existing
  cluster (the runtime). `ManagedSeed` collapses the seeds onto shoots
  that Gardener manages. The end result: **one Kubernetes cluster you
  install by hand (the runtime); everything else is bootstrapped from
  there.**

That is the design goal — minimum manual infrastructure, everything
else built and managed by Gardener itself.

---

## 4. How a shoot goes from YAML to running cluster <a id="4-lifecycle"></a>

Follow the lifecycle of `cc-b0-qa-de-1` — a real KVM compute shoot on
qa-de-1 — step by step.

```
Step 1  ─────────────────────────────────────────
        A user (or GitOps) applies a Shoot YAML to the virtual garden.

        u8s --context g-qa-de-1 kubectl -n garden-compute apply -f cc-b0.yaml

        The Shoot resource now exists in the virtual-garden's etcd.
        Nothing is running yet.

Step 2  ─────────────────────────────────────────
        gardener-scheduler (a controller in the garden) picks a seed.

        Looks at:
          - the shoot's provider (ironcore-metal)
          - the seed's provider (must match: mgmt-qa-de-1 matches)
          - taints, capacity, zone settings, …

        Writes:  spec.seedName: mgmt-qa-de-1

Step 3  ─────────────────────────────────────────
        gardenlet, running INSIDE mgmt-qa-de-1, sees the assignment.

        It talks to the virtual-garden's API (over the internet)
        using a kubeconfig secret. It watches for
          Shoot where spec.seedName == mgmt-qa-de-1

        For each match, it starts reconciling.

Step 4  ─────────────────────────────────────────
        gardenlet creates a namespace on the SEED:
          shoot--compute--cc-b0-qa-de-1

        It also creates, in that namespace:
          - kube-apiserver Deployment + Service (+ Istio route)
          - etcd StatefulSets (etcd-main, etcd-events)
          - kube-controller-manager Deployment
          - kube-scheduler Deployment
          - gardener-resource-manager Deployment
          - machine-controller-manager Deployment
          - Secrets, ConfigMaps, PVCs, NetworkPolicies …

        These are just pods and objects on the SEED cluster. To the
        seed, they look like any other workload.

Step 5  ─────────────────────────────────────────
        Extension controllers kick in.

        provider-ironcore-metal (installed on the seed) reads the
        shoot's spec and creates:
          - Machine resources (via machine-controller-manager)
          - Networks, LoadBalancers, DNS records
        Those Machines become real bare-metal servers running as
        KVM hypervisors — the shoot's WORKER NODES.

        These workers live on separate physical hardware, NOT inside
        the seed. They only *talk* to the seed (specifically, to the
        kube-apiserver pod there) via the Istio ingress on the seed.

Step 6  ─────────────────────────────────────────
        The shoot is up.

        - Its Kubernetes API endpoint is a DNS name pointing at the
          seed's Istio ingress LB, which forwards to the
          kube-apiserver Pod in shoot--compute--cc-b0-qa-de-1.
        - Its worker nodes exist as real machines somewhere else.
        - Its state (etcd) is stored on volumes in the seed.

        gardenlet reports back to the virtual garden:
          Shoot.status.lastOperation.state = Succeeded
```

The key insight: **at no point does the garden do the actual work.**
The garden only holds the declaration. All the work is done by
`gardenlet` on the seed, plus extensions running alongside it.

You can watch this happen live:

```bash
u8s --context g-qa-de-1 kubectl -n garden-compute get shoot cc-b0-qa-de-1 -w
u8s --context mgmt-qa-de-1 kubectl -n shoot--compute--cc-b0-qa-de-1 get pods
```

---

## 5. The special case: garden as a workload (virtual garden) <a id="5-virtual-garden"></a>

### What the naïve model says

"The garden is a separate Kubernetes cluster. It has its own nodes,
its own etcd, its own kube-apiserver. You install it once, and from
there you manage everything."

That was historically true. It's not true on `qa-de-1` today.

### What actually happens

On `qa-de-1`:

1. There is a plain Kubernetes cluster called **`rt-qa-de-1`** — the
   *runtime cluster*. It has real worker nodes provisioned on
   OpenStack.
2. Inside the `garden` namespace of `rt-qa-de-1`, someone installed
   the **`gardener-operator`** Deployment. That operator is the
   bootstrap piece.
3. Someone applied a single **`Garden`** custom resource named
   `garden` to `rt-qa-de-1`. This resource declares "I want a
   virtual garden with these properties."
4. `gardener-operator` reconciles that resource by creating a bunch
   of pods **inside `rt-qa-de-1`** that together *emulate* a
   Kubernetes cluster:
   - `virtual-garden-kube-apiserver` (a real kube-apiserver process,
     configured to be the "garden API").
   - `virtual-garden-etcd-main` and `virtual-garden-etcd-events`
     (etcd for that apiserver).
   - `virtual-garden-kube-controller-manager`.
   - `gardener-apiserver` (adds the `core.gardener.cloud`,
     `seedmanagement.gardener.cloud`, etc. APIs on top).
   - `gardener-controller-manager`, `gardener-admission-controller`,
     `gardener-scheduler`, `gardener-dashboard`.
5. It also creates a Service in the `virtual-garden-istio-ingress`
   namespace exposing the virtual apiserver behind a DNS name:
   `api.virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap`.

That DNS name is what you connect to when you use the kubectl context
`g-qa-de-1`. From the outside, it looks and feels like a completely
separate Kubernetes cluster. From the inside, it's just a service
running on `rt-qa-de-1`.

### Verified with kubectl

```bash
# g-qa-de-1 kubeconfig points to a URL on rt-qa-de-1:
u8s kubectl config view --raw -o json \
  | jq -r '.clusters[] | select(.name|contains("g-qa-de-1")) | .cluster.server'
# → https://api.virtual-garden.rt-qa-de-1.qa-de-1.cloud.sap

# The kube-apiserver pods that back that URL are pods on rt-qa-de-1:
u8s --context rt-qa-de-1 kubectl -n garden get pods \
    -l app=kubernetes,role=apiserver \
    -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName
# → virtual-garden-kube-apiserver-…  worker-rt-qa-de-1-…

# Only one Garden CR declares this whole setup:
u8s --context rt-qa-de-1 kubectl get garden
# NAME=garden  RUNTIME=True  VIRTUAL=True  API SERVER=True  …
```

### Why "virtual"?

The word "virtual" is Gardener's term. It means: the garden acts like
a real Kubernetes cluster (it has its own etcd, its own apiserver,
its own DNS, its own resources) but it does not sit on dedicated
hardware — it borrows the nodes of the runtime cluster to run its
pods. If `rt-qa-de-1` is up, the virtual garden is up. If
`rt-qa-de-1` dies, the virtual garden dies with it (and needs to be
restored from backup).

### Why do it this way?

- **One less cluster to build and operate.** No dedicated hardware
  just for "the garden." One less bootstrapping step.
- **Same tooling.** Because the virtual garden runs as pods, you can
  monitor it, back it up, and upgrade it with the same tools you use
  for any workload.
- **Cheap HA.** The virtual apiserver and etcd pods can spread across
  the runtime cluster's AZs without duplicating infrastructure.
- **Bootstrap simplicity.** You install one Kubernetes cluster (the
  runtime), install `gardener-operator`, apply one `Garden` resource,
  and Gardener bootstraps itself from there.

### Consequences you need to remember

- **`g-qa-de-1` is not a place where workloads run.** It only exists
  as an API. Its "pods" list will be short or empty.
- **The garden's uptime depends on the runtime cluster's uptime.**
  If `rt-qa-de-1` goes down, existing shoots keep running (because
  gardenlet on each seed continues its steady-state work), but you
  cannot create/modify shoots until the garden is restored.
- **The runtime cluster is often *also* a seed.** In qa-de-1,
  `rt-qa-de-1` is registered as a `Seed` and hosts shoot CPs
  (specifically the shoot named `mgmt-qa-de-1`, plus several
  workerless shoots). So the same nodes serve triple duty: runtime +
  seed + apiserver-hosting.

---

## 6. The special case: seed as a shoot (ManagedSeed) <a id="6-managedseed"></a>

### What the naïve model says

"A seed is a Kubernetes cluster you install and configure separately.
You then tell Gardener 'here is a seed you can use' and it registers
it."

### What actually happens

That model still exists (called an *unmanaged seed*), but on qa-de-1
we use **`ManagedSeed`**, a more automated pattern.

A ManagedSeed says: "please take this Shoot and, once it's up,
promote it to also be a Seed."

Concretely for `mgmt-qa-de-1`:

1. There is a **Shoot named `mgmt-qa-de-1`** in the virtual garden,
   in namespace `garden`. Its `spec.provider.type` is
   `ironcore-metal`. Its `spec.seedName` is `rt-qa-de-1`. So
   Gardener creates it as a normal shoot, with its control plane on
   `rt-qa-de-1`.
2. Once that shoot is `Ready`, gardener acts on a **`ManagedSeed`
   named `mgmt-qa-de-1`** which references that shoot. The
   ManagedSeed says "also install a gardenlet inside this cluster,
   and register it as a Seed."
3. A `Seed` CR (cluster-scoped) named `mgmt-qa-de-1` appears in the
   virtual garden. It is *generated* from the ManagedSeed — you
   never edit the Seed CR by hand.
4. gardenlet is installed inside `mgmt-qa-de-1`. From that moment
   on, `mgmt-qa-de-1` can host shoots of its own.

### The Russian-doll picture

```
Virtual garden g-qa-de-1
├── Shoot         mgmt-qa-de-1   spec.seedName = rt-qa-de-1
├── ManagedSeed   mgmt-qa-de-1   references the shoot above
├── Seed          mgmt-qa-de-1   generated from the ManagedSeed
└── Shoots on garden-compute (cc-*, lh-*)  spec.seedName = mgmt-qa-de-1
```

So `mgmt-qa-de-1` is simultaneously:

- **A `Shoot`** (as far as Gardener is concerned, it's just another
  cluster it manages).
- **A `Seed`** (from the moment its gardenlet registers, it hosts
  the control planes of *other* shoots).

The shoot's own control plane lives inside `rt-qa-de-1` (namespace
`shoot--garden--mgmt-qa-de-1`). But the workloads
`mgmt-qa-de-1` hosts as a seed (the KVM shoots, the Lighthouse) live
inside `mgmt-qa-de-1` itself.

### Why do it this way?

- **Uniform lifecycle.** Because the seed is just a shoot, you get
  the same install/upgrade/scale/backup pipeline you use for any
  other cluster. No special seed-only tooling.
- **Multiplication.** Once one seed exists, it can host any number
  of other clusters — including more ManagedSeeds. In principle you
  could have layers of nesting.
- **Provisioning automation.** Adding a new region becomes: apply
  one Shoot + one ManagedSeed. No manual "install a Kubernetes
  cluster somewhere and then wire it in" step.

### The file that declares this in our repo

In `sapcc/helm-charts`, the ManagedSeeds are templated by:

- **`system/cc-shoots-mgmt/templates/mgmt-shoot.yaml`** — creates the
  underlying `Shoot`.
- **`system/cc-shoots-mgmt/templates/managedseed.yaml`** — creates
  the `ManagedSeed` that promotes it to a seed. The seed's settings
  (`.spec.gardenlet.config.seedConfig.spec.settings.*`) live here.
- Values come from `.Values.mgmtShoots` — one entry per landscape.

### Verified with kubectl

```bash
u8s --context g-qa-de-1 kubectl -n garden get shoot mgmt-qa-de-1 \
  -o jsonpath='{.spec.seedName}'
# → rt-qa-de-1        (the shoot side — hosted on rt-qa-de-1)

u8s --context g-qa-de-1 kubectl -n garden get managedseed mgmt-qa-de-1
# → NAME=mgmt-qa-de-1  STATUS=Registered  SHOOT=mgmt-qa-de-1

u8s --context g-qa-de-1 kubectl get seed mgmt-qa-de-1
# → NAME=mgmt-qa-de-1  PROVIDER=ironcore-metal  REGION=qa-de-1  READY
```

---

## 7. Where every resource lives — the map <a id="7-resource-map"></a>

The single most useful table when reasoning about this system.

| Resource                       | Kubernetes scope   | Which cluster?             | Which namespace?                    | Purpose                                                        |
| ------------------------------ | ------------------ | -------------------------- | ----------------------------------- | -------------------------------------------------------------- |
| **`Garden`**                   | cluster-scoped     | Runtime cluster            | —                                   | Declares the virtual garden setup.                             |
| **`Project`**                  | cluster-scoped     | Virtual garden             | —                                   | A tenant group. Owns one `garden-<project>` namespace.         |
| **`Shoot`**                    | namespaced         | Virtual garden             | `garden-<project>` or `garden`      | Declaration of a customer cluster.                             |
| **`ManagedSeed`**              | namespaced         | Virtual garden             | `garden`                            | "This shoot should also be a seed."                            |
| **`Seed`**                     | cluster-scoped     | Virtual garden             | —                                   | A seed's spec/settings. Reconciled from ManagedSeed.           |
| **`ControllerRegistration`**   | cluster-scoped     | Virtual garden             | —                                   | Declares "this extension exists."                              |
| **`ControllerDeployment`**     | cluster-scoped     | Virtual garden             | —                                   | Points at the Helm chart or OCI image of an extension.         |
| **`ControllerInstallation`**   | namespaced         | Virtual garden             | `seed-<seed>`                       | "Install this extension on this seed." One per (extension, seed). |
| **`BackupBucket`**             | cluster-scoped     | Virtual garden             | —                                   | Cloud bucket used to store etcd backups.                       |
| **`BackupEntry`**              | cluster-scoped     | Virtual garden             | —                                   | Per-shoot backup pointer inside a BackupBucket.                |
| **Shoot CP namespace**         | namespace          | **Seed** cluster           | `shoot--<project>--<shoot>`         | Where the shoot's actual CP pods run.                          |
| **gardenlet**                  | Deployment         | **Seed** cluster           | `garden`                            | The reconciler that does all the work on the seed.             |
| **Extension controllers**      | Deployments        | **Seed** cluster           | `extension-<name>-<hash>`           | provider-openstack, provider-ironcore-metal, networking-…      |
| **`Cluster` extension CR**     | cluster-scoped     | **Seed** cluster           | —                                   | Snapshot of the Shoot for extension controllers to consume.    |
| **Worker VMs / bare metal**    | —                  | (outside k8s)              | —                                   | The shoot's actual worker nodes. Talk to the CP over the network. |

Two shortcuts to memorize:

- **Anything with "declared intent"** (Shoot, ManagedSeed, Seed,
  Project, ControllerInstallation) → **virtual garden**.
- **Anything that is a running workload of a shoot's CP** → **seed**.

If you catch yourself unsure "where does X live?", check whether X is
a declaration or a workload.

---

## 8. The controllers doing the work <a id="8-controllers"></a>

Gardener is a lot of controllers. Here are the ones you actually need
to know to reason about "who does what."

### On the runtime cluster (`rt-qa-de-1`)

| Component                              | What it does                                                                       |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| `gardener-operator`                    | Reconciles the `Garden` CR. Manages the virtual garden's pods and infrastructure. |
| `virtual-garden-kube-apiserver`        | The actual Kubernetes API server of the garden.                                    |
| `virtual-garden-etcd-{main,events}`    | Etcd for the garden.                                                               |
| `virtual-garden-kube-controller-manager` | Standard Kubernetes controllers for the garden.                                  |
| `gardener-apiserver`                   | Adds the `core.gardener.cloud`, `seedmanagement.gardener.cloud`, … APIs.           |
| `gardener-controller-manager`          | Cross-cutting Gardener controllers (Project, CloudProfile, quotas).               |
| `gardener-scheduler`                   | Decides which seed a Shoot is scheduled onto (sets `spec.seedName`).              |
| `gardener-admission-controller`        | Admission webhooks for the garden APIs.                                            |

Yes, the runtime cluster **also** runs a `gardenlet` in its `garden`
namespace — because it is *itself* registered as a Seed (see
`rt-qa-de-1` in the seed list).

### On each seed cluster (e.g. `mgmt-qa-de-1`)

| Component                     | What it does                                                                              |
| ----------------------------- | ----------------------------------------------------------------------------------------- |
| **`gardenlet`**               | THE agent. Watches Shoots with `spec.seedName == <this seed>`. Creates/updates their CPs. |
| `gardener-resource-manager`   | Enforces cross-cutting policies on shoot resources (e.g. zone pinning via node affinity). |
| `etcd-druid`                  | Operator for etcd StatefulSets used by shoot CPs.                                         |
| `dependency-watchdog`         | Restarts sad pods when their dependencies come back up.                                   |
| `extension-provider-<x>`      | Infrastructure/provider-specific logic (openstack, ironcore-metal, …).                    |
| `extension-networking-<x>`    | CNI-specific logic (calico, cilium).                                                       |
| `extension-os-<x>`            | OS-image-specific logic (garden-linux, flatcar).                                          |
| Istio ingress                 | Exposes each shoot's kube-apiserver externally.                                            |

### Inside each shoot CP namespace on the seed

| Component                        | What it does                                                                            |
| -------------------------------- | --------------------------------------------------------------------------------------- |
| `kube-apiserver-<shoot>`         | The API server of the shoot. Reachable from workers via Istio + DNS.                    |
| `etcd-main-0`, `etcd-events-0`   | The shoot's etcd.                                                                        |
| `kube-controller-manager-<shoot>`| Standard Kubernetes controllers for the shoot.                                          |
| `kube-scheduler-<shoot>`         | Standard scheduler.                                                                      |
| `machine-controller-manager`     | Manages the shoot's actual worker VMs / bare metal via the extension provider.          |
| `gardener-resource-manager`      | A copy inside the shoot CP namespace, enforcing shoot-cluster-level policies.           |

Every one of these is just a pod on the seed. If you `kubectl get
pods -n shoot--compute--cc-b0-qa-de-1` on the seed, you'll see them
all.

---

## 9. `qa-de-1` walkthrough — a fully worked example <a id="9-qa-de-1-walkthrough"></a>

Enough theory. Here is the actual topology.

### 9.1 The clusters

| Cluster       | Role                                     | Provider          | Zones                     |
| ------------- | ---------------------------------------- | ----------------- | ------------------------- |
| `rt-qa-de-1`  | Runtime + hosts virtual garden + Seed    | openstack         | `qa-de-1a`, `qa-de-1b`   |
| `mgmt-qa-de-1`| ManagedSeed (metal). Hosts KVM CPs.      | ironcore-metal    | `qa-de-1a`, `qa-de-1b`   |

`g-qa-de-1` is not a real cluster; it's the DNS name of the virtual
garden hosted on `rt-qa-de-1`.

### 9.2 The Seed CRs (in the virtual garden)

```bash
u8s --context g-qa-de-1 kubectl get seed
# NAME           STATUS   PROVIDER          REGION    …
# mgmt-qa-de-1   Ready    ironcore-metal    qa-de-1
# rt-qa-de-1     Ready    openstack         qa-de-1
```

### 9.3 The ManagedSeed CR

```bash
u8s --context g-qa-de-1 kubectl -n garden get managedseed
# NAMESPACE   NAME           STATUS       SHOOT           AGE
# garden      mgmt-qa-de-1   Registered   mgmt-qa-de-1    268d
```

Note: only `mgmt-qa-de-1` is a ManagedSeed. `rt-qa-de-1` is an
*unmanaged seed* — it was installed by hand as the runtime cluster
and registered separately.

### 9.4 The Shoots and their seed placement

Grouped by which seed hosts their CP:

```
Seed rt-qa-de-1  (hosts CPs on openstack)
├── Shoot mgmt-qa-de-1   ← this shoot BECOMES mgmt-qa-de-1 the seed
├── Shoot m-qa-de-1      ← openstack manager, workerless
├── Shoot nw-a-qa-de-8   ← wire-api, workerless
├── Shoot nw-t-ora-1
├── Shoot nw-t-qa-de-1
└── Shoot nw-t-qa-de-8

Seed mgmt-qa-de-1  (hosts CPs on bare metal)
├── Shoot cc-b0-qa-de-1  ← KVM compute, workers in qa-de-1b
├── Shoot cc-b1-qa-de-1  ← KVM compute, workers in qa-de-1b
├── Shoot cc-d0-qa-de-1  ← KVM compute, workers in qa-de-1d
└── Shoot lh-b-qa-de-1   ← Lighthouse, workerless, targets qa-de-1b
```

Every one of these lines is a `Shoot` resource in the virtual garden.
The seed assignment is `spec.seedName` on each. Verify:

```bash
u8s --context g-qa-de-1 kubectl get shoot -A \
  -o jsonpath='{range .items[*]}{.metadata.namespace}{"\t"}{.metadata.name}{"\t"}{.spec.seedName}{"\n"}{end}'
```

### 9.5 What each seed physically hosts

Look inside `mgmt-qa-de-1`:

```bash
u8s --context mgmt-qa-de-1 kubectl get ns | grep '^shoot--'
# shoot--compute--cc-b0-qa-de-1   Active   77d
# shoot--compute--cc-b1-qa-de-1   Active   21d
# shoot--compute--cc-d0-qa-de-1   Active   64d
# shoot--compute--lh-b-qa-de-1    Active   100d
```

Each of these namespaces contains ~30-50 pods that together implement
one shoot's control plane. That is where the "hosting" actually
happens.

### 9.6 The virtual garden's pods on `rt-qa-de-1`

```bash
u8s --context rt-qa-de-1 kubectl -n garden get pods | grep -E 'virtual-garden|gardener-'
# virtual-garden-kube-apiserver-…
# virtual-garden-etcd-main-0
# virtual-garden-etcd-events-0
# virtual-garden-kube-controller-manager-…
# gardener-apiserver-…
# gardener-controller-manager-…
# gardener-scheduler-…
# gardener-admission-controller-…
# gardener-operator-…
```

These pods together are what you connect to when you use context
`g-qa-de-1`.

---

## 10. Common misconceptions <a id="10-misconceptions"></a>

Corrections for things engineers often get wrong when they first
learn this system.

**"The garden is a big physical cluster."**
Not on our landscapes. It's a set of pods running inside the runtime
cluster. See §5.

**"The seed is a heavyweight thing you install separately."**
Sometimes yes (`rt-qa-de-1` is an unmanaged seed installed by hand),
but usually no. Most of our seeds are `ManagedSeed`s — they *are*
shoots that Gardener created and promoted. See §6.

**"The shoot's control plane runs in the shoot cluster."**
No. It runs in the *seed* cluster's `shoot--<project>--<shoot>`
namespace. The shoot cluster contains only worker nodes. See §4.

**"The garden namespace on my seed contains my shoot's CP."**
No. The `garden` namespace on a seed contains gardenlet, etcd-druid,
extension controllers, etc. — the seed's own operational
infrastructure. Shoot CPs live in `shoot--*` namespaces on the seed.

**"There's only one gardenlet in the whole landscape."**
No. Every seed cluster runs its own gardenlet (or a pair, for HA).
`mgmt-qa-de-1` has one, `rt-qa-de-1` has one.

**"Changing the Seed CR is how I change a ManagedSeed's settings."**
No. `Seed` is generated. Edit the `ManagedSeed`, or better, the Helm
chart that renders the `ManagedSeed`. Direct `Seed` edits are
overwritten on the next reconcile. See §6.

**"`kubectl get shoots` on my seed shows the shoots it hosts."**
No. `Shoot` resources live only in the virtual garden. On a seed
you'd instead look at `namespace/shoot--…` to see which shoots have
CPs there. To list shoots by seed, query the virtual garden with
`spec.seedName == <seed>`.

**"Deleting a shoot deletes its worker nodes only."**
No. Deleting a `Shoot` triggers gardenlet to delete the entire
`shoot--<project>--<shoot>` namespace on the seed, plus the worker
nodes. Its etcd backup remains in the BackupBucket until GC.

**"The virtual garden has its own nodes."**
No, that's the whole point of "virtual." Its pods borrow the runtime
cluster's nodes.

**"Every shoot has its own etcd cluster."**
Yes — one etcd-main and one etcd-events StatefulSet, running as pods
in the shoot's CP namespace on the seed. Not shared across shoots.

**"`management cluster` and `mgmt-*` are Gardener terms."**
No. Gardener does not use "management cluster." The `mgmt-*` name is
SAP convention for the seed that hosts KVM/metal shoots. In Gardener
docs the equivalent is just "a seed."

---

## 11. Glossary <a id="11-glossary"></a>

| Term                              | Definition                                                                                                                            |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Bootstrap kubeconfig**          | The initial kubeconfig gardenlet uses to first authenticate to the garden and obtain its long-lived credentials.                     |
| **Cluster resource** (extension)  | A `Cluster` CR on the seed that copies the Shoot spec so extension controllers can consume it without hitting the garden.            |
| **Control plane (CP)**            | The kube-apiserver + etcd + KCM + scheduler pods of a shoot. On our landscapes these are pods on a seed.                             |
| **ControllerDeployment**          | Cluster-scoped resource that points to a Helm chart / OCI image implementing an extension.                                            |
| **ControllerInstallation**        | Namespaced resource in `seed-<seed>` saying "install this extension on this seed."                                                    |
| **ControllerRegistration**        | Cluster-scoped resource announcing that an extension exists and what it handles.                                                      |
| **Extension**                     | A pluggable component that extends Gardener: providers (aws, openstack, ironcore-metal), OS images, networking, DNS, auditing, etc.  |
| **Failure tolerance type**        | `node` or `zone`. Determines whether a shoot's CP is HA against a node loss or an AZ loss.                                            |
| **Garden**                        | The logical top of the hierarchy. The Kubernetes API that stores all Gardener declarations. On qa-de-1 it's a virtual garden.        |
| **Garden namespace**              | A namespace called `garden` — exists on the garden (root of Gardener declarations) *and* on each seed (gardenlet's home). Different! |
| **gardener-operator**             | Controller that reconciles the `Garden` CR into the pods that make up a virtual garden.                                              |
| **gardenlet**                     | Per-seed agent that reconciles shoots assigned to its seed. The workhorse.                                                            |
| **Kubelet**                       | The Kubernetes node agent. Runs on every shoot worker node. Talks to that shoot's kube-apiserver on the seed.                       |
| **Lighthouse**                    | An SAP-specific workerless shoot that provides a per-AZ API endpoint for the KVM compute shoots in that AZ.                          |
| **ManagedSeed**                   | Resource that says "take this Shoot and also register it as a Seed." Runs a gardenlet inside the shoot.                              |
| **Managed seed**                  | A seed that was created via `ManagedSeed`. Its lifecycle is a shoot's lifecycle.                                                      |
| **Project**                       | Tenant grouping in Gardener. Owns one `garden-<project>` namespace where its Shoots live.                                            |
| **Project namespace**             | `garden-<project>` on the garden cluster. Holds `Shoot` declarations. **Not** the same as a CP namespace.                            |
| **Runtime cluster**               | The plain Kubernetes cluster that hosts `gardener-operator` and the virtual garden. On qa-de-1 that's `rt-qa-de-1`.                  |
| **Seed**                          | A Kubernetes cluster that hosts shoot control planes as pods. Registered in the garden via a `Seed` CR.                              |
| **Seed namespace**                | `seed-<seed>` on the garden cluster. Holds bookkeeping (`ControllerInstallation`s, seed-scoped secrets) for that seed.                |
| **Shoot**                         | The end-user Kubernetes cluster.                                                                                                     |
| **Shoot CP namespace**            | `shoot--<project>--<shoot>` on a seed cluster. Holds the shoot's control-plane pods.                                                 |
| **Unmanaged seed**                | A seed cluster that exists independently of any Shoot (e.g. installed by hand). Registered via `Seed` + gardenlet, no `ManagedSeed`. |
| **Virtual garden**                | A garden that runs as pods inside a runtime cluster. Same API as a "real" garden.                                                    |
| **Workerless shoot**              | A shoot with no worker pools. Only the control plane exists. Used for coordinator APIs like Lighthouse.                              |

---

## 12. References <a id="12-references"></a>

- Upstream Gardener architecture:
  - [Concept: Gardener architecture](https://github.com/gardener/gardener/blob/master/docs/concepts/architecture.md)
  - [Concept: gardenlet](https://github.com/gardener/gardener/blob/master/docs/concepts/gardenlet.md)
  - [Concept: gardener-operator](https://github.com/gardener/gardener/blob/master/docs/concepts/operator.md)
  - [Concept: ManagedSeed](https://github.com/gardener/gardener/blob/master/docs/operations/managed_seed.md)
- Upstream API references:
  - [`Garden` CRD](https://github.com/gardener/gardener/blob/master/docs/api-reference/operator.md)
  - [`Shoot`, `Seed`, `Project` CRDs](https://github.com/gardener/gardener/blob/master/docs/api-reference/core.md)
  - [`ManagedSeed` CRD](https://github.com/gardener/gardener/blob/master/docs/api-reference/seedmanagement.md)
- In this repo:
  - `system/cc-shoots-mgmt/templates/managedseed.yaml` — where our
    `mgmt-*` seeds are declared as ManagedSeeds.
  - `system/cc-shoots-mgmt/templates/mgmt-shoot.yaml` — where the
    underlying shoots for those ManagedSeeds are declared.
  - `docs/gardener-shoot-cp-az-placement.md` — how this architecture
    interacts with per-AZ control-plane placement (issue #943).
