#!/bin/bash
set -euo pipefail
set -x

echo "[utimaco] starting setup"
mkdir -p /utimaco

if [ -d /opt/utimaco ]; then
  echo "[utimaco] copying /opt/utimaco -> /utimaco"
  cp -a /opt/utimaco/. /utimaco/
else
  echo "[utimaco][WARN] /opt/utimaco not found"
fi

if [ -f /etc/utimaco/cs_pkcs11_R3.cfg ]; then
  echo "[utimaco] copying cs_pkcs11_R3.cfg -> /utimaco"
  cp -a /etc/utimaco/cs_pkcs11_R3.cfg /utimaco/
else
  echo "[utimaco][WARN] config not found"
fi

chmod -R a+rX /utimaco || true
echo "[utimaco] final contents:"
ls -la /utimaco || true
