[asr1k]
ignore_invalid_az_hint_for_router = {{ default "False" .Values.asr.ignore_invalid_az_hint_for_router}}

[asr1k-address-scopes]
{{ $cloud_asn := required "A valid .Values.global_cloud_asn entry required!" .Values.global_cloud_asn }}
{{- range $i, $address_scope := concat .Values.global_address_scopes .Values.local_address_scopes -}}
{{required "A valid address-scope required!" $address_scope.name}} = {{required "A valid address-scope required!" (default (print $cloud_asn ":1" ($address_scope.vrf | replace "cc-cloud" "")) $address_scope.rd) }}
{{ end }}
