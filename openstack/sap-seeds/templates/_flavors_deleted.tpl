# Removed flavors are kept _private_ ("is_public: false") in here instead of
# actually deleting them to allow management of old instances with these
# flavors.

# To query if one or more flavors are still in use run the following query in
# the "nova" DB (replace $FLAVOR with the flavor name(s)) of every region:
#
#   SELECT
#       i2.project_id,
#       i2.created_at,
#       i2.uuid,
#       i2.host,
#       i2.hostname AS name,
#       j1.flavor
#   FROM instances AS i2
#   JOIN (
#       SELECT
#           instance_uuid,
#           json_value(flavor, '$.cur."nova_object.data".name') AS flavor
#       FROM instance_extra AS ie
#       JOIN (SELECT uuid FROM instances WHERE deleted = 0) AS i
#       ON i.uuid = ie.instance_uuid
#   ) AS j1
#   ON j1.instance_uuid = i2.uuid
#   WHERE flavor in ('$FLAVOR');

- name: "m5.192xlarge"
  id: "271"
  vcpus: 106
  ram: 2979840
  disk: 64
  is_public: false
  extra_specs:
{{- if .Values.use_hana_exclusive }}
    {{- tuple . "vmware_hana_exclusive" | include "sap_seeds.helpers.flavor_extra_specs" | indent 4 }}
    "trait:CUSTOM_NUMASIZE_C48_M729": "required"
{{- else }}
    {{- tuple . "vmware_common" | include "sap_seeds.helpers.extra_specs" | indent 4 }}
    "resources:CUSTOM_BIGVM": "2"
    "host_fraction": "1,1/2"
{{- end }}
