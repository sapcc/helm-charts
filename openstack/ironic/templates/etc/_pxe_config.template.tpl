{{- define "pxe_config_template" }}
{{- $conductor := index . 1 }}
{{- with index . 0 }}
{{- $prefix := or (and (eq "lpxelinux.0" $conductor.pxe.pxe_bootfile_name) (printf "http://%v:%v/" .Values.global.ironic_tftp_ip .Values.conductor.deploy.port)) "" -}}
default deploy

label deploy
kernel {{$prefix}}{{"{{"}} pxe_options.deployment_aki_path {{"}}"}}
append initrd={{$prefix}}{{"{{"}} pxe_options.deployment_ari_path {{"}}"}} selinux=0 troubleshoot=0 text
ipappend 3


label boot_partition
kernel {{$prefix}}{{"{{"}} pxe_options.aki_path {{"}}"}}
append initrd={{$prefix}}{{"{{"}} pxe_options.ari_path {{"}}"}} root={{"{{"}} ROOT {{"}}"}} ro text


label boot_whole_disk
COM32 chain.c32
append mbr:{{"{{"}} DISK_IDENTIFIER {{"}}"}}


label trusted_boot
kernel mboot
append tboot.gz --- {{$prefix}}{{"{{"}}pxe_options.aki_path{{"}}"}} root={{"{{"}} ROOT {{"}}"}} ro text intel_iommu=on --- {{$prefix}}{{"{{"}}pxe_options.ari_path{{"}}"}}
{{- end }}
{{- end }}
