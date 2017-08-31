ALERT KubernetesKubeletDown
  IF up{job="kube-system/kubelet"} == 0
  FOR 15m
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "critical",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-health",
  }
  ANNOTATIONS {
    summary = "A Kubelet is DOWN",
    description = "Kublet on {{`{{$labels.instance}}`}} is DOWN.",
  }


ALERT KubernetesKubeletManyDown
  IF count(up{job="kube-system/kubelet"}) - sum(up{job="kube-system/kubelet"}) > 2
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "critical",
    context = "kubelet",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "Many Kubelets are DOWN",
    description = "More than 2 Kubelets are DOWN.",
  }

ALERT KubernetesKubeletScrapeMissing
  IF absent(up{job="kube-system/kubelet"})
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "critical",
    context = "kubelet",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "Kubelets cannot be scraped. Status unknown.",
    description = "Kubelets failed to be scraped.",
  }

ALERT KubernetesKubeletTooManyPods
  IF kubelet_running_pod_count > 225
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "warning",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "Kubelet is close to pod limit",
    description = "Kubelet {{`{{$labels.instance}}`}} is running {{`{{$value}}`}} pods, close to the limit of 250",
  }

ALERT KubernetesKubeletFull
  IF kubelet_running_pod_count >= 250
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "Kubelet is full",
    description = "Kubelet {{`{{$labels.instance}}`}} is running {{`{{$value}}`}} pods. That's too much!",
  }

