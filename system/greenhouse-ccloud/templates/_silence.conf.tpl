- status: "active"
  title: "API - Shoot Networks - NetworkNamespaceProbesFailed"
  description: "This silence can be used during non-business hours! It's about Garnder Networks."
  fixed_labels:
    alertname: "NetworkNamespaceProbesFailed"
    network_name: "shoot--it--.*"
    severity: "critical"
  editable_labels:
    - region
- status: "active"
  title: "VMware maintenance - Master Template ESXi Upgrade"
  description: "Silences alerts and all severity for given vccluster"
  fixed_labels:
    tier: "vmware"
  editable_labels:
    - region
    - vccluster
- status: "active"
  title: "VMware maintenance - CinderBackendStorageEmptyCritical"
  description: "Silences the CinderBackend on shard (e.g. vc-a-1)."
  fixed_labels:
    service: "vcenter"
    tier: "vmware"
    alertname: "CinderBackendStorageEmptyCritical"
  editable_labels:
    - region
    - shard
- status: "active"
  title: "VMware maintenance - OpenstackVcenterApiDown"
  description: "Silences the blackbox tests on Openstack VCenter API."
  fixed_labels:
    service: "vcenter"
    tier: "vmware"
    alertname: "OpenstackVcenterApiDown"
    severity: "critical"
  editable_labels:
    - region
    - check
- status: "active"
  title: "VMware maintenance - VCenterRedundancyLostHAPolicyNotConfigured"
  description: "VCenter exporter alert suppression."
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "VCenterRedundancyLostHAPolicyNotConfigured"
    severity: "critical"
  editable_labels:
    - region
    - vccluster
- status: "active"
  title: "VMware maintenance - VCenterRedundancyLostHAPolicyFaulty"
  description: "VCenter exporter alert suppression."
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "VCenterRedundancyLostHAPolicyFaulty"
    severity: "critical"
  editable_labels:
    - region
    - vccluster
- status: "active"
  title: "VMware maintenance - ESXiHostNotResponding"
  description: "Silence integrity blackbox tests."
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "ESXiHostNotResponding."
    severity: "critical"
  editable_labels:
    - region
    - meta
- status: "active"
  title: "VMware maintenance - ESXiHostWithAssociatedVMsNotResponding"
  description: "Silence integrity blackbox tests."
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "ESXiHostWithAssociatedVMsNotResponding"
    severity: "critical"
  editable_labels:
    - region
    - meta
- status: "active"
  title: "VMware maintenance - VCClusterDRSNotFullyAutomated"
  description: "VCenter exporter alert suppression."
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "VCClusterDRSNotFullyAutomated"
  editable_labels:
    - region
    - vccluster
- status: "active"
  title: "VMware maintenance - vPod Build Up"
  description: "Silence all alerts based on host and vccluster - use regex and bbxxx."
  fixed_labels:
    tier: "vmware"
  editable_labels:
    - region
    - vccluster
- status: "active"
  title: "VMware maintenance - NSXTTransportNodeConnectivityNotUP"
  description: "Silence all alerts based on nsxt_transport_node - use regex like 'nodexxx-bbxxx.*'"
  fixed_labels:
    tier: "vmware"
    alertname: "NSXTTransportNodeConnectivityNotUP"
  editable_labels:
    - region
    - nsxt_transport_node
- status: "active"
  title: "VMware maintenance - NSXTManagementNodeOffline"
  description: "Silence NSXTManagementNodeOffline based on the region and nsxv3_manager_hostname - use regex like 'nsx-ctl-bb305.*'"
  fixed_labels:
    tier: "vmware"
    alertname: "NSXTManagementNodeOffline"
  editable_labels:
    - region
    - nsxv3_manager_hostname
- status: "active"
  title: "VMware maintenance - VVol alert silence by VVol Name"
  description: "Silence VVol alerts during VVol maintenance by VVol Name, like 'vVOL_BBxxx.'"
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "VVolDatastoreNotAccessibleFromHost"
    severity: "critical"
  editable_labels:
    - region
    - name
- status: "active"
  title: "VMware maintenance - VVols alert silence by Datacenter (aka: VASA Provider maintenance)"
  description: "Silence VVol alerts during VVol maintenance or VASA Provider maintenance by DataCenter, like eu-de-1a"
  fixed_labels:
    service: "compute"
    tier: "vmware"
    alertname: "VVolDatastoreNotAccessibleFromHost"
    severity: "critical"
  editable_labels:
    - region
    - datacenter
- status: "disabled"
  title: "VmWare silence other"
  description: "This silence silences some other VmWare related alerts and this description should also be better"
  fixed_labels:
    service: "compute"
    tier: "vmware"
  editable_labels:
    - vccluster
    - cluster
- status: "active"
  title: "API - Shoot Networks - NetworkNamespaceProbesFailed - Test: empty"
  description: "This silence can be used during non-business hours! It's about Garnder Networks."
  fixed_labels:
    alertname: "NetworkNamespaceProbesFailed"
    network_name: "shoot--it--.*"
    severity: "critical"
- status: "active"
  title: "API - Shoot Networks - NetworkNamespaceProbesFailed - Test: defaults"
  description: "This silence can be used during non-business hours! It's about Garnder Networks."
  fixed_labels:
    alertname: "NetworkNamespaceProbesFailed"
    network_name: "shoot--it--.*"
    severity: "critical"
  editable_labels:
    - region
    - meta
  editable_labels_default_values:
    - ".*"
    - ".*"
