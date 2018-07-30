[ml2_aci]

tenant_manager   = hash_ring
tenant_ring_size =  60
tenant_items_managed =  1:60
tenant_prefix =  {{.Values.aci.apic_tenant_name}}

support_remote_mac_clear={{.Values.aci.support_remote_mac_clear  | default "True"}}

polling_interval=60
sync_batch_size=15
prune_orphans=True

# Hostname:port list of APIC controllers
apic_hosts = {{.Values.aci.apic_hosts}}

apic_username = {{.Values.aci.apic_user}}

# Password for the APIC controller
apic_password = {{.Values.aci.apic_password}}

# Whether use SSl for connecting to the APIC controller or not
apic_use_ssl = True

apic_application_profile = {{.Values.aci.apic_application_profile}}

{{.Values.aci.bindings}}