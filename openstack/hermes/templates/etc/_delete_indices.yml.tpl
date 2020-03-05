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
      timeout_override: 300
      continue_if_exception: False
      disable_action: False
    filters:
    - filtertype: pattern
      kind: prefix
      value: .kibana
      exclude: True
    - filtertype: pattern
      kind: prefix
      value: .task
      exclude: True
    - filtertype: space
      disk_space: {{required ".Values.hermes_elasticsearch_data_retention" .Values.hermes_elasticsearch_data_retention}}
      use_age: True
      source: creation_date
      exclude:
    - filtertype: kibana
      exclude: True
  2:
    action: close
    description: >-
      Close indices older than 4 months
    options:
      ignore_empty_list: True
      timeout_override: 300
      continue_if_exception: False
      disable_action: False
    filters:
    - filtertype: pattern
      kind: prefix
      value: audit-
    - filtertype: age
      source: name
      direction: older
      timestring: '%Y.%m'
      unit: months
      unit_count: 4
  3:
    action: open
    description: >-
      Open indices audit- prefixed indices. Off, this is to recover.
    options:
      ignore_empty_list: True
      timeout_override: 300
      continue_if_exception: False
      disable_action: True
    filters:
    - filtertype: pattern
      kind: prefix
      value: audit-
    - filtertype: age
      source: name
      direction: younger
      timestring: '%Y.%m'
      unit: months
      unit_count: 6
