{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "infraMonitoring.name" -}}
{{- default .Chart.Name .Values.nameOverride | replace "_" "-" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "infraMonitoring.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | replace "_" "-" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | replace "_" "-" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | replace "_" "-" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "infraMonitoring.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | replace "_" "-" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "prometheusVMware.fullName" -}}
{{- $name := index . 0 -}}
{{- $root := index . 1 -}}
{{- $vropshostname := split "." $name -}}
prometheus-vmware-{{ $vropshostname._0 | trimPrefix "vrops-" }}
{{- end -}}

{{- define "snmp_metric_relabel_configs" -}}
metric_relabel_configs:
  - source_labels: [server_name]
    target_label:  devicename
  - source_labels: [devicename]
    regex: '(\w*-\w*-\w*)-(\S*)'
    replacement: '$1'
    target_label: availability_zone
  - source_labels: [devicename]
    regex: '(\w*-\w*-\w*)-(\S*)'
    replacement: '$2'
    target_label: device
  - source_labels: [__name__, snmp_n3k_sysDescr]
    regex: 'snmp_n3k_sysDescr;(?s)(.*)(Version )([0-9().a-zIU]*)(,.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_aristaevpn_sysDescr]
    regex: 'snmp_aristaevpn_sysDescr;(?s)(.*)(version )([0-9.a-zA-Z]*)(.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_coreasr9k_sysDescr]
    regex: 'snmp_coreasr9k_sysDescr;(?s)(.*)(Version )([0-9.]*)(.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_pxgeneric_sysDescr]
    regex: 'snmp_pxgeneric_sysDescr;(.*)(, Version )([0-9().a-zIU]*)((?s).*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_n9kpx_ciscoImageString]
    regex: 'snmp_n9kpx_ciscoImageString;(.*)(\$)(.*)(\$)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__,inetCidrRouteProto]
    regex: 'snmp_n9kpx_inetCidrRouteProto;(bbnSpfIgp|ttdp|rpl|rip|other|netmgmt|isIs|idpr|icmp|hello|ggp|esIs|egp|dvmrp|dhcp|ciscoIgrp|ciscoEigrp|bgp)'
    action: drop
  - source_labels: [__name__,inetCidrRouteStatus]
    regex: 'snmp_n9kpx_inetCidrRouteStatus;(createAndGo|createAndWait|destroy|notInService|notReady)'
    action: drop
  - source_labels: [__name__, snmp_ipn_sysDescr]
    regex: 'snmp_ipn_sysDescr;(?s)(.*)(Version )([0-9().a-zIU]*)(,.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_arista_entPhysicalSoftwareRev]
    regex: 'snmp_arista_entPhysicalSoftwareRev;(.*)'
    replacement: '$1'
    target_label: image_version
  - source_labels: [__name__, etherStatsIndex]
    regex: 'snmp_arista_etherStatsCRCAlignErrors;(1\.3\.6\.1\.2\.1\.2\.2\.1\.1\.)([0-9]*)'
    replacement: '$2'
    target_label: ifIndex
  - source_labels: [__name__, snmp_asa_sysDescr]
    regex: 'snmp_asa_sysDescr;([a-zA-Z ]*)([0-9().]*)'
    replacement: '$2'
    target_label: image_version
  - source_labels: [__name__, device]
    regex: 'snmp_asa_sysDescr;(ASA0102-CC-CORP|AsSA0102-CC-DMZ|ASA0102-CC-HEC|ASA0102-CC-INTERNET|ASA0102-CC-SAAS|ASA0102a-CC-HEC|ASA0102a-CC-DMZ|ASA0102a-CC-CORP|ASA0102a-CC-INTERNET|ASA0102a-CC-SAAS)'
    action: drop
  - source_labels: [__name__, ifDescr]
    regex: 'snmp_acileaf_if.+;(Tunnel)[0-9]*'
    action: drop
  - source_labels: [__name__, snmp_acileaf_sysDescr]
    regex: 'snmp_acileaf_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_acispine_sysDescr]
    regex: 'snmp_acispine_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_asr_sysDescr]
    regex: 'snmp_asr_sysDescr;(?s)(.*)(Version )([0-9().a-zIU:]*)(, )?(CUST-SPECIAL:)?([A-Z0-9_]*)?(.*)'
    replacement: ${3}${6}
    target_label: image_version
  - source_labels: [__name__, snmp_asr03_sysDescr]
    regex: 'snmp_asr03_sysDescr;(?s)(.*)(Version )([0-9().a-z]*)(,.*)'
    replacement: '$3'
    target_label: image_version
  - source_labels: [__name__, snmp_f5_sysProductVersion]
    regex: 'snmp_f5_sysProductVersion;(.*)'
    replacement: '$1'
    target_label: image_version
  - source_labels: [__name__, snmp_acistretch_sysDescr]
    regex: "snmp_acistretch_sysDescr;(?s)(.*)Version ([0-9.]*)(.*)"
    replacement: '$2'
    target_label: image_version
  - source_labels: [__name__, cucsEtherErrStatsDn]
    regex: 'snmp_ucs_cucsEtherErrStats.+;.+(lan).+'
    action: drop
  - source_labels: [__name__, cucsFcErrStatsDn]
    regex: 'snmp_ucs_cucsFcErrStats.+;.+(port)-([3-9]|\d{2}).+'
    action: drop
  - source_labels: [__name__, ifAlias]
    regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
    replacement: '$3'
    target_label: project_id
  - source_labels: [__name__, ifAlias]
    regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
    replacement: '$4'
    target_label: router_id
  - source_labels: [__name__, ifAlias]
    regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
    replacement: '$5'
    target_label: network_id
  - source_labels: [__name__, ifAlias]
    regex: '^snmp_asr_.+;([a-z:]+);(project|)*:?([a-z0-9)]*);?router:([a-z0-9-]*);network:([a-z0-9-]*);subnet:([a-z0-9-]*)'
    replacement: '$6'
    target_label: subnet_id
  - source_labels: [__name__, device]
    regex: '^snmp_asr_[A-za-z0-9]+;((rt|asr)[0-9]+)[a|b]$'
    replacement: '$1'
    target_label: asr_pair
    action: replace
{{- end -}}