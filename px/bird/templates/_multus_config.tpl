{{- define "multus_config" -}}
{{- $vlan:= index . 0 -}}
{{- $ip:= index . 1 -}}
{
    "cniVersion": "0.3.0",
    "type": "macvlan",
    "master": "vlan{{ $vlan }}",
    "mode": "bridge",
    "ipam": {
    "type": "static",
    "addresses": [{ "address": "{{ $ip }}"}]
    }
}
{{ end }}