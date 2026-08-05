{{- define "tls_hardening_conf" }}
# BSI TR-02102-2 compliant TLS settings

# Disable all protocols, then enable only TLS 1.2 and TLS 1.3
SSLProtocol -all +TLSv1.2 +TLSv1.3

# TLS 1.3 cipher suites (BSI TR-02102-2 SF.Eco.4)
SSLCipherSuite TLSv1.3 {{ .Values.tls.hardening.cipherSuitesTLS13 | default "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256" }}

# TLS 1.2 cipher suites (BSI TR-02102-2 SF.Eco.4, OpenSSL names)
SSLCipherSuite {{ .Values.tls.hardening.cipherSuitesTLS12 | default "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256" }}

SSLHonorCipherOrder on
SSLCompression off
SSLSessionTickets off

# ECDHE curve preference (BSI TR-02102-2 SF.Eco.3)
SSLOpenSSLConfCmd Curves {{ .Values.tls.hardening.ecdheCurves | default "brainpoolP256r1:brainpoolP384r1:prime256v1:secp384r1" }}
{{- end }}
