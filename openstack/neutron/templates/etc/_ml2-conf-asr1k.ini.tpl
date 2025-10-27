# Defines configuration options specific for ASR1k ML2 Mechanism driver

[ml2_asr1k]
# The physical networks asr mechanism driver is responsible for
physical_networks = {{required "A valid .Values.asr.physnet required!" .Values.asr.physnet}}

