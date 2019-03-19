# WARNING: This file was auto-generated using snmp_exporter generator, manual changes will be lost.
asa:
  walk:
  - 1.3.6.1.4.1.9.9.147.1.2.1.1.1.3
  metrics:
  - name: snmp_asa_cfwHardwareStatusValue
    oid: 1.3.6.1.4.1.9.9.147.1.2.1.1.1.3
    type: gauge
    help: This object contains the current status of the resource. - 1.3.6.1.4.1.9.9.147.1.2.1.1.1.3
    indexes:
    - labelname: cfwHardwareType
      type: gauge
