{{/*
Expand the name of the chart.
*/}}
{{- define "metal-settings.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "metal-settings.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "metal-settings.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "metal-settings.labels" -}}
helm.sh/chart: {{ include "metal-settings.chart" . }}
{{ include "metal-settings.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "metal-settings.selectorLabels" -}}
app.kubernetes.io/name: {{ include "metal-settings.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "metal-settings.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "metal-settings.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fail fast if CRDVersionControl.features.readinessGates.enabled=true but CRDVersionControl.apiVersions
still point at the plain metal-operator group ("metal.ironcore.dev/v1alpha1"), which has no
readinessGates/completionConditionType fields. The readiness-gate chain requires
metal-maintenance-operator's group-qualified apiVersions ("baseboard.metal.ironcore.dev/v1alpha1"
for BMCSettingsSet/BMCVersionSet, "system.metal.ironcore.dev/v1alpha1" for
BIOSSettingsSet/BIOSVersionSet).

Usage:
  {{- include "metal-settings.requireChainCapableAPI" . }}
*/}}
{{- define "metal-settings.requireChainCapableAPI" -}}
{{- $av := .Values.CRDVersionControl.apiVersions -}}
{{- if or (eq $av.bmcSettingsSet "metal.ironcore.dev/v1alpha1") (eq $av.bmcVersionSet "metal.ironcore.dev/v1alpha1") (eq $av.biosSettingsSet "metal.ironcore.dev/v1alpha1") (eq $av.biosVersionSet "metal.ironcore.dev/v1alpha1") -}}
{{- fail "metal-settings: CRDVersionControl.features.readinessGates.enabled=true requires CRDVersionControl.apiVersions.* to point at metal-maintenance-operator's groups (baseboard.metal.ironcore.dev/v1alpha1, system.metal.ironcore.dev/v1alpha1) — the metal-operator group (metal.ironcore.dev/v1alpha1) has no readinessGates/completionConditionType fields." -}}
{{- end -}}
{{- end -}}

{{/*
Fail fast if a top-level machines: key is still defined. The old machines:/model:/stepsOnly:
selection schema was replaced entirely by parameters:/rollouts.Types: (see values.yaml's
"Machine inventory" comment) - this catches a values file (chart default or cluster override)
still carrying the removed schema instead of silently ignoring it.

Usage:
  {{- include "metal-settings.rejectLegacyMachinesKey" . }}
*/}}
{{- define "metal-settings.rejectLegacyMachinesKey" -}}
{{- if .Values.machines -}}
{{- fail "metal-settings: top-level machines: is no longer supported - it was replaced by parameters:/rollouts.Types: (see values.yaml's \"Machine inventory\" comment). Migrate any machines.<vendor>.models.<name> entries (clusterTypes/model/stepsOnly) into parameters.<vendor>.<model> plus rollouts.Types overrides, then remove machines: entirely." -}}
{{- end -}}
{{- end -}}

{{/*
Single shared source of truth for every CRD kind this chart knows how to render - each of the 5
step templates (bios_settings.yaml/bmc_settings.yaml/bios_versions.yaml/bmc_versions.yaml/
firmware_updates.yaml) consults this ONE list for its "unknown kind" fail-fast check, instead of
each maintaining its own hardcoded enum. Adding support for a new kind only requires adding it
here (plus a CRDVersionControl.apiVersions.<kind> entry and a new step template file) - domain
derivation in metal-settings.computedChain is already generic (derived from each Workflow step's
own settingsKey/versionKey prefix, not from kind), so no other hardcoding is needed.

Output must be piped through `fromYamlArray` by the caller.

Usage:
  {{- $knownKinds := include "metal-settings.knownKinds" . | fromYamlArray }}
*/}}
{{- define "metal-settings.knownKinds" -}}
{{- toYaml (list "BMCSettingsSet" "BMCVersionSet" "BIOSVersionSet" "BIOSSettingsSet" "FirmwareUpdateSet") -}}
{{- end -}}

{{/*
Render server selector matchExpressions from a serverFilters object.
Expected input:
  dict "serverFilters" (dict "included" (list ...) "excluded" (list ...)) "labelKey" $.Values.labelKeys.serverName

"labelKey" is optional and defaults to "kubernetes.metal.cloud.sap/name" if not provided.

Returns empty string if both lists are empty.
*/}}
{{- define "metal-settings.serverMatchExpressions" -}}
{{- $serverFilters := .serverFilters -}}
{{- $labelKey := .labelKey | default "kubernetes.metal.cloud.sap/name" -}}
{{- if or $serverFilters.included $serverFilters.excluded -}}
matchExpressions:
{{- if $serverFilters.included }}
  - key: {{ $labelKey }}
    operator: In
    values:
{{- range $serverFilters.included }}
      - {{ . | quote }}
{{- end }}
{{- end }}
{{- if $serverFilters.excluded }}
  - key: {{ $labelKey }}
    operator: NotIn
    values:
{{- range $serverFilters.excluded }}
      - {{ . | quote }}
{{- end }}
{{- end }}
{{- end -}}
{{- end -}}

{{/*
Returns the EFFECTIVE top-level rollouts.Types map for this cluster: .Values.rollouts.Types if
that key is set and non-empty (the REAL, per-cluster override - set via the cluster's own
kube-secrets/foundation-deployment values file), else .Values.Defaultrollouts.Types (the chart's
default catalog - every cluster type this chart knows about). Its keys ARE the effective cluster
types for this cluster - no separate intersection step is needed, since a cluster override
replaces the whole catalog outright rather than merging with it (the chart itself never defines a
top-level rollouts: key, so there's nothing for an override to merge against).

Each clusterType's value is a LIST of rules: [{filter?: {include?: {models?, resources?, servers?},
exclude?: {models?, resources?, servers?}}, workflow}, ...] - see
metal-settings.matchingWorkflowsForClusterType below for how rules are matched against a model.

Output must be piped through `fromYaml` by the caller.

Usage:
  {{- $types := include "metal-settings.effectiveRolloutTypes" $root | fromYaml }}
*/}}
{{- define "metal-settings.effectiveRolloutTypes" -}}
{{- $override := .Values.rollouts | default dict -}}
{{- $overrideTypes := $override.Types | default dict -}}
{{- if gt (len $overrideTypes) 0 -}}
{{- toYaml $overrideTypes -}}
{{- else -}}
{{- toYaml .Values.Defaultrollouts.Types -}}
{{- end -}}
{{- end -}}

{{/*
Resolves which Workflow(s) apply for a given (model, clusterType): the effective top-level
rollouts.Types.<clusterType> (see metal-settings.effectiveRolloutTypes above) is a LIST of rules,
each shaped {filter?: {include?: {models?, resources?, servers?}, exclude?: {models?, resources?,
servers?}}, workflow}.

"include" gates whether a rule applies to this model/kind AT ALL - a rule matches a model when
include.models is empty/absent OR contains the model (include.resources is checked later, per step,
since kinds are only known once the Workflow is being walked). include.servers is NOT a match gate
(the chart never enumerates real server names) - it's just the base serverFilter.included stamped
onto every step's params.serverFilter.

"exclude" is evaluated per model+kind (see metal-settings.computedChain, which does this per step,
since kind isn't known at this level yet):
  - exclude.models/exclude.resources empty/absent = matches every model/kind (wildcard).
  - if BOTH match for a given (model, kind) and exclude has NO servers: that step is suppressed
    entirely for THAT model only (other models this rule also matches still render that kind).
  - if BOTH match AND exclude HAS servers: the step still renders, but exclude.servers is merged
    into that step's serverFilter.excluded (on top of include.servers), carving those servers out
    of this rule's resource while a separate, more specific rule covers them instead.
If exclude matches a model with NEITHER resources NOR servers set (a blanket, unscoped exclusion),
the rule doesn't match that model at all - handled right here, since it doesn't need per-step kind
knowledge (equivalent to today's full modelFilter.excluded).

ALL matching rules are returned (in list order) - not first-match-wins - so e.g. a broad rule with
exclude: {models: [X], resources: [Y], servers: [Z]} plus a second rule with
include: {models: [X], resources: [Y], servers: [Z]} correctly produce two independent resources
together covering every server of X without overlap (see values.yaml's "Machine inventory" comment
and README's UC12/UC13). Fails fast if NO rule matches (misconfigured include/exclude, or the
cluster type has no rules at all).

rollouts.Types is the ONLY place workflow/server routing is expressed - there is no separate
vendor/model-level override anymore (parameters: has no "rollouts" key at all); scoping a workflow
variant and/or a server subset to one model is done entirely via a rule's include/exclude, directly
in rollouts.Types.

Output must be piped through `fromYamlArray` by the caller (a YAML list of {workflow, include,
exclude}).

Usage:
  {{- $matchedRules := include "metal-settings.matchingWorkflowsForClusterType" (dict "model" $model "clusterType" $clusterType "root" $) | fromYamlArray }}
*/}}
{{- define "metal-settings.matchingWorkflowsForClusterType" -}}
{{- $model := .model -}}
{{- $clusterType := .clusterType -}}
{{- $root := .root -}}
{{- $effectiveTypes := include "metal-settings.effectiveRolloutTypes" $root | fromYaml -}}
{{- $rules := dig $clusterType list $effectiveTypes -}}
{{- $matched := list -}}
{{- range $rules -}}
{{- $filter := dig "filter" dict . -}}
{{- $include := dig "include" dict $filter -}}
{{- $includeModels := dig "models" list $include -}}
{{- $exclude := dig "exclude" nil $filter -}}
{{- $excludeModels := list -}}
{{- $excludeResources := list -}}
{{- $excludeServers := list -}}
{{- if $exclude -}}
{{- $excludeModels = dig "models" list $exclude -}}
{{- $excludeResources = dig "resources" list $exclude -}}
{{- $excludeServers = dig "servers" list $exclude -}}
{{- end -}}
{{- $includeMatch := or (eq (len $includeModels) 0) (has $model $includeModels) -}}
{{- $excludeModelMatch := and $exclude (or (eq (len $excludeModels) 0) (has $model $excludeModels)) -}}
{{- $excludeIsBlanket := and $excludeModelMatch (eq (len $excludeResources) 0) (eq (len $excludeServers) 0) -}}
{{- if and $includeMatch (not $excludeIsBlanket) -}}
{{- $matched = append $matched (dict "workflow" .workflow "include" $include "exclude" $exclude) -}}
{{- end -}}
{{- end -}}
{{- if eq (len $matched) 0 -}}
{{- fail (printf "metal-settings: no workflow resolves for model %q at cluster type %q - check rollouts.Types (cluster override/Defaultrollouts) rule list for this cluster type: either it has no rules, or every rule's include/exclude excludes this model" $model $clusterType) -}}
{{- end -}}
{{- toYaml $matched -}}
{{- end -}}

{{/*
Resolve a chain step's optional "enabled" field (default true when unset). Accepts either a
literal boolean, or a template string tied to another values field (e.g.
"{{ .Values.CRDVersionControl.features.readinessGates.enabled }}"), rendered via tpl against the
root context and parsed as a bool.

Usage:
  {{- if include "metal-settings.stepEnabled" (dict "step" $s "root" $) }}
*/}}
{{- define "metal-settings.stepEnabled" -}}
{{- $v := .step.enabled -}}
{{- $enabled := true -}}
{{- if kindIs "string" $v -}}
{{- $enabled = eq (trim (tpl $v .root)) "true" -}}
{{- else if kindIs "bool" $v -}}
{{- $enabled = $v -}}
{{- end -}}
{{- if $enabled -}}
true
{{- end -}}
{{- end -}}

{{/*
Computes the chain(s) for a parameters.<vendor>.<model> model at ONE specific cluster type:
ruleIndex -> stepName -> {kind, order, enabled, params} - the exact shape the step templates
consume, one inner map per Workflow matched by "metal-settings.matchingWorkflowsForClusterType"
(structure/field-map, a map keyed by step name - see below) + parameters.<vendor>.<model> (user
input) + CRDVersionControl.features.readinessGates.enabled (feature toggle - only affects whether
completionConditionType/readinessGates get computed at all).

rollouts.Types.<clusterType> is a LIST of rules, and ALL rules whose include/exclude match this
model are resolved independently (see matchingWorkflowsForClusterType) - this is what lets one
model have two genuinely different resources for the same cluster type (e.g. a broad rule's
exclude.servers carves a specific server out of a Workflow variant, a second, narrower rule's
include.servers covers just that server with a different Workflow variant - see README's UC13). The outer ruleIndex key (the matched workflow's position in the rule
list, 0-based) keeps each rule's computed steps independent - including completionConditionType/
readinessGates auto-gating, which restarts fresh per rule since each rule's Workflow has its own
ordered step sequence.

Each resolved Workflow is a MAP keyed by step name, each value a field map: {order, kind,
settingsKey?, versionKey?, paramsKey?, enabled?}. "order" is REQUIRED and explicit (map iteration
in Go templates is key-sorted by step NAME, not by this field, so it's re-sorted here the same way
the step templates already re-sort $chain's output). Exactly one of settingsKey/versionKey/
paramsKey must be set per step - it is a fully-qualified, self-describing relative path -
"<domain>.settings.<key>" / "<domain>.versions.<key>" / "<domain>.params.<key>" (e.g.
"bmc.settings.initialSettings", "bios.versions.defaultVersion", "firmware.params.defaultVersion") - and
<domain> (the FIRST path segment) is where the step's data is read from under
parameters.<vendor>.<model>; there is no kind->domain convention to keep in sync - the domain is
whatever the key's own first segment says it is, so a step's kind and its domain are independent
(any kind can read any domain, e.g. a future second FirmwareUpdateSet-kind step could read a
different domain than "firmware").
"<domain>.settings.<key>" resolves to a plain string shorthand for settingsFileName, or an object
{ settingsFileName|settingsContent, enabled? }, into params.settingsFileName/params.settingsContent.
This shape is specific to BIOS/BMC redfish-settings steps (BMCSettingsSet/BIOSSettingsSet).
"<domain>.versions.<key>" resolves to an object { version, imagePath|imageURI, enabled? } into
params.version/params.imagePath/params.imageURI. This shape is specific to version-rollout steps
(BMCVersionSet/BIOSVersionSet).
"<domain>.params.<key>" is the generic escape hatch for any other kind: its entire object (minus
the reserved "enabled"/"completionConditionTypeOverride"/"readinessGatesOverride" keys, which are
never interpreted from here - reserved only so stray data using those same field names, e.g.
copy-pasted from an old Workflow step definition, can't silently leak through into the rendered
resource's spec) is merged into params verbatim, unmodified - e.g. FirmwareUpdateSet's
"firmware.params.<key>" carries arbitrary fields like dellRepository/serverMaintenancePolicy/
progressDeadlineSeconds straight through to the rendered resource, with no kind-specific
extraction logic needed here. Adding a brand-new kind with a brand-new resource shape therefore
never requires touching this helper - only a new step template that renders whatever its own
params dict happens to contain.
domain is simply the key's own first path segment - there's no separate bmcSettingsInitial domain;
bmc-settings-initial and bmc-settings both read the "bmc" domain (via bmc.settings.<key>), just
different named "settings" variants (e.g. initialSettings vs defaultSettings).

completionConditionType/readinessGates are computed purely from each step's position in its rule's
resolved Workflow and whether the model has domain data for it.

A Settings-kind step (BMCSettingsSet/BIOSSettingsSet) with no matching settingsKey data for this
model (e.g. a firmware-only model with no bmc.settings/bios.settings at all) is simply omitted
from the result - no separate clusterTypes candidate list is needed to express "this model doesn't
render Settings resources": the data's absence is sufficient. The same applies to paramsKey-based
steps with no matching data.

Because this is called ONCE PER EFFECTIVE CLUSTER TYPE (see metal-settings.effectiveRolloutTypes),
a Version-kind step's (BMCVersionSet/BIOSVersionSet) resolved definition may legitimately come out
identical across every (cluster type, ruleIndex) combination a model has (version-kind steps have
no clusterType/rule dimension of their own) - callers rendering Version-kind steps must verify this
and render once per model; see bios_versions.yaml/bmc_versions.yaml for the cross-combination
equality check.

enabled cascades top-down through five independent, optional levels (all default true when unset -
a disabled level skips every step under it regardless of its children's own enabled values):
  - parameters.<vendor>.enabled                           - skips the whole vendor
  - parameters.<vendor>.<model>.enabled                    - skips the whole model
  - parameters.<vendor>.<model>.<bmc|bios>.enabled         - skips the whole domain
  - parameters.<vendor>.<model>.<bmc|bios>.versions.<key>.enabled   - skips just that step
  - parameters.<vendor>.<model>.<bmc|bios>.settings.<key>.enabled  - skips just that step

The ONE reserved, non-pass-through key in a domain's data (not the Workflow) is "enabled" - only
consulted for a step whose Workflow entry itself defines "enabled" (today just
bmc-settings-initial) - when present, OVERRIDES the Workflow's own default for this model (e.g.
HPE/Lenovo set bmc.enabled: false to override Dell's flag-tied default). serverFilter/
setMetadataName/completionConditionTypeOverride/readinessGatesOverride are never read from a
domain's data at all - setMetadataName/completionConditionTypeOverride/readinessGatesOverride live
exclusively on the Workflow step definition ($stepDef, see below); serverFilter is computed
entirely from the matched rule(s)' include.servers/exclude.servers (see
metal-settings.matchingWorkflowsForClusterType above).

Output must be piped through `fromYaml` by the caller (named templates can only return strings).

Usage:
  {{- $chainsByRule := include "metal-settings.computedChain" (dict "vendor" $vendor "model" $model "clusterType" $clusterType "root" $) | fromYaml }}
  {{- range $ruleIndex, $chain := $chainsByRule }}
*/}}
{{- define "metal-settings.computedChain" -}}
{{- $vendor := .vendor -}}
{{- $model := .model -}}
{{- $clusterType := .clusterType -}}
{{- $root := .root -}}
{{- $vendorParams := dig $vendor dict $root.Values.parameters -}}
{{- $base := dig $model dict $vendorParams -}}
{{- $vendorEnabled := true -}}
{{- if hasKey $vendorParams "enabled" -}}
{{- $vendorEnabled = $vendorParams.enabled -}}
{{- end -}}
{{- $modelEnabled := true -}}
{{- if hasKey $base "enabled" -}}
{{- $modelEnabled = $base.enabled -}}
{{- end -}}
{{- $result := dict -}}
{{- if and $vendorEnabled $modelEnabled -}}
{{- $gatesEnabled := $root.Values.CRDVersionControl.features.readinessGates.enabled -}}
{{- $matchedRules := include "metal-settings.matchingWorkflowsForClusterType" (dict "model" $model "clusterType" $clusterType "root" $root) | fromYamlArray -}}
{{- range $ruleIndex, $matchedRule := $matchedRules -}}
{{- $workflow := $matchedRule.workflow -}}
{{- $ruleInclude := $matchedRule.include | default dict -}}
{{- $ruleExclude := $matchedRule.exclude -}}
{{- $includeResources := dig "resources" list $ruleInclude -}}
{{- $includeServers := dig "servers" list $ruleInclude -}}
{{- $excludeModels := list -}}
{{- $excludeResources := list -}}
{{- $excludeServers := list -}}
{{- if $ruleExclude -}}
{{- $excludeModels = dig "models" list $ruleExclude -}}
{{- $excludeResources = dig "resources" list $ruleExclude -}}
{{- $excludeServers = dig "servers" list $ruleExclude -}}
{{- end -}}
{{- $ruleResult := dict -}}
{{- $prevConditionType := "" -}}
{{- $orderedWorkflow := dict -}}
{{- range $stepName, $stepDef := $workflow -}}
{{- if not $stepDef.order -}}
{{- fail (printf "metal-settings: Workflow step %q has no order" $stepName) -}}
{{- end -}}
{{- $orderKey := printf "%04d" (int $stepDef.order) -}}
{{- if hasKey $orderedWorkflow $orderKey -}}
{{- fail (printf "metal-settings: Workflow has two steps with order %d" (int $stepDef.order)) -}}
{{- end -}}
{{- $_ := set $orderedWorkflow $orderKey (dict "name" $stepName "stepDef" $stepDef) -}}
{{- end -}}
{{- range $orderKey, $workflowEntry := $orderedWorkflow -}}
{{- $name := $workflowEntry.name -}}
{{- $stepDef := $workflowEntry.stepDef -}}
{{- $order := int $stepDef.order -}}
{{- $kind := $stepDef.kind -}}
{{/*
Per-step include/exclude evaluation (see metal-settings.matchingWorkflowsForClusterType for the
full semantics). include.resources (if set) uniformly restricts this rule to the listed kinds -
a step whose kind isn't listed is suppressed for every model this rule matches. exclude, if it
matches this (model, kind), either suppresses the step for THIS model only (no exclude.servers -
some other rule owns this kind for this model entirely) or - if exclude.servers is set - leaves
the step rendering but carves those servers out of its serverFilter (some other, narrower rule
owns just those servers for this model+kind).
*/}}
{{- $includeResourceAllowed := or (eq (len $includeResources) 0) (has $kind $includeResources) -}}
{{- $excludeModelMatch := and $ruleExclude (or (eq (len $excludeModels) 0) (has $model $excludeModels)) -}}
{{- $excludeKindMatch := and $excludeModelMatch (or (eq (len $excludeResources) 0) (has $kind $excludeResources)) -}}
{{- $excludeHasServers := gt (len $excludeServers) 0 -}}
{{- $stepSuppressed := or (not $includeResourceAllowed) (and $excludeKindMatch (not $excludeHasServers)) -}}
{{- $stepServerFilter := dict -}}
{{- if gt (len $includeServers) 0 -}}
{{- $_ := set $stepServerFilter "included" $includeServers -}}
{{- end -}}
{{- if and $excludeKindMatch $excludeHasServers -}}
{{- $_ := set $stepServerFilter "excluded" $excludeServers -}}
{{- end -}}
{{- $domainKey := $stepDef.settingsKey | default $stepDef.versionKey | default $stepDef.paramsKey -}}
{{- if not $domainKey -}}
{{- fail (printf "metal-settings: Workflow step %q (kind %q) defines none of settingsKey/versionKey/paramsKey - every step must declare exactly one so its domain can be derived" $name $kind) -}}
{{- end -}}
{{- $domain := index (splitList "." $domainKey) 0 -}}
{{- $data := dig $domain dict $base -}}
{{- $domainEnabled := true -}}
{{- if hasKey $data "enabled" -}}
{{- $domainEnabled = $data.enabled -}}
{{- end -}}
{{- $settingsKey := $stepDef.settingsKey -}}
{{- $settingsEnabled := true -}}
{{- $settingsExists := false -}}
{{- $resolvedSettingsFileName := "" -}}
{{- $resolvedSettingsContent := "" -}}
{{- $settingsRaw := dict -}}
{{- if $settingsKey -}}
{{- $settingsParts := splitList "." $settingsKey -}}
{{- if ne (len $settingsParts) 3 -}}
{{- fail (printf "metal-settings: Workflow step %q has settingsKey %q, expected format \"<domain>.settings.<key>\" (e.g. \"bmc.settings.initialSettings\")" $name $settingsKey) -}}
{{- end -}}
{{- if or (ne (index $settingsParts 0) $domain) (ne (index $settingsParts 1) "settings") -}}
{{- fail (printf "metal-settings: Workflow step %q has settingsKey %q, but this step's domain is %q - expected \"%s.settings.<key>\"" $name $settingsKey $domain $domain) -}}
{{- end -}}
{{- $settingsSubKey := index $settingsParts 2 -}}
{{- $settingsDomainDict := dig "settings" dict $data -}}
{{- $settingsExists = hasKey $settingsDomainDict $settingsSubKey -}}
{{- $settingsRaw = dig $settingsSubKey "" $settingsDomainDict -}}
{{- if kindIs "map" $settingsRaw -}}
{{- $resolvedSettingsFileName = $settingsRaw.settingsFileName -}}
{{- $resolvedSettingsContent = $settingsRaw.settingsContent -}}
{{- if hasKey $settingsRaw "enabled" -}}
{{- $settingsEnabled = $settingsRaw.enabled -}}
{{- end -}}
{{- else -}}
{{- $resolvedSettingsFileName = $settingsRaw -}}
{{- end -}}
{{- end -}}
{{- $versionKey := $stepDef.versionKey -}}
{{- $versionEnabled := true -}}
{{- $versionExists := false -}}
{{- $resolvedVersion := "" -}}
{{- $resolvedImagePath := "" -}}
{{- $resolvedImageURI := "" -}}
{{- $versionRaw := dict -}}
{{- if $versionKey -}}
{{- $versionParts := splitList "." $versionKey -}}
{{- if ne (len $versionParts) 3 -}}
{{- fail (printf "metal-settings: Workflow step %q has versionKey %q, expected format \"<domain>.versions.<key>\" (e.g. \"bmc.versions.defaultVersion\")" $name $versionKey) -}}
{{- end -}}
{{- if or (ne (index $versionParts 0) $domain) (ne (index $versionParts 1) "versions") -}}
{{- fail (printf "metal-settings: Workflow step %q has versionKey %q, but this step's domain is %q - expected \"%s.versions.<key>\"" $name $versionKey $domain $domain) -}}
{{- end -}}
{{- $versionSubKey := index $versionParts 2 -}}
{{- $versionDomainDict := dig "versions" dict $data -}}
{{- $versionExists = hasKey $versionDomainDict $versionSubKey -}}
{{- $versionRaw = dig $versionSubKey dict $versionDomainDict -}}
{{- $resolvedVersion = $versionRaw.version -}}
{{- $resolvedImagePath = $versionRaw.imagePath -}}
{{- $resolvedImageURI = $versionRaw.imageURI -}}
{{- if hasKey $versionRaw "enabled" -}}
{{- $versionEnabled = $versionRaw.enabled -}}
{{- end -}}
{{- end -}}
{{- $paramsKey := $stepDef.paramsKey -}}
{{- $rawParamsEnabled := true -}}
{{- $rawParamsExists := false -}}
{{- $resolvedRawParams := dict -}}
{{- $rawParams := dict -}}
{{- if $paramsKey -}}
{{- $paramsParts := splitList "." $paramsKey -}}
{{- if ne (len $paramsParts) 3 -}}
{{- fail (printf "metal-settings: Workflow step %q has paramsKey %q, expected format \"<domain>.params.<key>\" (e.g. \"firmware.params.defaultVersion\")" $name $paramsKey) -}}
{{- end -}}
{{- if or (ne (index $paramsParts 0) $domain) (ne (index $paramsParts 1) "params") -}}
{{- fail (printf "metal-settings: Workflow step %q has paramsKey %q, but this step's domain is %q - expected \"%s.params.<key>\"" $name $paramsKey $domain $domain) -}}
{{- end -}}
{{- $paramsSubKey := index $paramsParts 2 -}}
{{- $paramsDomainDict := dig "params" dict $data -}}
{{- $rawParamsExists = hasKey $paramsDomainDict $paramsSubKey -}}
{{- $rawParams = dig $paramsSubKey dict $paramsDomainDict -}}
{{- $resolvedRawParams = omit $rawParams "enabled" "completionConditionTypeOverride" "readinessGatesOverride" -}}
{{- if hasKey $rawParams "enabled" -}}
{{- $rawParamsEnabled = $rawParams.enabled -}}
{{- end -}}
{{- end -}}
{{- $settingsKeyPresent := or (not $settingsKey) $settingsExists -}}
{{- $versionKeyPresent := or (not $versionKey) $versionExists -}}
{{- $paramsKeyPresent := or (not $paramsKey) $rawParamsExists -}}
{{- $hasData := and (gt (len $data) 0) $domainEnabled $settingsEnabled $versionEnabled $rawParamsEnabled $settingsKeyPresent $versionKeyPresent $paramsKeyPresent -}}
{{- $conditionType := printf "metal.cloud.sap/step%d-%s-done" $order $name -}}
{{/*
Per-step manual overrides (completionConditionTypeOverride/readinessGatesOverride/setMetadataName)
live EXCLUSIVELY on the Workflow step definition ($stepDef) - never in parameters: (which is pure
vendor/model firmware/settings data, nothing else - see the "Machine inventory" comment).
auto-computation (order+name / nearest-preceding-step, generated default name) stays the default
for every step that doesn't set these. A stepDef-level override is scoped to every model using that
Workflow (or Workflow variant) - to scope it to ONE model/cluster type only, define a new named
Workflow variant with the override baked into its step (same pattern WorkflowSciSettings already
uses for settingsKey customization) and assign it via a rollouts.Types rule (see (3) below), rather
than editing the shared Workflow.

serverFilter is NOT one of these - it's never read from $stepDef at all. Its ONLY source is the
matched rollouts.Types rule's own filter.include.servers/filter.exclude.servers (see
metal-settings.matchingWorkflowsForClusterType above), computed per step above as
$stepServerFilter. A step needing a genuinely different server subset than its siblings in the
same rule gets its own rule (with its own filter.include/filter.exclude) pointing at a Workflow
variant that only changes that one step - there is no separate step-level escape hatch, since
anything it could express a second rule already covers.
*/}}
{{- $finalConditionType := $conditionType -}}
{{- if hasKey $stepDef "completionConditionTypeOverride" -}}
{{- $finalConditionType = $stepDef.completionConditionTypeOverride -}}
{{- end -}}
{{- $readinessGatesOverride := list -}}
{{- $hasReadinessGatesOverride := false -}}
{{- if hasKey $stepDef "readinessGatesOverride" -}}
{{- $readinessGatesOverride = $stepDef.readinessGatesOverride -}}
{{- $hasReadinessGatesOverride = true -}}
{{- end -}}
{{- if and $hasData (not $stepSuppressed) -}}
{{- $params := dict -}}
{{- if $settingsKey -}}
{{- $_ := set $params "settingsFileName" $resolvedSettingsFileName -}}
{{- if $resolvedSettingsContent -}}
{{- $_ := set $params "settingsContent" $resolvedSettingsContent -}}
{{- end -}}
{{- end -}}
{{- if $versionKey -}}
{{- $_ := set $params "version" $resolvedVersion -}}
{{- $_ := set $params "imagePath" $resolvedImagePath -}}
{{- if $resolvedImageURI -}}
{{- $_ := set $params "imageURI" $resolvedImageURI -}}
{{- end -}}
{{- end -}}
{{- if $paramsKey -}}
{{- $params = mergeOverwrite $params $resolvedRawParams -}}
{{- end -}}
{{- if gt (len $stepServerFilter) 0 -}}
{{- $_ := set $params "serverFilter" $stepServerFilter -}}
{{- end -}}
{{- if hasKey $stepDef "setMetadataName" -}}
{{- $_ := set $params "setMetadataName" $stepDef.setMetadataName -}}
{{- end -}}
{{- if $gatesEnabled -}}
{{- $_ := set $params "completionConditionType" $finalConditionType -}}
{{- if $hasReadinessGatesOverride -}}
{{- $_ := set $params "readinessGates" $readinessGatesOverride -}}
{{- else if $prevConditionType -}}
{{- $_ := set $params "readinessGates" (list (dict "type" $prevConditionType "requiredStatus" "True")) -}}
{{- end -}}
{{- end -}}
{{- $step := dict "kind" $kind "order" $order "params" $params -}}
{{- if hasKey $stepDef "enabled" -}}
{{- $_ := set $step "enabled" $stepDef.enabled -}}
{{- end -}}
{{- $_ := set $ruleResult $name $step -}}
{{- $prevConditionType = $finalConditionType -}}
{{- end -}}
{{- $_ := set $result (toString $ruleIndex) $ruleResult -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $result -}}
{{- end -}}



