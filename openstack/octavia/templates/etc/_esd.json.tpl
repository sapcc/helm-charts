{
  "proxy_protocol_2edF_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["proxy_protocol_2edF_v1_0"],
    "lbaas_one_connect": ""
  },
  "proxy_protocol_V2_e8f6_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_proxy_protocol_V2_e8f6_v1_0"],
    "lbaas_one_connect": ""
  },
  "standard_tcp_a3de_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_one_connect": ""
  },
  "x_forward_5b6e_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_x_forward_5b6e_v1_0"]
  },
  "one_connect_dd5c_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_one_connect": "cc_oneconnect_profile"
  },
  "no_one_connect_3caB_v1_0": {
    "lbaas_one_connect": ""
  },
  "http_compression_e4a2_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_http_compression": "cc_httpcompression_profile"
  },
  "cookie_encryption_b82a_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_cookie_encryption_b82a_v1_0"]
  },
  "sso_22b0_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_sso_22b0_v1_0"]
  },
  "sso_required_f544_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_sso_required_f544_v1_0"]
  },
  "http_redirect_a26c_v1_0": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_http_redirect_a26c_v1_0"]
  },
  "hcm_rmk_restrict_internal": {
    "lbaas_ctcp": "cc_tcp_profile",
    "lbaas_irule": ["cc_hcm_rmk_restrict_internal"]
  },
  "cc_esd_udp_stateless": {
    "lbaas_cudp": "cc_udp_datagram_profile"
  },
  "ccloud_special_udp_stateless": {
    "lbaas_cudp": "cc_udp_datagram_profile"
  }
}
