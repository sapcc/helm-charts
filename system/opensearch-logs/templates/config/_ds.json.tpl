{
  "index_patterns": [
    "_DS_NAME_-datastream*"
  ],
  "template": {
    "settings": {
      "index.number_of_shards": "4",
      "index.number_of_replicas": "1",
      "index.append_only.enabled": true,
      "index.refresh_interval": "60s"
    },
    "mappings": {
      "properties": {
        "resource": {
          "type": "object",
          "properties": {
            "k8s": {
              "type": "object",
              "properties": {
                "pod": {
                  "type": "object",
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
                  "type": "object",
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
