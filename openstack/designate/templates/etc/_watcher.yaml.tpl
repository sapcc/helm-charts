custom_actions:
  zones:
    - method: GET
      action_type: read/list

    - tasks:
        - imports:
            - method: GET
              action_type: read/list

        - transfer_requests:
            - method: GET
              action_type: read/list

        - transfer_accepts:
            - method: GET
              action_type: read/list

    - zone:
        - tasks:
            - imports:
                - method: GET
                  action_type: read/list

            - exports:
                - method: GET
                  action_type: read/list

        - recordsets:
            - method: GET
              action_type: read/list

        - nameservers:
            - method: GET
              action_type: read/list

  recordsets:
    - method: GET
      action_type: read/list

  pools:
    - method: GET
      action_type: read/list

  tlds:
    - method: GET
      action_type: read/list

  tsigkeys:
    - method: GET
      action_type: read/list

  blacklists:
    - method: GET
      action_type: read/list

  service_status:
    - method: GET
      action_type: read/list

  reverse:
    - floatingips:
        - method: GET
          action_type: read/list
