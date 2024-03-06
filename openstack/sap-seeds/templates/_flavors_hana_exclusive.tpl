- name: "hana_c24_m365"
  id: "300"
  vcpus: 24
  ram: 373352
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "24"  # used in nova-vmware as cores-per-socket (12pCPU = 24vCPU)
    "reservation:cpu": "22"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c48_m729"
  id: "301"
  vcpus: 48
  ram: 746720
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "45"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c96_m1458"
  id: "302"
  vcpus: 96
  ram: 1493460
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "91"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c144_m2188"
  id: "303"
  vcpus: 144
  ram: 2240196
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "136"
    "vmware:hw_version": "vmx-18"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c192_m2917"
  id: "304"
  vcpus: 192
  ram: 2986936
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "182"
    "vmware:hw_version": "vmx-18"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c384_m5835"
  id: "305"
  vcpus: 384
  ram: 5975024
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "364"
    "vmware:hw_version": "vmx-18"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c288_m4377"
  id: "311"
  vcpus: 288
  ram: 4481528
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "48"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "273"
    "vmware:hw_version": "vmx-18"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
- name: "hana_c448_m11671"
  id: "313"
  vcpus: 448
  ram: 11950772
  disk: 64
  extra_specs:
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C56_M1459": "required"
    "hw:cpu_cores": "56"  # used in nova-vmware as cores-per-socket (24pCPU = 48vCPU)
    "reservation:cpu": "425"
    "vmware:hw_version": "vmx-18"
    {{- if ( .Values.hana_flavors_quota_separate ) }}
    "quota:instance_only": "true"
    "quota:separate": "true"
    {{- end }}
