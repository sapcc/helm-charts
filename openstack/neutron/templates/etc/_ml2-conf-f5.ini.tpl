[ml2_f5]
physical_networks = {{- range $i, $loadbalancer := .Values.f5.loadbalancers -}}{{$loadbalancer.physical_network}}{{if lt $i (sub (len $.Values.f5.loadbalancers) 1) }},{{ end }} {{- end -}}
