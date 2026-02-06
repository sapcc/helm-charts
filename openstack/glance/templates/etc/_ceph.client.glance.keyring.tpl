[client.glance]
key = {{ .Values.ceph.keyring.key }}
caps mon = "allow r"
caps osd = "allow rwx pool=rbd-region-premium"