ALERT KubernetesNodeNotReady
  IF kube_node_status_condition{condition="Ready",status="true"} == 0
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "node",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.node}}`}}",
    {{ if .Values.ops_docu_url -}}
        playbook = "{{.Values.ops_docu_url}}/docs/support/playbook/k8s_node_not_ready.html",
    {{- end }}
  }
  ANNOTATIONS {
    summary = "Node status is NotReady",
    description = "Node {{`{{$labels.node}}`}} is NotReady for more than an hour",
  }

ALERT KubernetesNodeManyNotReady
  IF count(kube_node_status_condition{condition="Ready",status="true"} == 0) > 2
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "node",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "Many Nodes are NotReady",
    description = "Many ({{`{{$value}}`}}) nodes are NotReady for more than an hour.",
  }

ALERT KubernetesNodeNotReady
  IF changes(kube_node_status_condition{condition="Ready",status="true"}[15m]) > 2
  FOR 15m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "warning",
    context = "node",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "Node Readyness is flapping",
    description = "Node {{`{{$labels.node}}`}} is flapping between Ready and NotReady",
  }


ALERT KubernetesNodeScrapeMissing
  IF absent(up{job="endpoints",kubernetes_name="kube-state-metrics"})
  FOR 1h
  LABELS {
    service = "k8s",
    severity = "critical",
    context = "node",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "Node status cannot be scraped",
    description = "Node status failed to be scraped.",
  }

ALERT KubernetesPodRestartingTooMuch
  IF rate(kube_pod_container_status_restarts[15m]) > 0
  FOR 4h
  LABELS {
    tier = "kubernetes",
    service = "resources",
    severity = "info",
    context = "pod",
    meta = "{{`{{$labels.namespace}}`}}/{{`{{$labels.pod}}`}}",
  }
  ANNOTATIONS {
    summary = "Pod is in a restart loop",
    description = "Pod {{`{{$labels.namespace}}`}}/{{`{{$labels.pod}}`}} is restarting constantly",
  }


ALERT KubernetesKubeletDockerHangs
  IF rate(kubelet_docker_operations_timeout[5m])> 0
  FOR 15m
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "warning",
    context = "docker",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "Docker hangs!",
    description = "Docker on {{`{{$labels.instance}}`}} is hanging",
  }

ALERT KubernetesApiServerDown
  IF up{job="kube-system/apiserver"} == 0
  FOR 15m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "warning",
    context = "apiserver",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-kubelet?var-node={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "An ApiServer is DOWN",
    description = "ApiServer on {{`{{$labels.instance}}`}} is DOWN.",
  }

ALERT KubernetesApiServerAllDown
  IF count(up{job="kube-system/apiserver"} == 0) == count(up{job="kube-system/apiserver"})
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "apiserver",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "API is unavailable!!!",
    description = "All apiservers are down. API is unavailable!",
  }

ALERT KubernetesApiServerScrapeMissing
  IF absent(up{job="kube-system/apiserver"})
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "apiserver",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "ApiServer cannot be scraped",
    description = "ApiServers failed to be scraped.",
  }

ALERT KubernetesApiServerLatency
  IF histogram_quantile(
      0.99,
      sum without (instance,node,resource) (apiserver_request_latencies_bucket{verb!~"CONNECT|WATCHLIST|WATCH|LIST"})
    ) / 1e6 > 2.0
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "apiserver",
    severity = "info",
    context = "apiserver",
    dashboard = "kubernetes-apiserver"
  }
  ANNOTATIONS {
    summary = "Kubernetes apiserver latency is high",
    description = "Latency for {{`{{$labels.verb}}`}} is higher than 2s.",
  }

ALERT KubernetesApiServerEtcdAccessLatency
  IF etcd_request_latencies_summary{quantile="0.99"} / 1e6 > 1.0
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "etcd",
    severity = "info",
    context = "apiserver",
    dashboard = "kubernetes-apiserver"
  }
  ANNOTATIONS {
    summary = "Access to etcd is slow",
    description = "Latency for apiserver to access etcd is higher than 1s.",
  }



ALERT KubernetesSchedulerDown
  IF count(up{job="kube-system/scheduler"} == 1) == 0
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "scheduler",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "Scheduler is down",
    description = "No scheduler is running. New pods are not being assigned to nodes!",
  }

ALERT KubernetesSchedulerScrapeMissing
  IF absent(up{job="kube-system/scheduler"})
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "scheduler",
    dashboard = "kubernetes-health"
  }
  ANNOTATIONS {
    summary = "Scheduler cannot be scraped",
    description = "Scheduler in failed to be scraped.",
  }

ALERT KubernetesControllerManagerDown
  IF count(up{job="kube-system/controller-manager"} == 1) == 0
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "controller-manager",
    dashboard = "kubernetes-health"

  }
  ANNOTATIONS {
    summary = "Controller manager is down",
    description = "No controller-manager is running. Deployments and replication controllers are not making progress.",
  }

ALERT KubernetesControllerManagerScrapeMissing
  IF absent(up{job="kube-system/controller-manager"})
  FOR 1h
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "controller-manager",
    dashboard = "kubernetes-health"

  }
  ANNOTATIONS {
    summary = "ControllerManager cannot be scraped",
    description = "ControllerManager failed to be scraped.",
  }

ALERT KubernetesTooManyOpenFiles
  IF 100*process_open_fds{job=~"kube-system/kubelet|kube-system/apiserver"} / process_max_fds > 50
  FOR 10m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "warning",
    context = "system",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "Too many open file descriptors",
    description = "{{`{{$labels.job}}`}} on {{`{{$labels.instance}}`}} is using {{`{{$value}}`}}% of the available file/socket descriptors.",
  }

ALERT KubernetesTooManyOpenFiles
  IF 100*process_open_fds{job=~"kube-system/kubelet|kube-system/apiserver"} / process_max_fds > 80
  FOR 10m
  LABELS {
    tier = "kubernetes",
    service = "k8s",
    severity = "critical",
    context = "system",
    meta = "{{`{{ $labels.instance }}`}}",
    dashboard = "kubernetes-node?var-server={{`{{$labels.instance}}`}}",
  }
  ANNOTATIONS {
    summary = "Too many open file descriptors",
    description = "{{`{{$labels.job}}`}} on {{`{{$labels.instance}}`}} is using {{`{{$value}}`}}% of the available file/socket descriptors.",
  }

ALERT KubernetesHighNumberOfGoRoutines
  IF go_goroutines{job="kube-system/kubelet"} > 5000
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "warning",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
  }
  ANNOTATIONS {
    summary = "High number of Go routines",
    description = "Kublet on {{`{{$labels.instance}}`}} might be unresponsive due to a high number of go routines.",
  }

ALERT KubernetesPredictHighNumberOfGoRoutines
  IF abs(predict_linear(go_goroutines{job="kube-system/kubelet"}[1h], 2*3600)) > 10000
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "kubelet",
    severity = "warning",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
  }
  ANNOTATIONS {
    summary = "Predicting high number of Go routines",
    description = "Kublet on {{`{{$labels.instance}}`}} might become unresponsive due to a high number of go routines within 2 hours.",
  }

ALERT KubernetesNodeDiskPressure
  IF kube_node_status_condition{condition="DiskPressure",status="true"} == 1
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "node",
    severity = "warning",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
  }
  ANNOTATIONS {
    summary = "Insufficient disk space",
    description = "Kublet on {{`{{$labels.instance}}`}} under pressure due to insufficient available disk space.",
  }

ALERT KubernetesNodeMemoryPressure
  IF kube_node_status_condition{condition="MemoryPressure",status="true"} == 1
  FOR 5m
  LABELS {
    tier = "kubernetes",
    service = "node",
    severity = "warning",
    context = "kubelet",
    meta = "{{`{{ $labels.instance }}`}}",
  }
  ANNOTATIONS {
    summary = "Insufficient memory",
    description = "Kublet on {{`{{$labels.instance}}`}} under pressure due to insufficient available memory.",
  }
