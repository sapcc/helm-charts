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
        "analyzer": "custom_analyzer",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
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
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "global_request_id" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "request_id" : {
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
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "name" : {
            "type" : "text",
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "project_domain_name": {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "project_id" : {
            "type" : "text",
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "project_name": {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "typeURI" : {
            "type" : "text",
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          }
        }
      },
      "observer" : {
        "properties" : {
          "id" : {
            "type" : "text",
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          },
          "name" : {
            "type" : "text",
            "analyzer": "custom_analyzer"
          },
          "typeURI" : {
            "type" : "text",
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          }
        }
      },
      "outcome" : {
        "type" : "text",
        "analyzer": "custom_analyzer",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
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
        "analyzer": "custom_analyzer",
        "fields": {
          "keyword": {
            "type": "keyword"
          }
        }
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
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
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
            "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
          }
        }
      },
      "typeURI" : {
        "type" : "text",
        "analyzer": "custom_analyzer",
            "fields": {
              "keyword": {
                "type": "keyword"
              }
            }
      }
    }
  }
}
