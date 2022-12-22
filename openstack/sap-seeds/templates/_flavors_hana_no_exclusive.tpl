- name: "hana_c24_m365"
  id: "300"
  vcpus: 24
  ram: 373352
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "373352"
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
    "resources:CUSTOM_BIGVM": "2"
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
    "resources:CUSTOM_BIGVM": "2"
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
    "resources:CUSTOM_BIGVM": "2"
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
    "resources:CUSTOM_BIGVM": "2"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "3"
    "vmware:hw_version": "vmx-18"
- name: "hana_c288_m4377"
  id: "311"
  vcpus: 288
  ram: 4481528
  disk: 64
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "resources:CUSTOM_MEMORY_RESERVABLE_MB": "4481528"
    "resources:CUSTOM_BIGVM": "2"
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
    "hw:cpu_cores": "3"
    "vmware:hw_version": "vmx-18"

### Deprecated BigVM flavors
- name: "m5.96xlarge"
  id: "270"
  vcpus: 90
  ram: 1468416
  disk: 64
  is_public: true
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "host_fraction": "1/4,3/4,1/2,1"
    "resources:CUSTOM_BIGVM": "2"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "forbidden"
- name: "x1.32xlarge"
  id: "250"
  vcpus: 128
  ram: 1991680
  disk: 64
  is_public: true
  extra_specs:
    "vmware:hv_enabled": "True"
    "hw_video:ram_max_mb": "16"
    "host_fraction": "1,0.67,0.34"
    "resources:CUSTOM_BIGVM": "2"
    "trait:CUSTOM_HANA_EXCLUSIVE_HOST": "forbidden"
