custom_actions:
  extensions:
    - method: GET
      action_type: read/list

  limits:
    - method: GET
      action_type: read/list

  shares:
    - method: GET
      action_type: read/list

    - share:
        export_locations:
          - method: GET
            action_type: read/list

  snapshots:
    - method: GET
      action_type: read/list

  snapshot-instances:
    - method: GET
      action_type: read/list

  share-networks:
    - method: GET
      action_type: read/list

  security-services:
    - method: GET
      action_type: read/list

  share-servers:
    - method: GET
      action_type: read/list

  share_instances:
    - method: GET
      action_type: read/list

    - share_instance:
        - export_locations:
            - method: GET
              action_type: read/list

  types:
    - method: GET
      action_type: read/list

    - default:
        - method: GET
          action_type: read/list

  scheduler-stats:
    pools:
      - method: GET
        action_type: read/list

  services:
    - method: GET
      action_type: read/list

  availability-zones:
    - method: GET
      action_type: read/list

  messages:
    - method: GET
      action_type: read/list

  share-replicas:
    - method: GET
      action_type: read/list

  share_groups:
    - method: GET
      action_type: read/list

  share-group-types:
    - method: GET
      action_type: read/list

  share-group-snapshots:
    - method: GET
      action_type: read/list
