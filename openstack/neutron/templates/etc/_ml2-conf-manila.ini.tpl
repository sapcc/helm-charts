# Defines configuration options specific for manila ML2 Mechanism driver

[ml2_manila]
# The physical networks manila mechanism driver is responsible for
physical_networks = {{required "A valid .Values.manila.physnet required!" .Values.manila.physnet}}
