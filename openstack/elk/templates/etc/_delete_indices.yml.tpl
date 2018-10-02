---
# Remember, leave a key empty if there is no value.  None will be a string,
# not a Python "NoneType"
#
# Also remember that all examples have 'disable_action' set to True.  If you
# want to use this action as a template, be sure to set this to False after
# copying it.
actions:
  1:
    action: delete_indices
    description: >-
      Delete indices so that we stay below {{.Values.elk_elasticsearch_data_retention_space}}
      gb of used disk space for indices (total summed up over all data nodes). The oldest
      indices will be deleted first. Ignore the error if the filter does not result in an
      actionable list of indices (ignore_empty_list) and exit cleanly.
    options:
      ignore_empty_list: True
      timeout_override:
      continue_if_exception: False
      disable_action: False
    filters:
    - filtertype: pattern
      kind: regex
      value: '^.*-.*$'
      exclude:
    - filtertype: space
      disk_space: {{.Values.elk_elasticsearch_data_retention_space}}
      use_age: True
      source: creation_date
      exclude:
  2:
    action: delete_indices
    description: >-
      Delete indices older than {{.Values.elk_elasticsearch_data_retention_time}} days (based on index name).
      Ignore the error if the filter does not result in an
      actionable list of indices (ignore_empty_list) and exit cleanly.
    options:
      ignore_empty_list: True
      timeout_override:
      continue_if_exception: False
      disable_action: False
    filters:
    - filtertype: pattern
      kind: prefix
      value: '^.*-.*$'
      exclude:
    - filtertype: age
      source: name
      direction: older
      timestring: '%Y.%m.%d'
      unit: days
      unit_count: {{.Values.elk_elasticsearch_data_retention_time}}
      exclude:
