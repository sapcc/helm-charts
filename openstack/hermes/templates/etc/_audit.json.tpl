{
  "index_patterns" : [
    "audit-*"
  ],
  "settings" : {
    "index" : {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "codec": "best_compression",
      "max_result_window": 20000
    }
  },
  "mappings" : {
    "doc" : {
      "properties" : {
        "@timestamp" : {
          "type" : "date"
        },
        "@version" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "_unique_id" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "action" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "attachments" : {
          "properties" : {
            "content" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "name" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "typeURI" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        },
        "eventTime" : {
          "type" : "date"
        },
        "eventType" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "id" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "initiator" : {
          "properties" : {
            "domain" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "domain_id" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "host" : {
              "properties" : {
                "address" : {
                  "type" : "text",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256
                    }
                  }
                },
                "agent" : {
                  "type" : "text",
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
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "name" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "project_id" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "typeURI" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        },
        "observer" : {
          "properties" : {
            "id" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "name" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "typeURI" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        },
        "outcome" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "reason" : {
          "properties" : {
            "reasonCode" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "reasonType" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        },
        "requestPath" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        },
        "target" : {
          "properties" : {
            "attachments" : {
              "properties" : {
                "content" : {
                  "type" : "text",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256,
                      "doc_values": false
                    }
                  }
                },
                "name" : {
                  "type" : "text",
                  "fields" : {
                    "raw" : {
                      "type" : "keyword",
                      "ignore_above" : 256
                    }
                  }
                },
                "typeURI" : {
                  "type" : "text",
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
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "id" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "name" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "project_id" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            },
            "typeURI" : {
              "type" : "text",
              "fields" : {
                "raw" : {
                  "type" : "keyword",
                  "ignore_above" : 256
                }
              }
            }
          }
        },
        "typeURI" : {
          "type" : "text",
          "fields" : {
            "raw" : {
              "type" : "keyword",
              "ignore_above" : 256
            }
          }
        }
      }
    }
  }
}