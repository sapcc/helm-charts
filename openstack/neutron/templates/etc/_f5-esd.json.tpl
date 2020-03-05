{{- define "f5_esd_json" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
{
  "proxy_protocol_2edF_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp",
    "lbaas_irule": ["proxy_protocol_2edF_v1_0"],
    "lbaas_one_connect": ""
  },
  "proxy_protocol_V2_e8f6_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp",
    "lbaas_irule": ["cc_proxy_protocol_V2_e8f6_v1_0"],
    "lbaas_one_connect": ""
  },
  "standard_tcp_a3de_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp",
    "lbaas_one_connect": ""
  },
  "x_forward_5b6e_v1_0": {
    "lbaas_irule": ["cc_x_forward_5b6e_v1_0"]
  },
  "one_connect_dd5c_v1_0": {
    "lbaas_one_connect": "oneconnect"
  },
  "no_one_connect_3caB_v1_0": {
    "lbaas_one_connect": ""
  },
  "http_compression_e4a2_v1_0": {
    "lbaas_http_compression": "cc_http_compression_e4a2_v1_0"
  },
  "cookie_encryption_b82a_v1_0": {
    "lbaas_irule": ["cc_cookie_encryption_b82a_v1_0"]
  },
  "sso_22b0_v1_0": {
    "lbaas_irule": ["cc_sso_22b0_v1_0"]
  },
  "sso_required_f544_v1_0": {
    "lbaas_irule": ["cc_sso_required_f544_v1_0"]
  },
  "http_redirect_a26c_v1_0": {
    "lbaas_irule": ["cc_http_redirect_a26c_v1_0"]
  }
}
{{- end -}}