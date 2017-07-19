sample values file entry:

vcenter_exporter:
  enabled: True
  image_version: somedockerimageversion
  shorter_names_regex: '\.name\..*\.company\.com'
  docker_repo: dockerrepo/image
  maia_vcenter_config:
    - name: vcenter-1
      vcenter_ip: vcenter-1.hostname
      username: someuser1
      password: somepass1
      availability_zone: somezone1
    - name: vcenter-1
      vcenter_ip: vcenter-2.hostname
      username: someuser2
      password: somepass2
      availability_zone: somezone2

the file vcenter-metrics.txt contains a (incomplete) list of metrics, which might be obtained this way. this list should just give a rough idea about them, as it is not complete and might depend on the config of the vecenters and actual hardware as well.
