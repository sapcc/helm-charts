{{- define "f5_esd_json" -}}
{{- $context := index . 0 -}}
{{- $loadbalancer := index . 1 -}}
{
  "proxy_protocol_2edF_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp",
    "lbaas_irule": ["proxy_protocol_2edF_v1_0"]
  },
  "standard_tcp_a3de_v1_0": {
    "lbaas_fastl4": "",
    "lbaas_ctcp": "tcp"
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
  }
}
{{- end -}}