#!/bin/bash
set -ex

utimaco ()
{
    cp -a /opt/utimaco/. /utimaco/
    mv /etc/utimaco/cs_pkcs11_R3.cfg /utimaco
    chmod -R a+rX /utimaco
}

utimaco
