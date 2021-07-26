[swift-hash]
swift_hash_path_prefix = { fromEnv: HASH_PATH_PREFIX }
swift_hash_path_suffix = { fromEnv: HASH_PATH_SUFFIX }

[storage-policy:0]
name = default
default = yes

[swift-constraints]
max_header_size = {{ .Values.max_header_size }}
