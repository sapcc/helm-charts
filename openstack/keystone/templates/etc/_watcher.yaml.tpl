path_keywords:
  - application_credentials
  - credentials
  - domains
  - ec2tokens
  - endpoints
  - groups
  - implies
  - inherited_to_projects
  - limits
  - policies
  - projects
  - regions
  - registered_limits
  - role_assignments
  - role_inferences
  - roles
  - s3tokens
  - services
  - tags
  - tokens
  - users

# never replace these
keyword_exclusions:
  - config
  - OS-PKI
  - model


regex_path_mapping:
  - '\S+/domains/config/[0-9a-zA-Z_]+/default$': 'domains/config/group/default'
  - '\S+/domains/config/[0-9a-zA-Z_]+/[0-9a-zA-Z_]+/default$': 'domains/config/group/option/default'
  - '\S+/domains/\S+/config/[0-9a-zA-Z_]+/[0-9a-zA-Z_]+$': 'domains/domain/config/group/option'
  - '\S+/domains/\S+/config/[0-9a-zA-Z_]+$': 'domains/domain/config/group'

custom_actions:
  auth:
    - tokens:
        - OS-PKI:
            - revoked:
                - method: GET
                  action_type: read/list
