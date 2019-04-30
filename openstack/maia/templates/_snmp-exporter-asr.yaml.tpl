# WARNING: This file was auto-generated using snmp_exporter generator, manual changes will be lost.
asr:
  walk:
  - 1.3.6.1.2.1.2.2.1.2
  - 1.3.6.1.2.1.2.2.1.7
  - 1.3.6.1.2.1.2.2.1.8
  - 1.3.6.1.4.1.9.9.109.1.1.1.1.24
  - 1.3.6.1.4.1.9.9.109.1.1.1.1.25
  - 1.3.6.1.4.1.9.9.109.1.1.1.1.26
  - 1.3.6.1.4.1.9.9.532.1.1.1.1
  get:
  - 1.3.6.1.2.1.123.1.5.0
  - 1.3.6.1.2.1.123.1.7.0
  - 1.3.6.1.2.1.90.1.2.1.1.3.9.110.97.116.77.105.115.115.101.115.9.110.97.116.77.105.115.115.101.115
  - 1.3.6.1.4.1.9.10.77.1.2.1.0
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.18.7000.1
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.20.7000.1
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.22.7000.1
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.24.7000.1
  metrics:
  - name: snmp_asr_natAddrBindNumberOfEntries
    oid: 1.3.6.1.2.1.123.1.5
    type: gauge
    help: This object maintains a count of the number of entries that currently exist
      in the natAddrBindTable. - 1.3.6.1.2.1.123.1.5
  - name: snmp_asr_natAddrPortBindNumberOfEntries
    oid: 1.3.6.1.2.1.123.1.7
    type: gauge
    help: This object maintains a count of the number of entries that currently exist
      in the natAddrPortBindTable. - 1.3.6.1.2.1.123.1.7
  - name: snmp_asr_ifDescr
    oid: 1.3.6.1.2.1.2.2.1.2
    type: DisplayString
    help: A textual string containing information about the interface - 1.3.6.1.2.1.2.2.1.2
    indexes:
    - labelname: ifIndex
      type: gauge
  - name: snmp_asr_ifAdminStatus
    oid: 1.3.6.1.2.1.2.2.1.7
    type: gauge
    help: The desired state of the interface - 1.3.6.1.2.1.2.2.1.7
    indexes:
    - labelname: ifIndex
      type: gauge
    enum_values:
      1: up
      2: down
      3: testing
  - name: snmp_asr_ifOperStatus
    oid: 1.3.6.1.2.1.2.2.1.8
    type: gauge
    help: The current operational state of the interface - 1.3.6.1.2.1.2.2.1.8
    indexes:
    - labelname: ifIndex
      type: gauge
    enum_values:
      1: up
      2: down
      3: testing
      4: unknown
      5: dormant
      6: notPresent
      7: lowerLayerDown
  - name: snmp_asr_expExpression
    oid: 1.3.6.1.2.1.90.1.2.1.1.3
    type: DisplayString
    help: The expression to be evaluated - 1.3.6.1.2.1.90.1.2.1.1.3
    indexes:
    - labelname: expExpressionOwner
      type: DisplayString
    - labelname: expExpressionName
      type: DisplayString
  - name: snmp_asr_cnatAddrBindNumberOfEntries
    oid: 1.3.6.1.4.1.9.10.77.1.2.1
    type: gauge
    help: This object maintains a count of the number of entries that currently exist
      in the cnatAddrBindTable. - 1.3.6.1.4.1.9.10.77.1.2.1
  - name: snmp_asr_cpmCPULoadAvg1min
    oid: 1.3.6.1.4.1.9.9.109.1.1.1.1.24
    type: gauge
    help: The overall CPU load Average in the last 1 minute period - 1.3.6.1.4.1.9.9.109.1.1.1.1.24
    indexes:
    - labelname: cpmCPUTotalIndex
      type: gauge
  - name: snmp_asr_cpmCPULoadAvg5min
    oid: 1.3.6.1.4.1.9.9.109.1.1.1.1.25
    type: gauge
    help: The overall CPU load Average in the last 5 minutes period - 1.3.6.1.4.1.9.9.109.1.1.1.1.25
    indexes:
    - labelname: cpmCPUTotalIndex
      type: gauge
  - name: snmp_asr_cpmCPULoadAvg15min
    oid: 1.3.6.1.4.1.9.9.109.1.1.1.1.26
    type: gauge
    help: The overall CPU load Average in the last 15 minutes period - 1.3.6.1.4.1.9.9.109.1.1.1.1.26
    indexes:
    - labelname: cpmCPUTotalIndex
      type: gauge
  - name: snmp_asr_cempMemPoolHCUsed
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.18
    type: counter
    help: Indicates the number of bytes from the memory pool that are currently in
      use by applications on the physical entity - 1.3.6.1.4.1.9.9.221.1.1.1.1.18
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: snmp_asr_cempMemPoolHCFree
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.20
    type: counter
    help: Indicates the number of bytes from the memory pool that are currently unused
      on the physical entity - 1.3.6.1.4.1.9.9.221.1.1.1.1.20
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: snmp_asr_cempMemPoolHCLargestFree
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.22
    type: counter
    help: Indicates the largest number of contiguous bytes from the memory pool that
      are currently unused on the physical entity - 1.3.6.1.4.1.9.9.221.1.1.1.1.22
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: snmp_asr_cempMemPoolHCLowestFree
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.24
    type: counter
    help: The lowest amount of available memory in the memory pool recorded at any
      time during the operation of the system - 1.3.6.1.4.1.9.9.221.1.1.1.1.24
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: snmp_asr_cneAddrTranslationNumActive
    oid: 1.3.6.1.4.1.9.9.532.1.1.1.1
    type: gauge
    help: The total number of address translation entries that are currently available
      in the NAT device - 1.3.6.1.4.1.9.9.532.1.1.1.1
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
