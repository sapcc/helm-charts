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
    metric_type_name: counter
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
    metric_type_name: counter
    command: "show plat hard qfp act feat nat data ha | b Send Fails:"
    timeout_secs: 5
  redundancy_send_queue:
    regex: "0x(.)"
    value: $1
    description: Displays the most significant bit of the send queue possibly indicating a overflow
    metric_type_name: string
    command: "show plat hard qfp act system rg 1 stat | incl tx_seq_flags"
    timeout_secs: 5
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
  qfp_punt_arp_received:
    regex: >-
      \s+\d{3}\s+ARP request or response\s+(\d+)\s+(\d+)
    value: $1
    description: Counter of the number of ARP packages received
    metric_type_name: counter
    command: show platform hardware qfp active infrastructure punt statistics type per-cause | include ^  007.+ARP
    timeout_secs: 3
  qfp_punt_arp_transmitted:
    regex: >-
      \s+\d{3}\s+ARP request or response\s+(\d+)\s+(\d+)
    value: $2
    description: Counter of the number of ARP packages received
    metric_type_name: counter
    command: show platform hardware qfp active infrastructure punt statistics type per-cause | include ^  007.+ARP
    timeout_secs: 3
  software_punt_polcier_arp_conform_normal:
    regex: >-
      \s+\d+\s+ARP request or response\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
    value: $3
    description: Counter of punted, conforming ARP packets
    metric_type_name: counter
    command: show platform software punt-policer | in \ +7\ +ARP
    timeout_secs: 3
  software_punt_polcier_arp_conform_high:
    regex: >-
      \s+\d+\s+ARP request or response\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
    value: $4
    description: Counter of punted, bursted ARP packets
    metric_type_name: counter
    command: show platform software punt-policer | in \ +7\ +ARP
    timeout_secs: 3
  software_punt_polcier_arp_drop_normal:
    regex: >-
      \s+\d+\s+ARP request or response\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
    value: $5
    description: Counter of punted, dropped normal ARP packets
    metric_type_name: counter
    command: show platform software punt-policer | in \ +7\ +ARP
    timeout_secs: 3
  software_punt_polcier_arp_drop_high:
    regex: >-
      \s+\d+\s+ARP request or response\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
    value: $6
    description: Counter of punted, dropped high ARP packets
    metric_type_name: counter
    command: show platform software punt-policer | in \ +7\ +ARP
    timeout_secs: 3
  qfp_classification_ce_data_nat_1001_classes:
    regex: >-
      \(classes: (\d+)
    value: $1
    description: feature-manager class-group ce_data nat 1001 detail
    metric_type_name: gauge
    command: show platform hardware qfp active classification feature-manager class-group ce_data nat 1001 detail | in ^class-group
    timeout_secs: 3
  qfp_classification_client_nat_1001_classes:
    regex: >-
      \(classes: (\d+)
    value: $1
    description: class-group-manager class-Group client nat 1001
    metric_type_name: gauge
    command: show platform hardware qfp active classification class-group-manager class-Group client nat 1001 | in ^class-group
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
    - qfp_punt_arp_received
    - qfp_punt_arp_transmitted
    - software_punt_polcier_arp_conform_normal
    - software_punt_polcier_arp_conform_high
    - software_punt_polcier_arp_drop_normal
    - software_punt_polcier_arp_drop_high
    - qfp_classification_ce_data_nat_1001_classes
    - qfp_classification_client_nat_1001_classes

devices:
  cisco-ios-xe:
    prompt_regex: ^\S+\#$
    init_command: terminal length 0
