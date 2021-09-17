{
  "index_patterns" : [
    "audit-*"
  ],
  "settings" : {
    "index" : {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "codec": "best_compression",
      "max_result_window": 10000
    }
  },
  "mappings" : {
    "doc" : {
      "properties" : {
        "@timestamp" : {
          "type" : "date"
        },
        "@version" : {
          "type" : "keyword"
        },
        "_unique_id" : {
          "type" : "keyword"
        },
        "action" : {
          "type" : "keyword"
        },
        "attachments" : {
          "properties" : {
            "content" : {
              "type" : "text"
            },
            "name" : {
              "type" : "keyword"
            },
            "typeURI" : {
              "type" : "keyword"
            }
          }
        },
        "eventTime" : {
          "type" : "date"
        },
        "eventType" : {
          "type" : "keyword"
        },
        "id" : {
          "type" : "keyword"
        },
        "initiator" : {
          "properties" : {
            "domain" : {
              "type" : "keyword"
            },
            "domain_id" : {
              "type" : "keyword"
            },
            "host" : {
              "properties" : {
                "address" : {
                  "type" : "keyword",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256
                    }
                  }
                },
                "agent" : {
                  "type" : "keyword",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256
                    }
                  }
                }
              }
            },
            "id" : {
              "type" : "keyword"
            },
            "name" : {
              "type" : "keyword"
            },
            "project_id" : {
              "type" : "keyword"
            },
            "typeURI" : {
              "type" : "keyword"
            }
          }
        },
        "observer" : {
          "properties" : {
            "id" : {
              "type" : "keyword"
            },
            "name" : {
              "type" : "keyword"
            },
            "typeURI" : {
              "type" : "keyword"
            }
          }
        },
        "outcome" : {
          "type" : "keyword"
        },
        "reason" : {
          "properties" : {
            "reasonCode" : {
              "type" : "keyword"
            },
            "reasonType" : {
              "type" : "keyword"
            }
          }
        },
        "requestPath" : {
          "type" : "keyword"
        },
        "target" : {
          "properties" : {
            "attachments" : {
              "properties" : {
                "content" : {
                  "type" : "keyword",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256,
                      "doc_values": false
                    }
                  }
                },
                "name" : {
                  "type" : "keyword",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256
                    }
                  }
                },
                "typeURI" : {
                  "type" : "keyword",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256
                    }
                  }
                }
              }
            },
            "domain_id" : {
              "type" : "keyword"
            },
            "id" : {
              "type" : "keyword"
            },
            "name" : {
              "type" : "keyword"
            },
            "project_id" : {
              "type" : "keyword"
            },
            "typeURI" : {
              "type" : "keyword"
            }
          }
        },
        "typeURI" : {
          "type" : "keyword"
        }
      }
    }
  }
}
