# TLS Protocol Hardening for BSI Certification
# WP-1196: Apache TLS Protocol Hardening

{{- define "tls_hardening_conf" }}
# =============================================================================
# TLS Protocol Configuration
# BSI TR-02102-2 compliant settings
# =============================================================================

# Disable all protocols, then enable only TLS 1.2 and TLS 1.3
SSLProtocol -all +TLSv1.2 +TLSv1.3

# =============================================================================
# Cipher Suite Configuration
# Using OpenSSL cipher names (not BSI TLS_AKE names per WP-1209)
# =============================================================================

# TLS 1.3 cipher suites (BSI TR-02102-2 compliant per SF.Eco.4)
# Only TLS_AES_256_GCM_SHA384 and TLS_CHACHA20_POLY1305_SHA256 per spec
SSLCipherSuite TLSv1.3 {{ .Values.tls.hardening.cipherSuitesTLS13 | default "TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256" }}

# TLS 1.2 cipher suites (BSI TR-02102-2 compliant per SF.Eco.4, OpenSSL names)
# Includes both ECDSA and RSA variants for certificate flexibility
SSLCipherSuite {{ .Values.tls.hardening.cipherSuitesTLS12 | default "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256" }}

# =============================================================================
# Additional Security Settings
# =============================================================================

# Server determines cipher order (not client)
SSLHonorCipherOrder on

# Disable SSL compression (CRIME attack mitigation)
SSLCompression off

# Disable session tickets (for perfect forward secrecy)
SSLSessionTickets off

# ECDHE curve preference order (BSI TR-02102-2 compliant per SF.Eco.3)
# Order: brainpoolP256r1 > brainpoolP384r1 > prime256v1 > secp384r1
SSLOpenSSLConfCmd Curves {{ .Values.tls.hardening.ecdheCurves | default "brainpoolP256r1:brainpoolP384r1:prime256v1:secp384r1" }}

# =============================================================================
# OCSP Stapling (optional, improves performance)
# =============================================================================
# SSLUseStapling on
# SSLStaplingCache "shmcb:logs/ssl_stapling(32768)"

# =============================================================================
# Security Headers (if not handled by ingress)
# =============================================================================
# Uncomment if HSTS should be set at Apache level
# Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
{{- end }}
