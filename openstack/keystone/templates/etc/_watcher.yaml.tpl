custom_actions:
  users:
    - method: GET
      action_type: read/list

    - user:
        - groups:
            - method: GET
              action_type: read/list

        - projects:
            - method: GET
              action_type: read/list

        - application_credentials:
            - method: GET
              action_type: read/list

  credentials:
    - method: GET
      action_type: read/list

  domains:
    - method: GET
      action_type: read/list

    - domain:
        - groups:
            - group:
                - roles:
                    - method: GET
                      action_type: read/list

        - users:
            - user:
                - roles:
                    - method: GET
                      action_type: read/list

  projects:
    - method: GET
      action_type: read/list

    - project:
        - tags:
            - method: GET
              action_type: read/list

        - groups:
            - group:
                - roles:
                    - method: GET
                      action_type: read/list

        - users:
            - user:
                - roles:
                    - method: GET
                      action_type: read/list

  regions:
    - method: GET
      action_type: read/list

  groups:
    - method: GET
      action_type: read/list

  role_assignments:
    - method: GET
      action_type: read/list

  policies:
    - method: GET
      action_type: read/list

  application_credentials:
    - method: GET
      action_type: read/list

  auth:
    - tokens:
        - OS-PKI:
            - revoked:
                - method: GET
                  action_type: read/list

  roles:
    - method: GET
      action_type: read/list

    - role:
        - implies:
            - method: GET
              action_type: read/list

  role_assignments:
    - method: GET
      action_type: read/list

  role_inferences:
    - method: GET
      action_type: read/list

  system:
    - users:
        - user:
            - roles:
                - method: GET
                  action_type: read/list

    - groups:
        - group:
            - roles:
                - method: GET
                  action_type: read/list

  services:
    - method: GET
      action_type: read/list

  endpoints:
    - method: GET
      action_type: read/list

  registered_limits:
    - method: GET
      action_type: read/list

  limits:
    - method: GET
      action_type: read/list

  OS-INHERIT:
    - domains:
        - domain:
            - users:
                - user:
                    - roles:
                        - inherited_to_projects:
                            - method: GET
                              action_type: read/list

            - groups:
                - group:
                    - roles:
                        - inherited_to_projects:
                            - method: GET
                              action_type: read/list
