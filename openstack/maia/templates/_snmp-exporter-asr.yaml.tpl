# WARNING: This file was auto-generated using snmp_exporter generator, manual changes will be lost.
asr:
  walk:
  - 1.3.6.1.4.1.9.9.109.1.1.1.1.24
  - 1.3.6.1.4.1.9.9.109.1.1.1.1.25
  - 1.3.6.1.4.1.9.9.109.1.1.1.1.26
  - 1.3.6.1.4.1.9.9.532.1.1.1.1
  - 1.3.6.1.4.1.9.10.77.1.2.1
  get:
  - 1.3.6.1.2.1.90.1.2.1.1.3.2.114.103.1.49
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.18.7000.1
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.20.7000.1
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.22.7000.1
  - 1.3.6.1.4.1.9.9.221.1.1.1.1.24.7000.1
  metrics:
  - name: expExpression
    oid: 1.3.6.1.2.1.90.1.2.1.1.3
    type: OctetString
    help: The expression to be evaluated - 1.3.6.1.2.1.90.1.2.1.1.3
    indexes:
    - labelname: expExpressionOwner
      type: DisplayString
    - labelname: expExpressionName
      type: DisplayString
  - name: cpmCPULoadAvg1min
    oid: 1.3.6.1.4.1.9.9.109.1.1.1.1.24
    type: gauge
    help: The overall CPU load Average in the last 1 minute period - 1.3.6.1.4.1.9.9.109.1.1.1.1.24
    indexes:
    - labelname: cpmCPUTotalIndex
      type: gauge
  - name: cpmCPULoadAvg5min
    oid: 1.3.6.1.4.1.9.9.109.1.1.1.1.25
    type: gauge
    help: The overall CPU load Average in the last 5 minutes period - 1.3.6.1.4.1.9.9.109.1.1.1.1.25
    indexes:
    - labelname: cpmCPUTotalIndex
      type: gauge
  - name: cpmCPULoadAvg15min
    oid: 1.3.6.1.4.1.9.9.109.1.1.1.1.26
    type: gauge
    help: The overall CPU load Average in the last 15 minutes period - 1.3.6.1.4.1.9.9.109.1.1.1.1.26
    indexes:
    - labelname: cpmCPUTotalIndex
      type: gauge
  - name: cempMemPoolHCUsed
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.18
    type: counter
    help: Indicates the number of bytes from the memory pool that are currently in
      use by applications on the physical entity - 1.3.6.1.4.1.9.9.221.1.1.1.1.18
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: cempMemPoolHCFree
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.20
    type: counter
    help: Indicates the number of bytes from the memory pool that are currently unused
      on the physical entity - 1.3.6.1.4.1.9.9.221.1.1.1.1.20
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: cempMemPoolHCLargestFree
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.22
    type: counter
    help: Indicates the largest number of contiguous bytes from the memory pool that
      are currently unused on the physical entity - 1.3.6.1.4.1.9.9.221.1.1.1.1.22
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: cempMemPoolHCLowestFree
    oid: 1.3.6.1.4.1.9.9.221.1.1.1.1.24
    type: counter
    help: The lowest amount of available memory in the memory pool recorded at any
      time during the operation of the system - 1.3.6.1.4.1.9.9.221.1.1.1.1.24
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
    - labelname: cempMemPoolIndex
      type: gauge
  - name: cneAddrTranslationNumActive
    oid: 1.3.6.1.4.1.9.9.532.1.1.1.1
    type: gauge
    help: The total number of address translation entries that are currently available
      in the NAT device - 1.3.6.1.4.1.9.9.532.1.1.1.1
    indexes:
    - labelname: entPhysicalIndex
      type: gauge
  - name: snmp_asr_cnatAddrBindNumberOfEntries
    oid: 1.3.6.1.4.1.9.10.77.1.2.1
    type: gauge
