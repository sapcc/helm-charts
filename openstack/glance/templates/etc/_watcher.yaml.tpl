custom_actions:
  images:
    - method: GET
      action_type: read/list

    - image:
        - members:
            - method: POST
              action_type: update
            - method: GET
              action_type: read/list

  shared-images:
    member:
      - method: GET
        action_type: read/list

  tasks:
    - method: GET
      action_type: read/list