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
    command: show ip nat statistic | include active
    timeout_secs: 3
    
  nat_dynamic:
    regex: >-
      Total active translations: (\d+) \((\d+) static, (\d+) dynamic; (\d+) extended\)
    value: $3
    description: Displays the current active dynamic NAT translations
    metric_type_name: gauge
    command: show ip nat statistic | include active
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

  nat_portblock_tcp_start:
    regex: >-
      ( {0,2}(\d+) {0,2}-(\d+) {1,4}rfcnt (\d+))
    multi_value: true
    value: $2
    labels:
      start: $2
    description: show portblock start handed out to NAT 
    metric_type_name: gauge
    command: show ip nat portblock dynamic global | sec tcp
    timeout_secs: 4

  nat_portblock_tcp_end:
    regex: >-
      ( {0,2}(\d+) {0,2}-(\d+) {1,4}rfcnt (\d+))
    multi_value: true
    value: $3
    labels:
      start: $2
    description: show portblock start handed out to NAT 
    metric_type_name: gauge
    command: show ip nat portblock dynamic global | sec tcp
    timeout_secs: 4

  nat_portblock_udp_start:
    regex: >-
      ( {0,2}(\d+) {0,2}-(\d+) {1,4}rfcnt (\d+))
    multi_value: true
    value: $2
    labels:
      start: $2
    description: show portblock start handed out to NAT 
    metric_type_name: gauge
    command: show ip nat portblock dynamic global | sec udp
    timeout_secs: 4

  nat_portblock_udp_end:
    regex: >-
      ( {0,2}(\d+) {0,2}-(\d+) {1,4}rfcnt (\d+))
    multi_value: true
    value: $3
    labels:
      start: $2
    description: show portblock start handed out to NAT 
    metric_type_name: gauge
    command: show ip nat portblock dynamic global | sec udp
    timeout_secs: 4

  redundancy_state:
    regex: "My Role: ([A-Z]+)"
    value: $1
    map_values:
      - regex: INIT
        value: 1
      - regex: STANDBY
        value: 2
      - regex: ACTIVE
        value: 3
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
    value: $1
    regex: >-
      \s+tx_seq_flags\s+0x(.)\w+
    map_values:
      - regex: "\\d"
        value: 0
      - regex: .*
        value: 1
    description: Displays if the most significant bit is larger 0x9 or not
    metric_type_name: string
    command: "show platform hardware qfp active system rg 1 stat | incl tx_seq_flags"
    timeout_secs: 5
 
  openstack_vrf_count_total:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts all configured OpenStack VRFs
    metric_type_name: gauge
    command: show vrf | count ^  [a-z0-9]
    timeout_secs: 5

  bd_count_total:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts the number BD(-VIF|I)s that are in up state
    metric_type_name: gauge
    command: show interface summary | count ^\* BD
    timeout_secs: 5

  arp_alias_count_total:
    regex: "Total number of Alias ARP entries: (\\d+)."
    value: $1
    description: Counts the number of ARP alias that have been added
    metric_type_name: gauge
    command: show arp summary | include Total
    timeout_secs: 5

  openstack_prefix_lists_count:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts the number of OpenStack prefix lists that have been configured
    metric_type_name: gauge
    command: show ip prefix-list summary | count ^ip prefix-list (ext|snat|route)-
    timeout_secs: 5

  openstack_route_map_count:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts the number of OpenStack route maps that have been configured
    metric_type_name: gauge
    command: show route-map | count ^route-map (exp|pbr)-
    timeout_secs: 5

  openstack_access_list_count:
    regex: "Number of lines which match regexp = (\\d+)"
    value: $1
    description: Counts the number of OpenStack access lists that have been configured
    metric_type_name: gauge
    command: show ip access-lists | count Extended IP access list (NAT|PBR)-
    timeout_secs: 5
  
  qfp_punt_inject_received:
    regex: >-
      ^\s{2}(\d+)\s{2,}((\S|\s)+?)\s{2,}(\d+)\s{2,}(\d+)\s*?$
    value: $4
    multi_value: true
    labels:
      counter_id: $1
      cause_name: $2
    description: Counter of the number of QFP punts and injects
    metric_type_name: counter
    command: show platform hardware qfp active infrastructure punt statistics type per-cause
    timeout_secs: 3

  qfp_punt_inject_transmitted:
    regex: >-
      ^\s{2}(\d+)\s{2,}((\S|\s)+?)\s{2,}(\d+)\s{2,}(\d+)\s*?$
    value: $5
    multi_value: true
    labels:
      counter_id: $1
      cause_name: $2
    description: Counter of the number of QFP punts and injects
    metric_type_name: counter
    command: show platform hardware qfp active infrastructure punt statistics type per-cause
    timeout_secs: 3

  software_punt_polcier_conform_normal:
    regex: >-
      ^\s{0,3}(\d+)\s{2,}((\S|\s)+?)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\w+)\s{2,}(\w+)\s*$
    value: $6
    multi_value: true
    labels:
      cause: $1
      cause_text: $2
    description: Counter of punted, conforming packets
    metric_type_name: counter
    command: show platform software punt-policer
    timeout_secs: 10

  software_punt_polcier_conform_high:
    regex: >-
      ^\s{0,3}(\d+)\s{2,}((\S|\s)+?)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\w+)\s{2,}(\w+)\s*$
    value: $7
    multi_value: true
    labels:
      cause: $1
      cause_text: $2
    description: Counter of punted, conforming bursted (high) packets
    metric_type_name: counter
    command: show platform software punt-policer
    timeout_secs: 10

  software_punt_polcier_drop_normal:
    regex: >-
      ^\s{0,3}(\d+)\s{2,}((\S|\s)+?)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\w+)\s{2,}(\w+)\s*$
    value: $8
    multi_value: true
    labels:
      cause: $1
      cause_text: $2
    description: Counter of punted, dropped packets exceding normal treshhold
    metric_type_name: counter
    command: show platform software punt-policer
    timeout_secs: 10

  software_punt_polcier_drop_high:
    regex: >-
      ^\s{0,3}(\d+)\s{2,}((\S|\s)+?)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\d+)\s{2,}(\w+)\s{2,}(\w+)\s*$
    value: $9
    multi_value: true
    labels:
      cause: $1
      cause_text: $2
    description: Counter of punted, dropped packets exceding high treshhold
    metric_type_name: counter
    command: show platform software punt-policer
    timeout_secs: 10
  
  software_nat_counter_received_nat:
    regex: >-
      ((\d+) (.+?)\n)+
    multi_value: true
    value: $2
    labels:
      message_type: $3
    description: Shows messages received from NAT
    metric_type_name: counter
    command: show platform software nat counter | sec NAT
    timeout_secs: 4

  software_nat_counter_sent_fman:
    regex: >-
      ((\d+) (.+?)\n)+
    multi_value: true
    value: $2
    labels:
      message_type: $3
    description: Shows messages sent to fman from NAT
    metric_type_name: counter
    command: show platform software nat counter | sec Forwarding
    timeout_secs: 4

  software_nat_counter_received_rp:
    regex: >-
      ((\d+) (.+?)\n)+
    multi_value: true
    value: $2
    labels:
      message_type: $3
    description: Shows messages received from RP FMAN
    metric_type_name: counter
    command: show platform software nat counter | sec RP
    timeout_secs: 4

  qfp_classification_ce_data_nat_1001_classes:
    regex: >-
      \(classes: (\d+)
    value: $1
    description: feature-manager class-group ce_data nat 1001 detail
    metric_type_name: gauge
    command: show platform hardware qfp active classification feature-manager class-group ce_data nat 1001 detail | include ^class-group
    timeout_secs: 3

  qfp_classification_client_nat_1001_classes:
    regex: >-
      \(classes: (\d+)
    value: $1
    description: class-group-manager class-Group client nat 1001
    metric_type_name: gauge
    command: show platform hardware qfp active classification class-group-manager class-Group client nat 1001 | include ^class-group
    timeout_secs: 5

  qfp_nat_datapath_stats:
    regex: >-
      Subcode #(\d+)\s+(\S+)\s+(\d+)
    value: $3
    multi_value: true
    labels:
      subcode: $1
      reason: $2
    description: Drop subcodes and counters for QFP NAT processing
    metric_type_name: counter
    command: show platform hardware qfp active feature nat datapath stats
    timeout_secs: 10

  qfp_nat_datapath_gatein:
    regex: >-
      (\w+) (\d+)
    value: $2
    multi_value: true
    labels:
      type: $1
    description: Distribution of entries amoing the NAT Gatekeepers entries
    metric_type_name: gauge
    command: show platform hardware qfp active feature nat datapath gatein activity
    timeout_secs: 3
  
  qfp_nat_datapath_gateout:
    regex: >-
      (\w+) (\d+)
    value: $2
    multi_value: true
    labels:
      type: $1
    description: Distribution of entries amoing the NAT Gatekeepers entries
    metric_type_name: gauge
    command: show platform hardware qfp active feature nat datapath gateout activity
    timeout_secs: 3
  
  tcam_total:
    regex: >-
      ^Total.*?(regions|used cell entries|free cell entries) +: (\d+)
    value: $2
    multi_value: true
    labels:
      type: $1
    description: Usage of TCAM memory
    metric_type_name: gauge
    command: show platform hardware qfp active tcam resource-manager usage | begin Total TCAM Cell Usage Information
    timeout_secs: 3

  bgp_sessions:
    regex: >-
      ^BGP neighbor is (\S+),(\s+vrf (\S+),)?\s+remote AS (\d+),.*?((\w+) link).*?\n\s{2,}BGP state = (\w+),.*?$
    multi_value: true
    value: $7
    labels:
      vrf: $3
      peer_ip: $1
      remote_as: $4
      peer_type: $6
      local_as: $4
    map_values:
      - regex: Established
        value: 8
      - regex: Idle
        value: 2
      - regex: .*
        value: 1
    description: Indicates if a session in a VRF is established or not
    metric_type_name: string
    command: show bgp vpnv4 unicast all neighbors | include (BGP neighbor is|BGP state)
    timeout_secs: 4

  firewall_vrf_stats_total:
    regex: >-
      VRF: (\S+).*?Total Session Count\(estab \+ half-open\): (\d+), Exceed: (\d+)
    multi_value: true
    value: $2
    labels:
      vrf: $1
    description: Indicates the total established connections in the firewalls connection table
    metric_type_name: gauge
    command: show policy-firewall stats vrf | in (VRF|Total|UDP|ICMP|TCP)
    timeout_secs: 4

  firewall_vrf_stats_half_open_udp:
    regex: >-
      VRF: (\S+).*?UDP\s+(\d+)\s+(\d+)
    multi_value: true
    value: $2
    labels:
      vrf: $1
    description: Indicates the connections in a half open state
    metric_type_name: gauge
    command: show policy-firewall stats vrf | in (VRF|Total|UDP|ICMP|TCP)
    timeout_secs: 4

  firewall_vrf_stats_half_open_tcp:
    regex: >-
      VRF: (\S+).*?TCP\s+(\d+)\s+(\d+)
    multi_value: true
    value: $2
    labels:
      vrf: $1
    description: Indicates the connections in a half open state
    metric_type_name: gauge
    command: show policy-firewall stats vrf | in (VRF|Total|UDP|ICMP|TCP)
    timeout_secs: 4

  firewall_vrf_stats_half_open_icmp:
    regex: >-
      VRF: (\S+).*?ICMP\s+(\d+)\s+(\d+)
    multi_value: true
    value: $2
    labels:
      vrf: $1
    description: Indicates the connections in a half open state
    metric_type_name: gauge
    command: show policy-firewall stats vrf | in (VRF|Total|UDP|ICMP|TCP)
    timeout_secs: 4

  nx_ntp_configured:
    regex: >-
      ^ntp server (\S+).*?$
    multi_value: true
    labels:
      ntp_configured: $1
    description: Configured DNS Severs by dns name.
    metric_type_name: string
    command: show running-config ntp | include "ntp server"
    timeout_secs: 5

  xe_ntp_configured:
    regex: >-
      ^\s+ntp server vrf \S+ (\S+).*?$
    multi_value: true
    labels:
      ntp_configured: $1
    description: Configured DNS Severs by dns name.
    metric_type_name: string
    command: show ntp config
    timeout_secs: 5

batches:
  test:
    - redundancy_send_queue
  neutron-router:
    - nat_dynamic
    - nat_static
    - nat_misses
    - nat_hits
    - nat_portblock_tcp_start
    - nat_portblock_tcp_end
    - nat_portblock_udp_start
    - nat_portblock_udp_end
    - redundancy_state
    - redundancy_send_fails_delete
    - redundancy_send_fails_add
    - redundancy_send_queue
    - openstack_vrf_count_total
    - openstack_route_map_count
    - openstack_access_list_count
    - bd_count_total
    - qfp_punt_inject_received
    - qfp_punt_inject_transmitted
    - software_punt_polcier_conform_normal
    - software_punt_polcier_conform_high
    - software_punt_polcier_drop_normal
    - software_punt_polcier_drop_high
    - software_nat_counter_received_nat
    - software_nat_counter_sent_fman
    - software_nat_counter_received_rp
    - qfp_classification_ce_data_nat_1001_classes
    - qfp_classification_client_nat_1001_classes
    - qfp_nat_datapath_stats
    - qfp_nat_datapath_gatein
    - qfp_nat_datapath_gateout
    - bgp_sessions
    - tcam_total
    - firewall_vrf_stats_total
    - firewall_vrf_stats_half_open_udp
    - firewall_vrf_stats_half_open_tcp
    - firewall_vrf_stats_half_open_icmp


  cisco-nx-os_core-router:
    - nx_ntp_configured

  cisco-ios-xe_core-router:
    - xe_ntp_configured

devices:
  cisco-ios-xe:
    prompt_regex: ^\S+\#$
    init_command: terminal length 0
  cisco-nx-os:
    prompt_regex: ^\S+\# $
    init_command: terminal length 0