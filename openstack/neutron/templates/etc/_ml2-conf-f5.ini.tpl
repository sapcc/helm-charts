[ml2_f5]
physical_networks = {{- range $i, $loadbalancer := .Values.f5.loadbalancers -}}{{required "A valid f5 physical_network required!" $loadbalancer.physical_network}}{{if lt $i (sub (len $.Values.f5.loadbalancers) 1) }},{{ end }} {{- end -}}
