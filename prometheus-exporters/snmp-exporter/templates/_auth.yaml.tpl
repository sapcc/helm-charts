auths:
{{- if .Values.snmp_exporter.arista.enabled }}
  aas_v3:
    version: {{ .Values.snmp_exporter.arista.snmpv3.version }}
    security_level: {{ .Values.snmp_exporter.arista.snmpv3.security_level }}
    username: {{ .Values.snmp_exporter.arista.snmpv3.username }}
    password: {{ .Values.snmp_exporter.arista.snmpv3.password }}
    auth_protocol: {{ .Values.snmp_exporter.arista.snmpv3.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.arista.snmpv3.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.arista.snmpv3.priv_password }}
  ams_v3:
    version: {{ .Values.snmp_exporter.arista.snmpv3.version }}
    security_level: {{ .Values.snmp_exporter.arista.snmpv3.security_level }}
    username: {{ .Values.snmp_exporter.arista.snmpv3.username }}
    password: {{ .Values.snmp_exporter.arista.snmpv3.password }}
    auth_protocol: {{ .Values.snmp_exporter.arista.snmpv3.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.arista.snmpv3.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.arista.snmpv3.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.asa.enabled }}
  asa_v3:
    version: {{ .Values.snmp_exporter.asa.version }}
    security_level: {{ .Values.snmp_exporter.asa.security_level }}
    username: {{ .Values.snmp_exporter.asa.username }}
    password: {{ .Values.snmp_exporter.asa.password }}
    auth_protocol: {{ .Values.snmp_exporter.asa.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.asa.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.asa.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.asr.enabled }}
  asr_v3:
    version: {{ .Values.snmp_exporter.asr.version }}
    security_level: {{ .Values.snmp_exporter.asr.security_level }}
    username: {{ .Values.snmp_exporter.asr.username }}
    password: {{ .Values.snmp_exporter.asr.password }}
    auth_protocol: {{ .Values.snmp_exporter.asr.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.asr.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.asr.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.f5.enabled }}
  f5_v3:
    version: {{ .Values.snmp_exporter.f5.version }}
    security_level: {{ .Values.snmp_exporter.f5.security_level }}
    username: {{ .Values.snmp_exporter.f5.username }}
    password: {{ .Values.snmp_exporter.f5.password }}
    auth_protocol: {{ .Values.snmp_exporter.f5.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.f5.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.f5.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.asr03.enabled }}
  asr03_v3:
    version: {{ .Values.snmp_exporter.asr03.version }}
    security_level: {{ .Values.snmp_exporter.asr03.security_level }}
    username: {{ .Values.snmp_exporter.asr03.username }}
    password: {{ .Values.snmp_exporter.asr03.password }}
    auth_protocol: {{ .Values.snmp_exporter.asr03.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.asr03.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.asr03.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.coreasr9k.enabled }}
  coreasr9k_v3:
    version: {{ .Values.snmp_exporter.coreasr9k.version }}
    security_level: {{ .Values.snmp_exporter.coreasr9k.security_level }}
    username: {{ .Values.snmp_exporter.coreasr9k.username }}
    password: {{ .Values.snmp_exporter.coreasr9k.password }}
    auth_protocol: {{ .Values.snmp_exporter.coreasr9k.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.coreasr9k.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.coreasr9k.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.n3k.enabled }}
  n3k_v3:
    version: {{ .Values.snmp_exporter.n3k.version }}
    security_level: {{ .Values.snmp_exporter.n3k.security_level }}
    username: {{ .Values.snmp_exporter.n3k.username }}
    password: {{ .Values.snmp_exporter.n3k.password }}
    auth_protocol: {{ .Values.snmp_exporter.n3k.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.n3k.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.n3k.priv_password }}
    version: {{ .Values.snmp_exporter.n3k.version }}
    community: {{ .Values.snmp_exporter.n3k.community }}
{{- end }}
{{- if .Values.snmp_exporter.pxgeneric.enabled }}
  pxgeneric_v3:
    version: {{ .Values.snmp_exporter.pxgeneric.version }}
    security_level: {{ .Values.snmp_exporter.pxgeneric.security_level }}
    username: {{ .Values.snmp_exporter.pxgeneric.username }}
    password: {{ .Values.snmp_exporter.pxgeneric.password }}
    auth_protocol: {{ .Values.snmp_exporter.pxgeneric.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxgeneric.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.pxgeneric.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.pxdlroutergeneric.enabled }}
  pxdlroutergeneric_v3:
    version: {{ .Values.snmp_exporter.pxdlroutergeneric.version }}
    security_level: {{ .Values.snmp_exporter.pxdlroutergeneric.security_level }}
    username: {{ .Values.snmp_exporter.pxdlroutergeneric.username }}
    password: {{ .Values.snmp_exporter.pxdlroutergeneric.password }}
    auth_protocol: {{ .Values.snmp_exporter.pxdlroutergeneric.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxdlroutergeneric.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.pxdlroutergeneric.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.pxdlrouteriosxe.enabled }}
  pxdlrouteriosxe_v3:
    version: {{ .Values.snmp_exporter.pxdlrouteriosxe.version }}
    security_level: {{ .Values.snmp_exporter.pxdlrouteriosxe.security_level }}
    username: {{ .Values.snmp_exporter.pxdlrouteriosxe.username }}
    password: {{ .Values.snmp_exporter.pxdlrouteriosxe.password }}
    auth_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxe.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxe.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.pxdlrouteriosxe.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.pxdlrouteriosxr.enabled }}
  pxdlrouteriosxr_v3:
    version: {{ .Values.snmp_exporter.pxdlrouteriosxr.version }}
    security_level: {{ .Values.snmp_exporter.pxdlrouteriosxr.security_level }}
    username: {{ .Values.snmp_exporter.pxdlrouteriosxr.username }}
    password: {{ .Values.snmp_exporter.pxdlrouteriosxr.password }}
    auth_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxr.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxr.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.pxdlrouteriosxr.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.acileaf.enabled }}
  acileaf_v3:
    version: {{ .Values.snmp_exporter.acileaf.version }}
    security_level: {{ .Values.snmp_exporter.acileaf.security_level }}
    username: {{ .Values.snmp_exporter.acileaf.username }}
    password: {{ .Values.snmp_exporter.acileaf.password }}
    auth_protocol: {{ .Values.snmp_exporter.acileaf.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.acileaf.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.acileaf.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.n9kpx.enabled }}
  n9kpx_v3:
    version: {{ .Values.snmp_exporter.n9kpx.version }}
    security_level: {{ .Values.snmp_exporter.n9kpx.security_level }}
    username: {{ .Values.snmp_exporter.n9kpx.username }}
    password: {{ .Values.snmp_exporter.n9kpx.password }}
    auth_protocol: {{ .Values.snmp_exporter.n9kpx.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.n9kpx.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.n9kpx.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.ipn.enabled }}
  ipn_v3:
    version: {{ .Values.snmp_exporter.ipn.version }}
    security_level: {{ .Values.snmp_exporter.ipn.security_level }}
    username: {{ .Values.snmp_exporter.ipn.username }}
    password: {{ .Values.snmp_exporter.ipn.password }}
    auth_protocol: {{ .Values.snmp_exporter.ipn.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.ipn.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.ipn.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.acispine.enabled }}
  acispine_v3:
    version: {{ .Values.snmp_exporter.acispine.version }}
    security_level: {{ .Values.snmp_exporter.acispine.security_level }}
    username: {{ .Values.snmp_exporter.acispine.username }}
    password: {{ .Values.snmp_exporter.acispine.password }}
    auth_protocol: {{ .Values.snmp_exporter.acispine.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.acispine.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.acispine.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.acistretch.enabled }}
  acistretch_v2:
    version: {{ .Values.snmp_exporter.acistretch.version }}
    community: {{ .Values.snmp_exporter.acistretch.community }}
{{- end }}
{{- if .Values.snmp_exporter.ucs.enabled }}
  ucs_v3:
    version: {{ .Values.snmp_exporter.ucs.version }}
    security_level: {{ .Values.snmp_exporter.ucs.security_level }}
    username: {{ .Values.snmp_exporter.ucs.username }}
    password: {{ .Values.snmp_exporter.ucs.password }}
    auth_protocol: {{ .Values.snmp_exporter.ucs.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.ucs.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.ucs.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.hsm.enabled }}
  hsm_v3:
    version: {{ .Values.snmp_exporter.hsm.version }}
    security_level: {{ .Values.snmp_exporter.hsm.security_level }}
    username: {{ .Values.snmp_exporter.hsm.username }}
    password: {{ .Values.snmp_exporter.hsm.password }}
    auth_protocol: {{ .Values.snmp_exporter.hsm.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.hsm.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.hsm.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.aristaevpn.enabled }}
  aristaevpn_v3:
    version: {{ .Values.snmp_exporter.aristaevpn.version }}
    security_level: {{ .Values.snmp_exporter.aristaevpn.security_level }}
    username: {{ .Values.snmp_exporter.aristaevpn.username }}
    password: {{ .Values.snmp_exporter.aristaevpn.password }}
    auth_protocol: {{ .Values.snmp_exporter.aristaevpn.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.aristaevpn.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.aristaevpn.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.fortinet.enabled }}
  fortinet_v3:
    version: {{ .Values.snmp_exporter.fortinet.version }}
    security_level: {{ .Values.snmp_exporter.fortinet.security_level }}
    username: {{ .Values.snmp_exporter.fortinet.username }}
    password: {{ .Values.snmp_exporter.fortinet.password }}
    auth_protocol: {{ .Values.snmp_exporter.fortinet.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.fortinet.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.fortinet.priv_password }}
{{- end }}
{{- if .Values.snmp_exporter.aristaspine.enabled }}
  aristaspine_v3:
    version: {{ .Values.snmp_exporter.aristaspine.version }}
    security_level: {{ .Values.snmp_exporter.aristaspine.security_level }}
    username: {{ .Values.snmp_exporter.aristaspine.username }}
    password: {{ .Values.snmp_exporter.aristaspine.password }}
    auth_protocol: {{ .Values.snmp_exporter.aristaspine.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.aristaspine.priv_protocol }}
    priv_password: {{ .Values.snmp_exporter.aristaspine.priv_password }}
{{- end }}
