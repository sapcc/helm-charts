# metadata_agent.ini
[DEFAULT]
metadata_proxy_shared_secret = {{required "A valid .Values.global.nova_metadata_secret required!" .Values.global.nova_metadata_secret}}
