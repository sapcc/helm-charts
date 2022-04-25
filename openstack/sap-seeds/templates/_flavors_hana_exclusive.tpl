- name: "hana_c24_m365"
  id: "300"
  vcpus: 24
  ram: 373352
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "373352"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
- name: "hana_c48_m729"
  id: "301"
  vcpus: 48
  ram: 746720
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "746720"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
- name: "hana_c96_m1458"
  id: "302"
  vcpus: 96
  ram: 1493460
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "1493460"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
- name: "hana_c144_m2188"
  id: "303"
  vcpus: 144
  ram: 2240196
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "2240196"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "2"
    "vmware:hw_version": "vmx-15"
- name: "hana_c192_m2917"
  id: "304"
  vcpus: 192
  ram: 2986936
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "2986936"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "2"
    "vmware:hw_version": "vmx-15"
- name: "hana_c384_m5835"
  id: "305"
  vcpus: 384
  ram: 5975024
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "5975024"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "3"
    "vmware:hw_version": "vmx-18"
- name: "hana_c24_m729"
  id: "306"
  vcpus: 24
  ram: 746908
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "746908"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M1459": "required"
- name: "hana_c48_m1459"
  id: "307"
  vcpus: 48
  ram: 1493832
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "1493832"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M1459": "required"
- name: "hana_c96_m2918"
  id: "308"
  vcpus: 96
  ram: 2987680
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "2987680"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M1459": "required"
- name: "hana_c144_m4377"
  id: "309"
  vcpus: 144
  ram: 4481528
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "4481528"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M1459": "required"
    "hw:cpu_cores": "2"
    "vmware:hw_version": "vmx-15"
- name: "hana_c192_m5835"
  id: "310"
  vcpus: 192
  ram: 5975376
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "5975376"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M1459": "required"
    "hw:cpu_cores": "2"
    "vmware:hw_version": "vmx-15"
- name: "hana_c288_m4377"
  id: "311"
  vcpus: 288
  ram: 4481528
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "4481528"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "3"
    "vmware:hw_version": "vmx-18"
- name: "hana_c448_m11671"
  id: "312"
  vcpus: 448
  ram: 11950772
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "11950772"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "required"
    "trait:CUSTOM_NUMASIZE_C56_M1459": "required"
    "hw:cpu_cores": "4"
    "vmware:hw_version": "vmx-18"
