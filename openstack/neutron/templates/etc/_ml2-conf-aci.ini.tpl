[ml2_aci]
sync_allocations =  {{.Values.aci.sync_allocations | default "True"}}
tenant_manager = hash_ring
tenant_ring_size = 60
tenant_items_managed = 1:60
tenant_prefix = {{required "A valid .Values.aci required!" .Values.aci.apic_tenant_name}}
support_remote_mac_clear = {{.Values.aci.support_remote_mac_clear | default "True"}}

polling_interval=60
sync_batch_size=15
prune_orphans=True

# Hostname:port list of APIC controllers
apic_hosts = {{required "A valid .Values.aci required!" .Values.aci.apic_hosts}}
apic_username = {{required "A valid .Values.aci required!" .Values.aci.apic_user}}
apic_password = {{required "A valid .Values.aci required!" .Values.aci.apic_password}}
apic_use_ssl = True
apic_application_profile = {{required "A valid .Values.aci required!" .Values.aci.apic_application_profile}}

{{required "A valid .Values.aci required!" .Values.aci.bindings}}