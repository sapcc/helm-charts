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
    "_default_": {
      "dynamic_templates": [
        {
          "message_field": {
            "mapping": {
              "fielddata": {
                "format": "disabled"
              },
              "index": "analyzed",
              "omit_norms": true,
              "type": "string"
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
              "index": "analyzed",
              "omit_norms": true,
              "type": "string",
              "fields": {
                "raw": {
                  "ignore_above": 256,
                  "index": "not_analyzed",
                  "type": "string",
                  "doc_values": true
                }
              }
            },
            "match_mapping_type": "string",
            "match": "*"
          }
        },
        {
          "float_fields": {
            "mapping": {
              "type": "float",
              "doc_values": true
            },
            "match_mapping_type": "float",
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
          "byte_fields": {
            "mapping": {
              "type": "byte",
              "doc_values": true
            },
            "match_mapping_type": "byte",
            "match": "*"
          }
        },
        {
          "short_fields": {
            "mapping": {
              "type": "short",
              "doc_values": true
            },
            "match_mapping_type": "short",
            "match": "*"
          }
        },
        {
          "integer_fields": {
            "mapping": {
              "type": "integer",
              "doc_values": true
            },
            "match_mapping_type": "integer",
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
        },
        {
          "geo_point_fields": {
            "mapping": {
              "type": "geo_point",
              "doc_values": true
            },
            "match_mapping_type": "geo_point",
            "match": "*"
          }
        }
      ],
      "_all": {
        "omit_norms": true,
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
          "index": "not_analyzed",
          "type": "string",
          "doc_values": true
        }
      }
    }
  },
  "aliases": {}
}
