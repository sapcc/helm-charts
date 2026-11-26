{{- if $.Values.tsig }}
server {{ $.Values.master_server }} {
 keys {{ $.Values.tsig.keyname }};
};
{{- else }}
server {{ $.Values.master_server }} {
 keys {{ tpl ( $.Values.tsig_key_name | default "tsig-key" ) $ }};
};
{{- end }}

include "/etc/bind/tsig.keys";
