{{- define "volume_vmware_conf" -}}
{{- $context := index . 0 -}}
{{- $volume := index . 1 -}}

[DEFAULT]
enabled_backends = vmware
storage_availability_zone={{$volume.availability_zone}}

[vmware]
volume_backend_name = vmware
volume_driver = cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver
vmware_host_ip = {{$volume.host}}
vmware_host_username = {{$volume.username | replace "$" "$$"}}
vmware_host_password = {{$volume.password | replace "$" "$$"}}
vmware_insecure = True
vmware_storage_profile = cinder-vvol
{{ if .Values.image_cache.enabled -}}
image_volume_cache_enabled = True
image_volume_cache_max_size_gb = {{.Values.image_cache.max_size_gb}}
image_volume_cache_max_count = {{.Values.image_cache.max_count}}
{{- end -}}
{{- end -}}
