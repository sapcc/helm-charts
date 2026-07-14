{
  "index_patterns": [
    "_DS_NAME_-datastream*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "{{ .Values.global.data_stream.logs.number_of_shards }}",
      "index.number_of_replicas": "1",
      "index.append_only.enabled": true,
      "index.refresh_interval": "{{ .Values.global.data_stream.logs.refresh_interval }}"
      "index.translog.sync_interval": "{{ .Values.global.data_stream.logs.refresh_interval }}",
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
        }
      ],
      "properties": {
        "resource": {
          "properties": {
            "k8s": {
              "properties": {
                "pod": {
                  "properties": {
                    "name": {
                      "type": "keyword",
                      "fields": {
                        "text": { "type": "text" }
                      }
                    }
                  }
                },
                "container": {
                  "properties": {
                    "name": {
                      "type": "keyword",
                      "fields": {
                        "text": { "type": "text" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
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
