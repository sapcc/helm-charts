{{/*
Apache TLS protocol hardening configuration.
Configures TLS 1.3/1.2 with compliant cipher suites, PFS, AEAD modes,
and brainpool curve preference. Shared between Keystone and Barbican.
*/}}

# TLS Protocol Versions: only 1.3 and 1.2
SSLProtocol -all +TLSv1.3 +TLSv1.2

# TLS 1.2 Cipher Suites (ECDHE + AEAD only, PFS required)
SSLCipherSuite ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256

# TLS 1.3 Cipher Suites
SSLCipherSuite TLSv1.3 TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256

# Server chooses cipher order
SSLHonorCipherOrder on

# ECDHE Curve Preference: brainpool first, NIST as fallback
SSLOpenSSLConfCmd Curves brainpoolP256r1:brainpoolP384r1:prime256v1:secp384r1

# Signature algorithms preference
SSLOpenSSLConfCmd SignatureAlgorithms ecdsa_secp256r1_sha256:ecdsa_secp384r1_sha384:rsa_pss_rsae_sha256:rsa_pss_rsae_sha384

# Session cache
SSLSessionCache shmcb:/run/apache2/ssl_scache(512000)
SSLSessionCacheTimeout 300

# Disable session tickets (for PFS)
SSLSessionTickets off

# Strict SNI
SSLStrictSNIVHostCheck on
