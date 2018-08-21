path_keywords:
    - blacklists
    - exports
    - floatingips
    - imports
    - limits
    - nameservers
    - pools
    - quotas
    - service_status: status
    - recordsets
    - tasks
    - tlds
    - transfer_accepts
    - transfer_requests
    - tsigkeys
    - zones

keyword_exclusions:
    - export

regex_path_mapping:
    - '\S+/reverse/floatingips/\S+:\S+$': 'reverse/floatingips/region/floatingip'
