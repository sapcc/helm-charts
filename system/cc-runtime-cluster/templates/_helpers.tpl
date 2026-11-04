{{/*
Short hash of the machine template image string.

Used as a suffix on IroncoreMetalMachineTemplate object names so that
any change to .Values.machineTemplate.image rotates the template's
name. KubeadmControlPlane and MachineDeployment detect the rotation
via infrastructureRef.name and trigger a rolling update automatically.

See system/cc-runtime-cluster/docs/issue-1277-automate-image-rollout.md
for background.
*/}}
{{- define "cc-runtime-cluster.imageHash" -}}
{{- .Values.machineTemplate.image | sha256sum | trunc 8 -}}
{{- end -}}
