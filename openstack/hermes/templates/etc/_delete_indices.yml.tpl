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
      Delete closed indices older than 12 months. The oldest
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
    - filtertype: age
      source: name
      direction: older
      timestring: '%Y.%m'
      unit: months
      unit_count: 12
    - filtertype: kibana
      exclude: True
