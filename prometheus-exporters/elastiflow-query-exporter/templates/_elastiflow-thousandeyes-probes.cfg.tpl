[query_elastiflow_thousandeyes_probes]
QueryIntervalSecs = 900
QueryTimeoutSecs = 850
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
                          {{if $index}},{{end}}
                          {
                            "match": {
                              "destination.ip": {{ $element | quote}}
                            }
                          }
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
              }
{{- end }}
{{- if .Values.probes.port443 }}
  {{- if .Values.probes.port1080 }}, {{ end }}
{{- end }}
{{- if .Values.probes.port1080  -}}
              {
                "bool": {
                  "filter": [
                    {
                      "bool": {
                        "should": [
                        {{- range $index, $element := .Values.probes.port1080 }}
                        {{if $index}},{{end}}
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
                          }
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
              "lte": "now-14m",
              "gte": "now-30m"
            }
          }
        }
      ]
    }
  }
 }
