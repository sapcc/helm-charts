# Removed flavors are kept _private_ ("is_public: false") in here instead of
# actually deleting them to allow management of old instances with these
# flavors.

# To query if one or more flavors are still in use run the following query in
# the "nova" DB (replace $FLAVOR with the flavor name(s)) of every region:
#
#   SELECT
#       i2.project_id,
#       i2.created_at,
#       i2.uuid,
#       i2.host,
#       i2.hostname AS name,
#       j1.flavor
#   FROM instances AS i2
#   JOIN (
#       SELECT
#           instance_uuid,
#           json_value(flavor, '$.cur."nova_object.data".name') AS flavor
#       FROM instance_extra AS ie
#       JOIN (SELECT uuid FROM instances WHERE deleted = 0) AS i
#       ON i.uuid = ie.instance_uuid
#   ) AS j1
#   ON j1.instance_uuid = i2.uuid
#   WHERE flavor in ('$FLAVOR');

- name: "m5.96xlarge"
  id: "270"
  vcpus: 90
  ram: 1468416
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{- else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "host_fraction": "1/4,3/4,1/2,1"
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "1468416"
{{- end }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "vmware:hw_version": "vmx-18"

- name: "m5.192xlarge"
  id: "271"
  vcpus: 106
  ram: 2979840
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{- else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "host_fraction": "1,1/2"
{{- end }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "vmware:hw_version": "vmx-18"

- name: "x1.32xlarge"
  id: "250"
  vcpus: 128
  ram: 1991680
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{- else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "host_fraction": "1,0.67,0.34"
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "1991680"
{{- end }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "vmware:hw_version": "vmx-18"
