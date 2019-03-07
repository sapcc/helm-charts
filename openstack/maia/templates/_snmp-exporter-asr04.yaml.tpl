# WARNING: This file was auto-generated using snmp_exporter generator, manual changes will be lost.
asr04:
  get:
  - 1.3.6.1.2.1.197.1.2.1.0
  metrics:
  - name: snmp_asr04_ntpEntStatusCurrentMode
    oid: 1.3.6.1.2.1.197.1.2.1
    type: gauge
    help: The current mode of the NTP - 1.3.6.1.2.1.197.1.2.1
    enum_values:
      1: notRunning
      2: notSynchronized
      3: noneConfigured
      4: syncToLocal
      5: syncToRefclock
      6: syncToRemoteServer
      99: unknown
