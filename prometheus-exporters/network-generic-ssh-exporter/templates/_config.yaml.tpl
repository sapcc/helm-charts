credentials:
  default:
    username: {{ .Values.network_generic_ssh_exporter.user }}
    password: {{ .Values.network_generic_ssh_exporter.password }}
metrics:
  nat_static:
    regex: >-
      Total active translations: (\d+) \((\d+) static, (\d+) dynamic; (\d+) extended\)
    value: $2
    description: Displays the current active static NAT translations
    metric_type_name: gauge
    command: show ip nat statistic | in active
    timeout_secs: 3
  nat_dynamic:
    regex: >-
      Total active translations: (\d+) \((\d+) static, (\d+) dynamic; (\d+) extended\)
    value: $3
    description: Displays the current active dynamic NAT translations
    metric_type_name: gauge
    command: show ip nat statistic | in active
    timeout_secs: 3
  nat_misses:
    regex: >-
      Hits:\s+(\d+)\s+Misses:\s(\d+)
    value: $2
    description: Indicates how many packets did not find a match in the current NAT database
    metric_type_name: gauge
    command: show ip nat statistics | incl Misses
    timeout_secs: 3
  nat_hits:
    regex: >-
      Hits:\s+(\d+)\s+Misses:\s(\d+)
    value: $1
    description: Indicates how many packets did not find a match in the current NAT database
    metric_type_name: gauge
    command: show ip nat statistics | incl Misses
    timeout_secs: 3
  redundancy_state:
    regex: "My Role: ([A-Z]+)"
    value: $1
    description: Displays the current role in the redundancy group
    metric_type_name: string
    command: show redundancy application group 1 | inc My Role
    timeout_secs: 5
  redundancy_send_fails_delete:
    regex: "sdel (\\d+)"
    value: $1
    description: Displays how many delete message failed to be sent to the other device
    metric_type_name: gauge
    command: "show plat hard qfp act feat nat data ha | b Send Fails:"
    timeout_secs: 5
  redundancy_send_fails_add:
    regex: "sadd (\\d+)"
    value: $1
    description: Displays how many add message failed to be sent to the other device
    metric_type_name: gauge
    command: "show plat hard qfp act feat nat data ha | b Send Fails:"
    timeout_secs: 5
  redundancy_send_queue:
    regex: "0x(.)"
    value: $1
    description: Displays the most significant bit of the send queue possibly indicating a overflow
    metric_type_name: string
    command: "show plat hard qfp act system rg 1 stat | incl tx_seq_flags"
    timeout_secs: 5
  nat_datapath_drop_counter:
    regex: "ALLOC_ADDR_PORT_FAIL (\\d+)"
    value: $1
    description: Displays the failed port allocations of the nat stack
    metric_type_name: gauge
    command: "show platform hardware qfp active feature nat datapath stats"
    timeout_secs: 10
  vrf_count_cc_cloud:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts the number of CC-CLOUD[0-9]+ named VRFs
    metric_type_name: gauge
    command: show vrf | count CC-CLOUD[0-9]+
    timeout_secs: 5
  vrf_count_total:
    regex: "Current number of VRFs: (\\d+)"
    value: $1
    description: Counts all configured VRFs
    metric_type_name: gauge
    command: show vrf counters | in Current number of VRFs
    timeout_secs: 5
  bd_count_total:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts the number BD(-VIF|I)s that are in up state
    metric_type_name: gauge
    command: show interface summary | count ^\* BD
    timeout_secs: 5
batches:
  neutron-router:
    - nat_dynamic
    - nat_static
    - nat_misses
    - nat_hits
    - redundancy_state
    - redundancy_send_fails_delete
    - redundancy_send_fails_add
    - redundancy_send_queue
    - vrf_count_cc_cloud
    - vrf_count_total
    - bd_count_total
    #- nat_datapath_drop_counter
devices:
  cisco-ios-xe:
    prompt_regex: ^\S+\#$
    init_command: terminal length 0
