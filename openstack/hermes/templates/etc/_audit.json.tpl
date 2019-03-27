{
  "order": 0,
  "template": "audit-*",
  "settings": {
    "index": {
      "refresh_interval": "10s",
      "unassigned": {
        "node_left": {
          "delayed_timeout": "10m"
        }
      },
      "number_of_shards": "1",
      "number_of_replicas": "0"
    }
  },
  "mappings": {
    
    "dynamic_templates": [
      {
        "message_field": {
          "mapping": {
            "fielddata": {
              "format": "disabled"
            },
            "index": true,
            "norms": false,
            "type": "text"
          },
          "match_mapping_type": "string",
          "match": "message"
        }
      },
      {
        "string_fields": {
          "mapping": {
            "fielddata": {
              "format": "disabled"
            },
            "index": true,
            "norms": false,
            "type": "text",
            "fields": {
              "raw": {
                "ignore_above": 256,
                "index": true,
                "type": "keyword",
                "doc_values": true
              }
            }
          },
          "match_mapping_type": "string",
          "match": "*"
        }
      },
      {
        "double_fields": {
          "mapping": {
            "type": "double",
            "doc_values": true
          },
          "match_mapping_type": "double",
          "match": "*"
        }
      },
      {
        "long_fields": {
          "mapping": {
            "type": "long",
            "doc_values": true
          },
          "match_mapping_type": "long",
          "match": "*"
        }
      },
      {
        "date_fields": {
          "mapping": {
            "type": "date",
            "doc_values": true
          },
          "match_mapping_type": "date",
          "match": "*"
        }
      }
    ],
    "_all": {
      "norms": false,
      "enabled": true
    },
    "properties": {
      "@timestamp": {
        "type": "date",
        "doc_values": true
      },
      "geoip": {
        "dynamic": true,
        "type": "object",
        "properties": {
          "ip": {
            "type": "ip",
            "doc_values": true
          },
          "latitude": {
            "type": "float",
            "doc_values": true
          },
          "location": {
            "type": "geo_point",
            "doc_values": true
          },
          "longitude": {
            "type": "float",
            "doc_values": true
          }
        }
      },
      "@version": {
        "index": true,
        "type": "keyword",
        "doc_values": true
      }
    }
  },
  "aliases": {}
}
