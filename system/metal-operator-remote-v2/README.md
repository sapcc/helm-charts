# metal-operator-remote-v2 — Operator-Native Chart Redesign

> **Status: IMPLEMENTED.** Chart files are present. The design notes below are retained
> for context. See `examples/` for an annotated `DualDeploymentOperator` CR.

---

## Subchart vendoring model

This chart declares the upstream `metal-operator` chart as an OCI dependency in
`Chart.yaml` and commits only `Chart.lock` — **not** `charts/*.tgz`.

```
Chart.yaml     ← declares dep: oci://ghcr.io/ironcore-dev/charts/metal-operator 0.6.2-crds
Chart.lock     ← committed — locks the digest
charts/*.tgz   ← gitignored — NOT committed
```

The publish workflow (`helm dependency update → helm package → helm push`) bundles
the subchart tarball into the published chart artifact. The operator pulls the
**complete artifact** from the OCI registry; it does not resolve dependencies at
apply time.

See the operator documentation:
[`docs/subchart-dependency-resolution.md`](https://github.com/SAP-cloud-infrastructure/dual-deployment-operator/blob/main/docs/subchart-dependency-resolution.md)

> **DO NOT** commit `charts/*.tgz` — it is gitignored by the root `.gitignore`.

---

## 1. Why this redesign exists

The current `system/metal-operator-remote` chart is a **pre-render-and-commit** wrapper:

- `Chart.yaml` declares the upstream `metal-operator` chart as a disabled dependency.
- A `make build-metal-operator-remote` step renders the upstream chart and **commits the
  result** into `managedresources/crds-and-rbac.yaml` (~5,500 lines).
- `templates/managedresource.yaml` wraps every committed document in a Gardener
  `resources.gardener.cloud/v1alpha1 ManagedResource` + `Secret` pair, so the
  Gardener Resource Manager (GRM) applies the objects to the shoot.
- Per-cluster/secret values are supplied at deploy time by the `cc/kube-secrets` Helm
  overlay (`values/helm/<landscape>/<region>/<cluster>/metal-operator-remote.yaml`),
  including `vault+kvv2` resolves for BMC credentials.

**The `dual-deployment-operator` removes the reason for all of that machinery.** The
operator pulls one chart, renders it **twice** (once with `mode=seed`, once with
`mode=shoot`), applies typed transformations to each render, and **applies each render
directly** to its target cluster via Server-Side Apply — the seed via the operator's own
ServiceAccount, the shoot via a Gardener token-requestor kubeconfig. There is no
pre-render, no committed YAML, and no GRM `ManagedResource` indirection.

So `-v2` collapses to a **thin wrapper**: the upstream chart as a subchart plus a small set
of sapcc addition templates, all **mode-guarded**. The design doc for the operator
(`docs/design.md §4.1`, "Before/After") already sketches this shape and estimates a ~94%
reduction in chart size.

---

## 2. The operator contract this chart MUST satisfy

A chart is "operator-native" when it obeys the following contract (source:
`dual-deployment-operator` `docs/design.md`, `internal/source/helm.go`,
`internal/deliver/`, `internal/manifest/`):

1. **Rendered twice.** The operator renders the chart once per mode and injects
   `.Values.mode` = `"seed"` or `"shoot"`.
   - The chart **must NOT set `.Values.mode` itself** — the operator rejects a render
     whose user values contain `mode` (`internal/source/helm.go`:
     `"'mode' is operator-controlled and must not be set in values"`).
   - Common values plus per-mode values come from the CR
     (`spec.source.helm.values`, `spec.source.helm.seedValues`,
     `spec.source.helm.shootValues`).

2. **Mode gates which objects each render emits.** Every template that belongs to only one
   cluster must be guarded, e.g.:
   ```yaml
   {{- if eq .Values.mode "seed" }}
   # ... seed-only object ...
   {{- end }}
   ```
   Routing to seed vs shoot is **implicit from which render emitted the object** — there is
   no destination field on a manifest.

3. **Origin tagging for transforms.** The operator tags every rendered object with
   `dual-deployment-operator.cc.sap/origin: upstream` by default. Templates the sapcc team
   authors should stamp `dual-deployment-operator.cc.sap/origin: additions` (via
   `_helpers.tpl`). This only lets transformations target `origin: upstream` vs
   `additions` (e.g. `patch: {target: {origin: upstream}}`, `filterKinds: {source: upstream}`);
   it does **not** affect seed/shoot routing.

4. **Delivery is kind-agnostic.** `internal/deliver/applier.go` applies any kind via SSA
   with `ForceOwnership`. Deployment, Service, Ingress, NetworkPolicy, Secret, ConfigMap,
   Namespace, RBAC, CRDs, and WebhookConfigurations are all deliverable. **No object in the
   current chart is un-deliverable by the operator.** The only real question is *where each
   value comes from* (see §5).

5. **Webhook caBundle is not the chart's job.** On apply the operator strips `.caBundle`
   from webhook configs and CRD conversion configs (`internal/deliver/cabundle.go`). The
   `webhook-injector` sidecar, running in target-patch mode on the shoot, patches
   `.caBundle` in place on labeled objects. The chart emits the WebhookConfiguration with
   `caBundle` unset and the injector's label; the operator owns every other field.

6. **The operator does not:** create the shoot namespace for itself, bootstrap its own
   shoot RBAC (a minimal GRM-seeded ServiceAccount + apply ClusterRole must pre-exist),
   generate/rotate TLS certs, or manage its own Deployment. These stay outside the chart.

---

## 3. Target chart structure

```
system/metal-operator-remote-v2/
├── Chart.yaml            # dep: metal-operator (subchart), owner-info optional
├── Chart.lock
├── values.yaml           # subchart all-disabled by default; sapcc defaults
└── templates/
    ├── _helpers.tpl               # dual.seed/dual.shoot guards; stamps origin: additions
    ├── controller-manager.yaml    # mode=seed
    ├── webhook-injector-rbac.yaml # mode=shoot (RBAC/SA for the injector)
    ├── webhook-config.yaml        # mode=seed  (ConfigMap consumed by injector)
    ├── webhooks.yaml -> template   # mode=shoot (ValidatingWebhookConfiguration, caBundle unset)
    ├── metal-registry-service.yaml# mode=seed
    ├── ingress.yaml               # mode=seed
    ├── networkpolicy.yaml         # mode=seed
    ├── macdb.yaml                 # mode=seed  (Secret; SEE §5 — value source open)
    ├── remote-kubeconfig-configmap.yaml   # mode=seed
    ├── remote-kubeconfig.yaml     # mode=seed  (token-requestor Secret)
    ├── rotate-kubeconfig.yaml     # mode=seed  (token-rotate token-requestor Secret)
    ├── token-rotate-rbac.yaml     # mode=shoot (SA/Role/RB/CR/CRB)
    ├── oidc-ias-rbac.yaml         # mode=shoot (region-gated ClusterRoleBindings + viewer roles)
    ├── dns-records-rbac.yaml      # mode=shoot (ClusterRole + binding)
    ├── dns-record-template.yaml   # mode=seed  (ConfigMap, when enabled)
    └── namespace.yaml             # mode=shoot (metal-servers Namespace) — see §2.6 caveat
```

### What is DELETED versus today's `metal-operator-remote`

| Deleted | Replaced by |
|---|---|
| `managedresources/crds-and-rbac.yaml` (~5,500 pre-rendered lines) | operator renders the upstream subchart live (`crd.enable`/`rbac.enable`/`webhook.enable` per mode) |
| `managedresources/rbac.yaml`, `managedresources/namespace.yaml` | normal mode-guarded templates carrying `origin: additions` |
| `templates/managedresource.yaml` (ManagedResource + Secret generator) | direct SSA apply by the operator — **no GRM indirection** |
| `values-managed-resources.yaml`, `values-overrides.yaml` | CR `seedValues` / `shootValues` |
| `make build-metal-operator-remote` (auto-generates the `controllerManager` block) | **no pre-render step at all** |
| `Chart.lock` `charts/*.tgz` cached upstream tarball logic tied to the make step | subchart pulled by the operator's chart loader at the pinned dependency version |

### What SURVIVES as thin templates (mode-guarded, `origin: additions`)

- **seed render (`mode=seed`)** — the things that run *in the seed* control-plane namespace:
  controller-manager Deployment (± webhook-injector initContainer), metal-registry Service,
  Ingress, NetworkPolicies, macdb Secret, remote-kubeconfig ConfigMap, the two
  token-requestor Secrets (`metal-operator-remote-kubeconfig`, `metal-token-rotate-kubeconfig`),
  webhook-config ConfigMap, dns-record-template ConfigMap.
- **shoot render (`mode=shoot`)** — the operator's domain objects served in the virtual
  cluster: upstream CRDs + RBAC + webhooks (from the subchart), plus sapcc additions
  (webhook-injector RBAC/SA, token-rotate RBAC/SA, oidc-ias ClusterRoleBindings,
  metal-api-viewer ClusterRole, dns-records ClusterRole), and the ValidatingWebhookConfiguration
  (caBundle unset, injector label present).

---

## 4. Mode-gating convention — PICK ONE (open decision)

The operator design doc shows **two** ways to gate the upstream subchart and additions by
mode, and the chart must standardise on **one**:

- **(A) Chart-side guards.** `_helpers.tpl` defines `dual.seed`/`dual.shoot`; every template
  wraps its body in `{{- if eq .Values.mode "seed" }}`. The subchart is enabled/disabled by
  mapping `.Values.mode` onto subchart `*.enable` flags inside `values.yaml` /
  a `templates` shim.
- **(B) CR-side values.** The CR carries `seedValues`/`shootValues` that set the subchart
  `*.enable` flags per mode (this is what today's operator test fixtures do:
  `seedValues: {controllerManager: {enable: true}, rbac: {enable: false}, ...}` and the
  inverse for `shootValues`). Chart additions still need `{{ if eq .Values.mode ... }}`
  guards because CR values cannot gate a template's presence.

**Recommendation:** use **(A) chart-side `mode` guards for the chart's own addition
templates**, and **(B) CR `seedValues`/`shootValues` for the upstream subchart enable
flags** — because the subchart's flags are its published API and the chart's additions are
ours to gate. Document the chosen convention in `values.yaml` comments so the CR author and
the chart stay in sync.

---

## 5. The one real feasibility gap: deploy-time / vault / per-cluster values

This is the pivot of the whole redesign and the one thing that is **not** a trivial
template move.

Today `cc/kube-secrets` feeds the chart a **per-cluster Helm values overlay at deploy time**,
including `vault+kvv2` secret resolution. Concretely, the overlay supplies:

| Value | Used by | Today's source |
|---|---|---|
| `macdb.macPrefixes[].defaultCredentials` (BMC user/pass) | `macdb` Secret | `vault+kvv2:///secrets/<region>/ironic/ipmi-user/...` in the overlay |
| `remote.ca` | remote/rotate kubeconfig Secrets | overlay (base64 CA) |
| `controllerManager.manager.env.KUBERNETES_SERVICE_HOST` | Deployment + remote-kubeconfig | overlay (per shoot apiserver URL) |
| `controllerManager.manager.args` (`--registry-url`, `--manager-namespace`, probe images, `--enforce-*`) | Deployment | overlay |
| `global.region` | region-gated oidc-ias RBAC (`contains "qa-de-"`) | overlay |
| `global.clusterType`, `global.tld` | Ingress host | overlay |
| `dnsRecordTemplate.enabled`, `dnsRecordTemplate.zone` | dns-record-template + Deployment arg | overlay |
| `virtualGardenLBIP` | NetworkPolicy egress | overlay |

**The operator render has no equivalent of that overlay-plus-vault step.** The operator
pulls the chart at a ref and renders it with values that come from the `DualDeploymentOperator`
CR (`spec.source.helm.values/seedValues/shootValues`) — there is no deploy-time Helm overlay
and no vault resolution in the operator path.

Therefore the redesign must decide, **per value**, one of:

1. **Move into CR values** — fine for non-secret, per-cluster config (`global.region`,
   `global.clusterType`, `global.tld`, `KUBERNETES_SERVICE_HOST`, `--registry-url`,
   `--manager-namespace`, `dnsRecordTemplate.zone`, `virtualGardenLBIP`, images/args). The
   CR is per-shoot already (`metadata.namespace: shoot--cp--m-<region>`), so per-cluster CR
   values are natural. These can live in the CR that `cc/kube-secrets` (or its successor)
   templates per cluster.
2. **Reference a Secret the chart consumes** — required for genuine secrets that must NOT
   sit in a git-committed CR:
   - **`macdb` BMC credentials** — must come from a Secret resolved at runtime, not from CR
     values. Options: the chart mounts an existing `macdb` Secret provisioned separately
     (kube-secrets/vault continues to own *only* this Secret), or the operator gains a
     Secret-reference value path. **This is the hard sub-decision.**
   - **`remote.ca`** — is the shoot CA bundle; it is already injected by Gardener via the
     token-requestor annotation `serviceaccount.resources.gardener.cloud/inject-ca-bundle: "true"`
     on the kubeconfig Secret, so `remote.ca` may become unnecessary in `-v2` if the chart
     relies on the injected bundle instead of templating the CA into a kubeconfig.

**Feasibility conclusion:** everything is deliverable and templatable; the redesign is
on-architecture. The blocking design decision is **how the small set of runtime secrets
(chiefly `macdb` BMC credentials) reaches the render**, because the operator has no
vault/overlay step. Resolve that first; the rest is mechanical template work.

---

## 6. Simplifications this unlocks

Because `-v2` is a **greenfield chart that defines its own truth** (it no longer has to match
a committed pre-render), several accidental problems from the equivalence work disappear:

- **No `fullnameOverride` gymnastics.** The chart owns its object names directly.
- **Leader-election kind divergences vanish.** Today's fixture records Role↔ClusterRole and
  RoleBinding↔ClusterRoleBinding mismatches between the wrapper's committed pre-render and a
  clean upstream render. In `-v2` the clean upstream render *is* the truth — nothing to
  reconcile.
- **`owner-info` subchart** can be dropped unless still wanted for chart provenance.
- **No `ManagedResource` naming scheme** (`mr-<kind>-<name>`) and no per-object wrapper
  Secrets.

---

## 7. Handoff checklist for the implementing session (in this repo)

1. **Decide the values-relocation model (§5)** — especially the `macdb` secret path. This
   gates everything.
2. **Pick the mode-gating convention (§4)** and document it in `values.yaml`.
3. Author `Chart.yaml` with the `metal-operator` subchart dependency at the intended version
   (today the fixture uses `0.6.2-crds` from `oci://ghcr.io/ironcore-dev/charts`).
4. Write `values.yaml` with the subchart disabled by default and sapcc defaults; keep the
   `.Values.mode` guard contract (never set `mode` in the chart).
5. Port each surviving template from `system/metal-operator-remote` (§3), adding
   `{{ if eq .Values.mode ... }}` guards and the `origin: additions` annotation via
   `_helpers.tpl`.
6. Delete all `managedresources/*`, `templates/managedresource.yaml`, `values-overrides.yaml`,
   `values-managed-resources.yaml`, and the `make build-*` wiring for this chart.
7. Provide (or update) a `DualDeploymentOperator` CR that points `spec.source.helm` at this
   chart and supplies per-mode `seedValues`/`shootValues` plus the relocated per-cluster
   values. Validate against the operator's equivalence harness
   (`internal/equivalence`, `RUN_EQUIVALENCE=1`) if a golden comparison is still wanted, or
   drop the golden comparison since `-v2` defines new truth.
8. Coordinate the `cc/kube-secrets` change: the deploy pipeline shifts from templating a
   Helm values overlay to templating the operator CR (and, if chosen, the `macdb` Secret).

## 8. Source references

- Operator design & contract: `dual-deployment-operator` `docs/design.md` (esp. §1.1, §3.3,
  §3.5.2, §4.1, "Non-goals"), `docs/context.md`.
- Operator mechanics: `internal/source/helm.go` (two-render, `mode` injection),
  `internal/deliver/applier.go` (kind-agnostic SSA), `internal/deliver/cabundle.go`
  (caBundle stripping), `internal/manifest/{manifest,parse}.go` (origin tagging).
- Current chart being replaced: `system/metal-operator-remote/` (this repo).
- Deploy overlay + pipeline: `cc/kube-secrets`
  `pipelines/metal-operator-remote-runtime/pipeline.rb`,
  `values/helm/<landscape>/<region>/<cluster>/metal-operator-remote.yaml`.
