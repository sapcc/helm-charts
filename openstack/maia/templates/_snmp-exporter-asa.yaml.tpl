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
    enum_values:
      1: other
      2: up
      3: down
      4: error
      5: overTemp
      6: busy
      7: noMedia
      8: backup
      9: active
      10: standby
