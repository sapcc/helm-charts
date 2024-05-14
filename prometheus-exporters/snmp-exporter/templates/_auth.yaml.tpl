auths:
{{- if .Values.snmp_exporter.arista.enabled }}
  aas_v3:
    version: {{ .Values.snmp_exporter.arista.snmpv3.version }}
    security_level: {{ .Values.snmp_exporter.arista.snmpv3.security_level }}
    username: ${ARISTA_V3_USERNAME}
    password: ${ARISTA_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.arista.snmpv3.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.arista.snmpv3.priv_protocol }}
    priv_password: ${ARISTA_V3_PRIV_PASSWORD}
  ams_v3:
    version: {{ .Values.snmp_exporter.arista.snmpv3.version }}
    security_level: {{ .Values.snmp_exporter.arista.snmpv3.security_level }}
    username: ${ARISTA_V3_USERNAME}
    password: ${ARISTA_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.arista.snmpv3.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.arista.snmpv3.priv_protocol }}
    priv_password: ${ARISTA_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.asa.enabled }}
  asa_v3:
    version: {{ .Values.snmp_exporter.asa.version }}
    security_level: {{ .Values.snmp_exporter.asa.security_level }}
    username: ${ASA_V3_USERNAME}
    password: ${ASA_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.asa.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.asa.priv_protocol }}
    priv_password: ${ASA_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.asr.enabled }}
  asr_v3:
    version: {{ .Values.snmp_exporter.asr.version }}
    security_level: {{ .Values.snmp_exporter.asr.security_level }}
    username: ${ASR_V3_USERNAME}
    password: ${ASR_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.asr.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.asr.priv_protocol }}
    priv_password: ${ASR_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.f5.enabled }}
  f5_v3:
    version: {{ .Values.snmp_exporter.f5.version }}
    security_level: {{ .Values.snmp_exporter.f5.security_level }}
    username: ${F5_V3_USERNAME}
    password: ${F5_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.f5.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.f5.priv_protocol }}
    priv_password: ${F5_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.asr03.enabled }}
  asr03_v3:
    version: {{ .Values.snmp_exporter.asr03.version }}
    security_level: {{ .Values.snmp_exporter.asr03.security_level }}
    username: ${ASR03_V3_USERNAME}
    password: ${ASR03_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.asr03.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.asr03.priv_protocol }}
    priv_password: ${ASR03_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.coreasr9k.enabled }}
  coreasr9k_v3:
    version: {{ .Values.snmp_exporter.coreasr9k.version }}
    security_level: {{ .Values.snmp_exporter.coreasr9k.security_level }}
    username: ${COREASR9K_V3_USERNAME}
    password: ${COREASR9K_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.coreasr9k.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.coreasr9k.priv_protocol }}
    priv_password: ${COREASR9K_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.n3k.enabled }}
  n3k_v3:
    version: {{ .Values.snmp_exporter.n3k.version }}
    security_level: {{ .Values.snmp_exporter.n3k.security_level }}
    username: ${N3K_V3_USERNAME}
    password: ${N3K_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.n3k.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.n3k.priv_protocol }}
    priv_password: ${N3K_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.pxgeneric.enabled }}
  pxgeneric_v3:
    version: {{ .Values.snmp_exporter.pxgeneric.version }}
    security_level: {{ .Values.snmp_exporter.pxgeneric.security_level }}
    username: ${PXGENERIC_V3_USERNAME}
    password: ${PXGENERIC_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.pxgeneric.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxgeneric.priv_protocol }}
    priv_password: ${PXGENERIC_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.pxdlroutergeneric.enabled }}
  pxdlroutergeneric_v3:
    version: {{ .Values.snmp_exporter.pxdlroutergeneric.version }}
    security_level: {{ .Values.snmp_exporter.pxdlroutergeneric.security_level }}
    username: ${PXDLROUTERGENERIC_V3_USERNAME}
    password: ${PXDLROUTERGENERIC_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.pxdlroutergeneric.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxdlroutergeneric.priv_protocol }}
    priv_password: ${PXDLROUTERGENERIC_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.pxdlrouteriosxe.enabled }}
  pxdlrouteriosxe_v3:
    version: {{ .Values.snmp_exporter.pxdlrouteriosxe.version }}
    security_level: {{ .Values.snmp_exporter.pxdlrouteriosxe.security_level }}
    username: ${PXDLROUTERIOSXE_V3_USERNAME}
    password: ${PXDLROUTERIOSXE_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxe.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxe.priv_protocol }}
    priv_password: ${PXDLROUTERIOSXE_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.pxdlrouteriosxr.enabled }}
  pxdlrouteriosxr_v3:
    version: {{ .Values.snmp_exporter.pxdlrouteriosxr.version }}
    security_level: {{ .Values.snmp_exporter.pxdlrouteriosxr.security_level }}
    username: ${PXDLROUTERIOSXR_V3_USERNAME}
    password: ${PXDLROUTERIOSXR_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxr.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.pxdlrouteriosxr.priv_protocol }}
    priv_password: ${PXDLROUTERIOSXR_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.acileaf.enabled }}
  acileaf_v3:
    version: {{ .Values.snmp_exporter.acileaf.version }}
    security_level: {{ .Values.snmp_exporter.acileaf.security_level }}
    username: ${ACILEAF_V3_USERNAME}
    password: ${ACILEAF_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.acileaf.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.acileaf.priv_protocol }}
    priv_password: ${ACILEAF_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.n9kpx.enabled }}
  n9kpx_v3:
    version: {{ .Values.snmp_exporter.n9kpx.version }}
    security_level: {{ .Values.snmp_exporter.n9kpx.security_level }}
    username: ${N9KPX_V3_USERNAME}
    password: ${N9KPX_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.n9kpx.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.n9kpx.priv_protocol }}
    priv_password: ${N9KPX_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.ipn.enabled }}
  ipn_v3:
    version: {{ .Values.snmp_exporter.ipn.version }}
    security_level: {{ .Values.snmp_exporter.ipn.security_level }}
    username: ${IPN_V3_USERNAME}
    password: ${IPN_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.ipn.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.ipn.priv_protocol }}
    priv_password: ${IPN_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.acispine.enabled }}
  acispine_v3:
    version: {{ .Values.snmp_exporter.acispine.version }}
    security_level: {{ .Values.snmp_exporter.acispine.security_level }}
    username: ${ACISPINE_V3_USERNAME}
    password: ${ACISPINE_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.acispine.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.acispine.priv_protocol }}
    priv_password: ${ACISPINE_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.acistretch.enabled }}
  acistretch_v2:
    version: {{ .Values.snmp_exporter.acistretch.version }}
    community: ACISTRETCH_V2_COMMUNITY
{{- end }}
{{- if .Values.snmp_exporter.ucs.enabled }}
  ucs_v3:
    version: {{ .Values.snmp_exporter.ucs.version }}
    security_level: {{ .Values.snmp_exporter.ucs.security_level }}
    username: ${UCS_V3_USERNAME}
    password: ${UCS_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.ucs.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.ucs.priv_protocol }}
    priv_password: ${UCS_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.hsm.enabled }}
  hsm_v3:
    version: {{ .Values.snmp_exporter.hsm.version }}
    security_level: {{ .Values.snmp_exporter.hsm.security_level }}
    username: ${HSM_V3_USERNAME}
    password: ${HSM_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.hsm.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.hsm.priv_protocol }}
    priv_password: ${HSM_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.aristaevpn.enabled }}
  aristaevpn_v3:
    version: {{ .Values.snmp_exporter.aristaevpn.version }}
    security_level: {{ .Values.snmp_exporter.aristaevpn.security_level }}
    username: ${ARISTAEVPN_V3_USERNAME}
    password: ${ARISTAEVPN_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.aristaevpn.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.aristaevpn.priv_protocol }}
    priv_password: ${ARISTAEVPN_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.fortinet.enabled }}
  fortinet_v3:
    version: {{ .Values.snmp_exporter.fortinet.version }}
    security_level: {{ .Values.snmp_exporter.fortinet.security_level }}
    username: ${FORTINET_V3_USERNAME}
    password: ${FORTINET_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.fortinet.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.fortinet.priv_protocol }}
    priv_password: ${FORTINET_V3_PRIV_PASSWORD}
{{- end }}
{{- if .Values.snmp_exporter.aristaspine.enabled }}
  aristaspine_v3:
    version: {{ .Values.snmp_exporter.aristaspine.version }}
    security_level: {{ .Values.snmp_exporter.aristaspine.security_level }}
    username: ${ARISTASPINE_V3_USERNAME}
    password: ${ARISTASPINE_V3_PASSWORD}
    auth_protocol: {{ .Values.snmp_exporter.aristaspine.auth_protocol }}
    priv_protocol: {{ .Values.snmp_exporter.aristaspine.priv_protocol }}
    priv_password: ${ARISTASPINE_V3_PRIV_PASSWORD}
{{- end }}
