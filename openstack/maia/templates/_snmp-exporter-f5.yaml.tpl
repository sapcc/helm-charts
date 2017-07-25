f5:
  walk:
  - 1.3.6.1.4.1.3375.2.2.10.2.1
  - 1.3.6.1.4.1.3375.2.2.10.2.2
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.1
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.10
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.11
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.12
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.13
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.14
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.15
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.16
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.17
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.18
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.19
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.2
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.20
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.21
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.22
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.23
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.24
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.25
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.26
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.27
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.28
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.29
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.3
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.30
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.31
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.32
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.33
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.34
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.35
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.36
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.37
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.38
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.39
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.4
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.40
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.41
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.42
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.43
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.44
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.5
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.6
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.7
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.8
  - 1.3.6.1.4.1.3375.2.2.10.2.3.1.9
  metrics:
  - name: snmp_f5_ltmVirtualServStatResetStats
    oid: 1.3.6.1.4.1.3375.2.2.10.2.1
    type: gauge
  - name: snmp_f5_ltmVirtualServStatNumber
    oid: 1.3.6.1.4.1.3375.2.2.10.2.2
    type: gauge
  - name: snmp_f5_ltmVirtualServStatName
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.1
    type: DisplayString
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientMaxConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.10
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientTotConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.11
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientCurConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.12
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralPktsIn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.13
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralBytesIn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.14
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralPktsOut
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.15
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralBytesOut
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.16
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralMaxConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.17
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralTotConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.18
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatEphemeralCurConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.19
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatCsMinConnDur
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.2
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaPktsIn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.20
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaBytesIn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.21
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaPktsOut
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.22
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaBytesOut
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.23
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaMaxConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.24
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaTotConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.25
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatPvaCurConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.26
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatTotRequests
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.27
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatTotPvaAssistConn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.28
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatCurrPvaAssistConn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.29
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatCsMaxConnDur
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.3
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatCycleCount
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.30
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatVsUsageRatio5s
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.31
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatVsUsageRatio1m
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.32
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatVsUsageRatio5m
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.33
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatCurrentConnsPerSec
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.34
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatDurationRateExceeded
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.35
    type: gauge
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatSwSyncookies
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.36
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatSwSyncookieAccepts
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.37
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatHwSyncookies
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.38
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatHwSyncookieAccepts
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.39
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatCsMeanConnDur
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.4
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientEvictedConns
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.40
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientSlowKilled
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.41
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatWlSyncookieHits
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.42
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatWlSyncookieAccepts
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.43
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatWlSyncookieRejects
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.44
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatNoNodesErrors
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.5
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientPktsIn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.6
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientBytesIn
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.7
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientPktsOut
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.8
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
  - name: snmp_f5_ltmVirtualServStatClientBytesOut
    oid: 1.3.6.1.4.1.3375.2.2.10.2.3.1.9
    type: counter
    indexes:
    - labelname: ltmVirtualServStatName
      type: DisplayString
