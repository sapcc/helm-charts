# helm-charts Project Agent Instructions

## DDO Operand Chart Conventions

This repo contains the sapcc fleet of dual-deployment-operator (DDO) operand charts
under `system/*-ddo/`. Five charts are live: metal-operator-remote-ddo,
boot-operator-remote-ddo, argora-operator-remote-ddo, ipam-capi-remote-ddo, disco-ddo.

---

## LESSON: Vault refs must NOT appear in DualDeploymentOperator CR values

**The mistake (disco-ddo, Nov 2026):** openstack credentials were placed directly in
the `DualDeploymentOperator` CR `values:` block in kube-secrets:

```yaml
# WRONG — will fail CI
disco-remote:
  values:
    openstack:
      password: vault+kvv2:///secrets/qa-de-1/disco/keystone-user/service/password
```

**Why it fails:** The kube-secrets admin-k3s CI pipeline runs:
```
helm template | secrets-injector-validator -kinds=OpenstackSeed
```
This validator only allows vault refs in `Secret` and `OpenstackSeed` kinds.
`DualDeploymentOperator` is NOT in the allowed list → CI gate fails.

**The correct pattern (from metal-operator-remote-ddo, argora):**
Put credentials in the **operand chart's `values.yaml`** as `{{ resolve \`vault+kvv2://...\` }}`
directives with `${REGION}` tokens:

```yaml
# system/disco-ddo/values.yaml — CORRECT
openstack:
  password: "{{ resolve `vault+kvv2:///secrets/${REGION}/disco/keystone-user/service/password` }}"
```

The chart template substitutes `${REGION}` from `.Values.global.region` via `replace "${REGION}" $region`.
The vault ref lands in a `Secret` kind when the chart renders (the `disco-config` Secret) → allowed.
The DDO CR in kube-secrets carries **no vault refs** — only non-sensitive overrides.

**RULE:** When authoring a DDO operand chart that needs secrets:
1. Put vault refs in the chart's `values.yaml` using `{{ resolve \`...\` }}` + `${REGION}` tokens
2. The chart template resolves `${REGION}` → `.Values.global.region` via `replace`
3. Credentials render into a `Secret` kind in the chart templates
4. The kube-secrets CR `values:` block contains ONLY non-sensitive values (`global.region`, `record`, `apiServerHost`, etc.)

---

## DDO Chart Checklist (building a new -ddo chart)

- Chart version: clean semver, NO `_sha` suffix (→ "improper constraint" SeedRenderFailed)
- `values.yaml` MUST NOT contain `mode:` key (CI gate `ci/no-mode-default.sh` fails)
- Every resource wrapped in `{{- if eq .Values.mode "seed" }}` or `{{- if eq .Values.mode "shoot" }}`
- CRDs go in `templates/` (mode-guarded), NOT `crds/` dir (unconditional, cannot be mode-guarded)
- Every disco-authored resource carries `dual-deployment-operator.cc.sap/origin: additions` annotation
- Seed render must include a seed ServiceAccount (Deployment references it; fleet pattern: seed SA in `.Release.Namespace`)
- Vault refs in `values.yaml` use backtick `{{ resolve \`vault+kvv2://...\` }}` syntax
- `${REGION}` in values is substituted by template via `replace "${REGION}" .Values.global.region`
- kube-secrets CR: NO vault refs in `values:` block (validator constraint above)

---

## kube-secrets publish-before-merge

DDO operand chart versions referenced in a kube-secrets `DualDeploymentOperator` CR
MUST be published to `oci://keppel.eu-de-1.cloud.sap/ccloud-helm` BEFORE the kube-secrets PR merges.
Verify: `helm show chart oci://keppel.eu-de-1.cloud.sap/ccloud-helm/<chart-name> --version <version>`
Merging before publish → DDO cannot pull the chart → `SeedRenderFailed`.
