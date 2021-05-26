[query_elastiflow_thousandeyes_probes]
QueryIntervalSecs = 300
QueryTimeoutSecs = 150
QueryIndices = elastiflow-*
QueryJson = {
   "query": {
    "bool": {
      "must": [],
      "filter": [
        {
          "bool": {
            "should": [
{{- if .Values.probes.port443  }}
              {
                "bool": {
                  "filter": [
                    {
                      "bool": {
                        "should": [
                          {{- range $index, $element := .Values.probes.port443 }}
                          {
                            "match": {
                              "destination.ip": {{ $element | quote}}
                            }
                          }{{if $index}},{{end}}
                          {{- end }}
                        ],
                        "minimum_should_match": 1
                      }
                    },
                    {
                      "bool": {
                        "filter": [
                          {
                            "bool": {
                              "should": [
                                {
                                  "match": {
                                    "destination.port": 443
                                  }
                                }
                              ],
                              "minimum_should_match": 1
                            }
                          },
                          {
                            "bool": {
                              "filter": [
                                {
                                  "bool": {
                                    "should": [
                                      {
                                        "match": {
                                          "client.bytes": 50
                                        }
                                      }
                                    ],
                                    "minimum_should_match": 1
                                  }
                                },
                                {
                                  "bool": {
                                    "should": [
                                      {
                                        "match": {
                                          "netflow.fw_event": 5
                                        }
                                      }
                                    ],
                                    "minimum_should_match": 1
                                  }
                                }
                              ]
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              },
{{- end }}
{{- if .Values.probes.port1080  -}}
              {
                "bool": {
                  "filter": [
                    {
                      "bool": {
                        "should": [
                        {{- range $index, $element := .Values.probes.port1080 }}
                          {
                            "bool": {
                              "should": [
                                {
                                  "match": {
                                    "destination.ip": {{ $element | quote }}
                                  }
                                }
                              ],
                              "minimum_should_match": 1
                            }
                          }{{if $index}},{{end}}
                        {{- end }}
                        ],
                        "minimum_should_match": 1
                      }
                    },
                    {
                      "bool": {
                        "filter": [
                          {
                            "bool": {
                              "should": [
                                {
                                  "match": {
                                    "destination.port": 1080
                                  }
                                }
                              ],
                              "minimum_should_match": 1
                            }
                          },
                          {
                            "bool": {
                              "should": [
                                {
                                  "match": {
                                    "netflow.fw_event": 1
                                  }
                                }
                              ],
                              "minimum_should_match": 1
                            }
                          }
                        ]
                      }
                    }
                  ]
                }
              }
{{- end -}}
            ],
            "minimum_should_match": 1
          }
        },
        {
          "range": {
            "@timestamp": {
              "gte": "now-5m"
            }
          }
        }
      ]
    }
  }
}