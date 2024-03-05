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

- name: gmp_m1024_c128
  id: cb13a435-bd62-4569-ad02-2da67f88b776
  vcpus: 128
  ram: 1048576
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    trait:CUSTOM_NUMASIZE_C48_M729: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18

- name: gmp_m1024_c96
  id: 97709ba4-e52e-4a92-ae28-caf53f28243e
  vcpus: 96
  ram: 1048576
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    trait:CUSTOM_NUMASIZE_C48_M729: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18

- name: gmp_m1024_c96_hana
  id: a219a815-e08e-47c6-9b71-bc77bc1cbbfd
  vcpus: 96
  ram: 1048576
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    trait:CUSTOM_NUMASIZE_C48_M729: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18

- name: gmp_m128_c20
  id: 85a96f15-70f8-43fd-86f3-cdde3c26874a
  vcpus: 20
  ram: 131072
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m128_c8
  id: fb00681d-ae99-4a8a-9e4d-b1b832f30cab
  vcpus: 8
  ram: 131072
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m16_c4
  id: de149b2d-ac27-49a2-8974-9169f0c3ff34
  vcpus: 4
  ram: 16384
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m1946_c128
  id: db25520d-b4d7-4485-850b-140021557ea5
  vcpus: 128
  ram: 1992704
  disk: 40
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{ else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "1992704"
{{- end }}
    trait:CUSTOM_NUMASIZE_C48_M729: required
    hw:cpu_cores: '48'  # cores-per-socket

- name: gmp_m200_c24
  id: 0788f792-25d8-4538-b410-287d55de0380
  vcpus: 24
  ram: 204800
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m246_c24_hana
  id: 576b9c5d-5ebe-4281-8ff5-250891efab18
  vcpus: 24
  ram: 251904
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m24_c8
  id: a9666665-a504-40e5-a191-c18c09188298
  vcpus: 8
  ram: 24576
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m256_c24
  id: 098aefa2-b45f-4bb0-808b-4606d53e0167
  vcpus: 24
  ram: 262144
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m256_c24_hana
  id: 4fe207d5-32a8-49a8-a8d0-ca1710969ce0
  vcpus: 24
  ram: 262144
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m256_c32
  id: 7361b99c-fae3-4dd7-a291-68f1bf2d28a7
  vcpus: 32
  ram: 262144
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m256_c40
  id: 74f07fca-ae8d-4585-894c-acd82548a2ff
  vcpus: 40
  ram: 262144
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m256_c64
  id: e29d2378-16c2-4654-83fa-d19f470ab991
  vcpus: 64
  ram: 262144
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m2_c2
  id: 911ee148-d131-471e-b475-1fb4de6b76cf
  vcpus: 2
  ram: 2048
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m320_c24_hana
  id: e88de616-3d65-4ed0-87b0-e06641f1943c
  vcpus: 24
  ram: 327680
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m32_c10
  id: "101"
  vcpus: 10
  ram: 32768
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m32_c12
  id: 6551a9d9-6010-4174-ad51-0e988ea18aed
  vcpus: 12
  ram: 32768
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m32_c8
  id: 3b051fec-386b-42d0-89c2-e92dac2a5658
  vcpus: 8
  ram: 32768
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m44_c12
  id: dc59f223-6394-4759-88f2-6069dcf5e03e
  vcpus: 12
  ram: 45056
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m48_c12
  id: 3cfb669e-7371-49bb-a536-238503ce631c
  vcpus: 12
  ram: 49152
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m48_c32
  id: eea81c29-77f8-4015-acf0-5e85f27d9830
  vcpus: 32
  ram: 49152
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m4_c2
  id: 1c571abf-cc81-4e99-859f-5a991cbc0b14
  vcpus: 2
  ram: 4096
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m4_c4
  id: 29537e93-9be7-43ed-8ccd-83ae38050393
  vcpus: 4
  ram: 4096
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m512_c32
  id: 38f2d6d7-6f83-4c53-b183-3968fe2e94a6
  vcpus: 32
  ram: 524288
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m512_c60
  id: 115b5ea7-0dcb-4254-ae91-052fb01ae57b
  vcpus: 60
  ram: 524288
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m64_c12
  id: adb79f96-904c-4e4d-8480-046d0f5f7d4e
  vcpus: 12
  ram: 65536
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m64_c20
  id: 90cf44cb-11a5-4fd0-a76a-68772fe92919
  vcpus: 20
  ram: 65536
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m64_c60
  id: 6ecde341-e475-4fb3-8802-58a69e68837f
  vcpus: 60
  ram: 65536
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m8_c32
  id: dab7c9da-0a00-4885-9e53-811ec670fe0e
  vcpus: 32
  ram: 8192
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m8_c4
  id: 9e0fa54d-3112-4ec1-8b38-bb407b5d978b
  vcpus: 4
  ram: 8192
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: gmp_m8_c8
  id: ac16ac87-49bc-400f-ad9c-da8c41da4f85
  vcpus: 8
  ram: 8192
  disk: 40
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}

- name: hana_c24_m729
  id: "306"
  vcpus: 24
  ram: 746908
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{ else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "746908"
{{- end }}
    trait:CUSTOM_NUMASIZE_C48_M1459: required
    hw:cpu_cores: '24'  # cores-per-socket
    vmware:hw_version: vmx-18
    {{- if .Values.hana_flavors_quota_separate }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    "limes:allow_growth": "false" # never report capacity above the current usage
    {{- end }}

- name: hana_c48_m1459
  id: "307"
  vcpus: 48
  ram: 1493832
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{ else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "1493832"
{{- end }}
    trait:CUSTOM_NUMASIZE_C48_M1459: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18
    {{- if .Values.hana_flavors_quota_separate }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    "limes:allow_growth": "false" # never report capacity above the current usage
    {{- end }}

- name: hana_c96_m2918
  id: "308"
  vcpus: 96
  ram: 2987680
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{ else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "2987680"
{{- end }}
    trait:CUSTOM_NUMASIZE_C48_M1459: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18
    {{- if .Values.hana_flavors_quota_separate }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    "limes:allow_growth": "false" # never report capacity above the current usage
    {{- end }}

- name: hana_c192_m5835
  id: "310"
  vcpus: 192
  ram: 5975376
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{ else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "5975376"
{{- end }}
    trait:CUSTOM_NUMASIZE_C48_M1459: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18
    {{- if .Values.hana_flavors_quota_separate }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    "limes:allow_growth": "false" # never report capacity above the current usage
    {{- end }}

- name: x1.64xlarge
  id: "251"
  vcpus: 128
  ram: 4194304
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
{{ else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "4194304"
{{- end }}
    trait:CUSTOM_NUMASIZE_C48_M729: required
    hw:cpu_cores: '48'  # cores-per-socket
    vmware:hw_version: vmx-18


- name: xclarity
  id: deleted_160
  vcpus: 8
  ram: 8176
  disk: 192
  is_public: false
  extra_specs:
    {{- tuple . "vmware" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
