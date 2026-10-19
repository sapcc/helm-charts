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
      ],
      "properties": {
        "resource": {
          "properties": {
            "k8s": {
              "properties": {
                "cluster": {
                  "properties": {
                    "uid": { "type": "keyword", "fields": { "text": { "type": "text" } } }
                  }
                },
                "container": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "restart_count": { "type": "keyword" }
                  }
                },
                "cronjob": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } }
                  }
                },
                "daemonset": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "uid": { "type": "keyword" }
                  }
                },
                "deployment": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "uid": { "type": "keyword" }
                  }
                },
                "job": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "uid": { "type": "keyword" }
                  }
                },
                "namespace": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } }
                  }
                },
                "node": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "uid": { "type": "keyword" }
                  }
                },
                "object": {
                  "properties": {
                    "api_version": { "type": "keyword" },
                    "fieldpath": { "type": "keyword" },
                    "kind": { "type": "keyword" },
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "resource_version": { "type": "keyword" },
                    "uid": { "type": "keyword" }
                  }
                },
                "pod": {
                  "properties": {
                    "ip": { "type": "keyword" },
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "start_time": { "type": "date" },
                    "uid": { "type": "keyword" }
                  }
                },
                "replicaset": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "uid": { "type": "keyword" }
                  }
                },
                "statefulset": {
                  "properties": {
                    "name": { "type": "keyword", "fields": { "text": { "type": "text" } } },
                    "uid": { "type": "keyword" }
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
