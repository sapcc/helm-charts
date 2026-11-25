[ml2_aci]
apic_username = {{required "A valid .Values.aci required!" .Values.aci.apic_user | include "resolve_secret" }}
apic_password = {{required "A valid .Values.aci required!" .Values.aci.apic_password | include "resolve_secret" }}
