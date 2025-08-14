{{- range $pool := .Values.bind_pools }}
- name: {{ $pool.name }}
  description: Bind9 Pool
  {{- if $pool.attributes}}
  attributes:
   {{- range $attr := $pool.attributes}}
    {{ $attr.tag }}
   {{- end }}
  {{- end }}
  ns_records:
    {{- range $idx, $srv := $pool.ns_records}}
    - hostname: {{ $srv.hostname }}
      priority: {{ add1 $idx }}
    {{- end}}
  nameservers:
    {{- range $prio, $srv := $pool.nameservers}}
    - host: {{ $srv.ip }}
      port: 53
    {{- end}}
  targets:
    {{- range $idx, $srv := $pool.nameservers}}
    - type: bind9
      description: BIND9 Server {{ add1 $idx }}

      # List out the designate-mdns servers from which BIND servers should
      # request zone transfers (AXFRs) from.
      masters:
        - host: {{ $.Values.global.designate_mdns_external_ip }}
          port: 5354

      # BIND Configuration options
      options:
        host: {{$srv.ip}}
        port: 53
        rndc_host: {{ $srv.ip }}
        rndc_port: {{ $pool.rndc_port }}
        rndc_key_file: {{ $pool.rndc_key_file }}
        clean_zonefile: {{ $pool.clean_zonefile | default "False" }}
    {{- end}}
{{- end }}
{{- range $pool := .Values.catz_pools }}
- name: {{ $pool.name }}
  description: Catz Pool
  {{- if $pool.attributes}}
  attributes:
   {{- range $attr := $pool.attributes}}
    {{ $attr.tag }}
   {{- end }}
  {{- end }}
  ns_records:
    {{- range $idx, $srv := $pool.ns_records}}
    - hostname: {{ $srv.hostname }}
      priority: {{ add1 $idx }}
    {{- end}}
  nameservers:
    {{- range $prio, $srv := $pool.nameservers}}
    - host: {{ $srv.ip }}
      port: 53
    {{- end}}
  catalog_zone:
      catalog_zone_fqdn: catalog.pool.{{ $pool.name }}.
      catalog_zone_refresh: 60
      catalog_zone_tsig_key: {{ tpl $pool.tsigkey $ | include "resolve_secret" }}
      catalog_zone_tsig_algorithm: {{ tpl ($pool.tsigkeyalgorithm | default "hmac-sha512") $ | include "resolve_secret" }}
{{- end }}
{{- range $pool := .Values.akamai_pools_v2 }}
- name: {{ $pool.name }}
  description: Akamai Edge DNS v2 Pool
  attributes:
   {{- range $attr := $pool.attributes}}
    {{ $attr.tag }}
   {{- end }}
  ns_records:
    {{- range $idx, $srv := $pool.nameservers}}
    - hostname: {{ $srv.hostname }}
      priority: {{ add1 $idx }}
    {{- end}}
  nameservers:
    {{- range $prio, $srv := $pool.nameservers}}
    - host: {{ $srv.ip }}
      port: 53
    {{- end}}
  {{- if $pool.also_notifies}}
  also_notifies:
    {{- range $i, $notify := $pool.also_notifies}}
    - host: {{ $notify.host }}
      port: {{ $notify.port }}
    {{- end}}
  {{- end}}
  targets:
    - type: akamai_v2
      description: Akamai v2 DNS API

      # List out the designate-mdns servers from which Akamai servers should
      # request zone transfers (AXFRs) from.
      masters:
        - host: {{ $.Values.global.designate_mdns_akamai_ip }}
          port: 53

      # Akamai Configuration options
      options:
        host: {{ $pool.options.host }}
        port: {{ $pool.options.port }}
        akamai_host: {{ $pool.options.akamai_host }}
        akamai_client_token: {{ $pool.options.akamai_client_token | include "resolve_secret" }}
        akamai_access_token: {{ $pool.options.akamai_access_token | include "resolve_secret" }}
        akamai_client_secret: {{ $pool.options.akamai_client_secret | include "resolve_secret" }}
        akamai_contract_id: {{ $pool.options.akamai_contract_id | include "resolve_secret" }}
        akamai_gid: {{ $pool.options.akamai_gid }}
        tsig_key_name: "{{ $pool.options.tsig_key_name }}"
        tsig_key_secret: {{ $pool.options.tsig_key_secret | include "resolve_secret" }}
        tsig_key_algorithm: "{{ $pool.options.tsig_key_algorithm }}"
{{- end }}
