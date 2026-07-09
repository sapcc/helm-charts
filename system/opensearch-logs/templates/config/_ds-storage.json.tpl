{
  "index_patterns": [
    "_DS_NAME_-datastream*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "{{ .Values.global.data_stream.storage.number_of_shards }}",
      "index.number_of_replicas": "1",
      "index.append_only.enabled": true,
      "index.refresh_interval": "{{ .Values.global.data_stream.storage.refresh_interval }}",
      "index.translog.sync_interval": "{{ .Values.global.data_stream.storage.refresh_interval }}",
      "index.translog.durability": "async"
    },
    "mappings": {
      "dynamic_templates": [
        {
          "resource_strings_as_keyword": {
            "path_match": "resource.*",
            "match_mapping_type": "string",
            "mapping": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        {
          "attributes_strings_as_keyword": {
            "path_match": "attributes.*",
            "match_mapping_type": "string",
            "mapping": {
              "type": "keyword",
              "ignore_above": 256
            }
          }
        },
        {
          "attributes_long_as_float": {
            "path_match": "attributes.*",
            "match_mapping_type": "long",
            "mapping": {
              "type": "float",
              "ignore_malformed": true
            }
          }
        },
        {
          "attributes_double_as_float": {
            "path_match": "attributes.*",
            "match_mapping_type": "double",
            "mapping": {
              "type": "float",
              "ignore_malformed": true
            }
          }
        }
      ]
    },
    "aliases": {
      "_DS_NAME_-ds": {}
    }
  },
  "composed_of": [],
  "priority": "0",
  "_meta": {
    "flow": "simple"
  },
  "data_stream": {
    "timestamp_field": {
      "name": "@timestamp"
    }
  }
}
