# WARNING: This file was auto-generated using snmp_exporter generator, manual changes will be lost.
f5:
  get:
  - 1.3.6.1.4.1.3375.2.1.1.2.20.44.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.45.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.46.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.47.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.48.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.49.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.50.0
  - 1.3.6.1.4.1.3375.2.1.1.2.20.51.0
  - 1.3.6.1.4.1.3375.2.1.1.2.21.28.0
  - 1.3.6.1.4.1.3375.2.1.1.2.21.29.0
  - 1.3.6.1.4.1.3375.2.1.1.2.21.37.0
  - 1.3.6.1.4.1.3375.2.1.1.2.21.38.0
  - 1.3.6.1.4.1.3375.2.1.7.1.1.0
  - 1.3.6.1.4.1.3375.2.1.7.1.2.0
  - 1.3.6.1.4.1.3375.2.1.7.1.3.0
  - 1.3.6.1.4.1.3375.2.1.7.1.4.0
  metrics:
  - name: snmp_f5_sysGlobalHostOtherMemoryTotal
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.44
    type: counter
    help: The total other non-TMM memory in bytes for the system - 1.3.6.1.4.1.3375.2.1.1.2.20.44
  - name: snmp_f5_sysGlobalHostOtherMemoryUsed
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.45
    type: counter
    help: The other non-TMM memory in bytes currently in use for the system - 1.3.6.1.4.1.3375.2.1.1.2.20.45
  - name: snmp_f5_sysGlobalHostSwapTotal
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.46
    type: counter
    help: The total swap in bytes for the system - 1.3.6.1.4.1.3375.2.1.1.2.20.46
  - name: snmp_f5_sysGlobalHostSwapUsed
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.47
    type: counter
    help: The swap in bytes currently in use for the system - 1.3.6.1.4.1.3375.2.1.1.2.20.47
  - name: snmp_f5_sysGlobalHostOtherMemTotalKb
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.48
    type: gauge
    help: The total other non-TMM memory in Kilobytes for the system. - 1.3.6.1.4.1.3375.2.1.1.2.20.48
  - name: snmp_f5_sysGlobalHostOtherMemUsedKb
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.49
    type: gauge
    help: The other non-TMM memory in Kilobytes currently in use for the system. -
      1.3.6.1.4.1.3375.2.1.1.2.20.49
  - name: snmp_f5_sysGlobalHostSwapTotalKb
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.50
    type: gauge
    help: The total swap in Kilobytes for the system. - 1.3.6.1.4.1.3375.2.1.1.2.20.50
  - name: snmp_f5_sysGlobalHostSwapUsedKb
    oid: 1.3.6.1.4.1.3375.2.1.1.2.20.51
    type: gauge
    help: The swap in Kilobytes currently in use for the system. - 1.3.6.1.4.1.3375.2.1.1.2.20.51
  - name: snmp_f5_sysGlobalTmmStatMemoryTotal
    oid: 1.3.6.1.4.1.3375.2.1.1.2.21.28
    type: counter
    help: The total memory available in bytes for TMM (Traffic Management Module)
      - 1.3.6.1.4.1.3375.2.1.1.2.21.28
  - name: snmp_f5_sysGlobalTmmStatMemoryUsed
    oid: 1.3.6.1.4.1.3375.2.1.1.2.21.29
    type: counter
    help: The memory in use in bytes for TMM (Traffic Management Module) - 1.3.6.1.4.1.3375.2.1.1.2.21.29
  - name: snmp_f5_sysGlobalTmmStatMemoryTotalKb
    oid: 1.3.6.1.4.1.3375.2.1.1.2.21.37
    type: gauge
    help: The total memory available in Kilobytes for TMM (Traffic Management Module).
      - 1.3.6.1.4.1.3375.2.1.1.2.21.37
  - name: snmp_f5_sysGlobalTmmStatMemoryUsedKb
    oid: 1.3.6.1.4.1.3375.2.1.1.2.21.38
    type: gauge
    help: The memory in use in Kilobytes for TMM (Traffic Management Module). - 1.3.6.1.4.1.3375.2.1.1.2.21.38
  - name: snmp_f5_sysHostMemoryTotal
    oid: 1.3.6.1.4.1.3375.2.1.7.1.1
    type: counter
    help: The total host memory in bytes - 1.3.6.1.4.1.3375.2.1.7.1.1
  - name: snmp_f5_sysHostMemoryUsed
    oid: 1.3.6.1.4.1.3375.2.1.7.1.2
    type: counter
    help: The host memory in bytes currently in use - 1.3.6.1.4.1.3375.2.1.7.1.2
  - name: snmp_f5_sysHostMemoryTotalKb
    oid: 1.3.6.1.4.1.3375.2.1.7.1.3
    type: gauge
    help: The total host memory in Kilobytes - 1.3.6.1.4.1.3375.2.1.7.1.3
  - name: snmp_f5_sysHostMemoryUsedKb
    oid: 1.3.6.1.4.1.3375.2.1.7.1.4
    type: gauge
    help: The host memory in Kilobytes currently in use - 1.3.6.1.4.1.3375.2.1.7.1.4
