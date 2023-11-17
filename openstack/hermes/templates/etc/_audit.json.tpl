{
  "index_patterns" : [
    "audit-*"
  ],
  "settings" : {
    "index" : {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "codec": "best_compression",
      "max_result_window": 20000,
      "analysis": {
        "analyzer": {
          "custom_analyzer": {
            "type": "custom",
            "tokenizer": "custom_tokenizer"
          }
        },
        "tokenizer": {
          "custom_tokenizer": {
            "type": "pattern",
            "pattern": "[\\s\\p{Punct}&&[^-]]+"
          }
        }
      }
    }
  },
  "mappings" : {
    "properties" : {
      "@timestamp" : {
        "type" : "date"
      },
      "@version" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "_unique_id" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "action" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "attachments" : {
        "properties" : {
          "content" : {
            "type" : "text"
          },
          "name" : {
            "type" : "text",
        "analyzer": "custom_analyzer"
          },
          "typeURI" : {
            "type" : "text",
        "analyzer": "custom_analyzer"
          }
        }
      },
      "eventTime" : {
        "type" : "date",
        "format" : "date_optional_time"
      },
      "eventType" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "id" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "initiator" : {
        "properties" : {
          "domain" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "domain_id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "host" : {
            "properties" : {
              "address" : {
                "type" : "text",
                "analyzer": "custom_analyzer"
              },
              "agent" : {
                "type" : "text",
                "analyzer": "custom_analyzer"
              }
            }
          },
          "id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "name" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "project_id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "typeURI" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          }
        }
      },
      "observer" : {
        "properties" : {
          "id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "name" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "typeURI" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          }
        }
      },
      "outcome" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "reason" : {
        "properties" : {
          "reasonCode" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "reasonType" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          }
        }
      },
      "requestPath" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      },
      "target" : {
        "properties" : {
          "attachments" : {
            "properties" : {
              "content" : {
                "type" : "text",
                "analyzer": "custom_analyzer"
              },
              "name" : {
                "type" : "text",
                "analyzer": "custom_analyzer"
              },
              "typeURI" : {
                "type" : "text",
                "analyzer": "custom_analyzer"
              }
            }
          },
          "domain_id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "name" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "project_id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "typeURI" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          }
        }
      },
      "typeURI" : {
        "type" : "text",
        "analyzer": "custom_analyzer"
      }
    }
  }
}
