{{/*
Pod metadata (labels + annotations) shared by all workload kinds.
Usage: {{- include "agent-sandbox.podMeta" . | nindent <n> }}
*/}}
{{- define "agent-sandbox.podMeta" -}}
labels:
  app.kubernetes.io/name: {{ .Values.agent.name }}
  agent-sandbox.cloud.sap/enforce: "true"
annotations:
  checksum/envoy-config: {{ include (print $.Template.BasePath "/envoy-configmap.yaml") . | sha256sum }}
{{- end -}}

{{/*
Pod spec body shared by the Deployment, Job and CronJob workloads.

The Envoy egress proxy runs as a native sidecar (an initContainer with
restartPolicy: Always) rather than a regular container. This starts Envoy
before the agent, keeps it up for the pod's lifetime, and - crucially for
Job/CronJob - lets Kubernetes tear it down when the agent container exits so
the run can actually complete.

Takes a tuple (list <workloadKind> <rootContext>). The kind decides whether a
pod-level restartPolicy is emitted: Deployments default to Always (omitted),
batch workloads use .Values.agent.workload.restartPolicy.

Usage: {{- tuple .Values.agent.workload.kind $ | include "agent-sandbox.podSpec" | nindent <n> }}
*/}}
{{- define "agent-sandbox.podSpec" -}}
{{- $kind := index . 0 -}}
{{- $ctx := index . 1 -}}
automountServiceAccountToken: false
{{- if ne $kind "Deployment" }}
restartPolicy: {{ $ctx.Values.agent.workload.restartPolicy }}
{{- end }}
initContainers:
  - name: setup-agent-sandbox-iptables
    image: {{ $ctx.Values.iptables.image | quote }}
    imagePullPolicy: {{ $ctx.Values.iptables.imagePullPolicy | quote }}
    securityContext:
      capabilities:
        add: ["NET_ADMIN"]
    command:
      - /bin/sh
      - -ceu
      - |
        # Install iptables in the short-lived init container. The rules
        # stay in the shared pod network namespace after this exits.
        apk add --no-cache iptables

        echo "=== Setting up agent sandbox iptables rules ==="

        # NAT chain: transparently send agent web traffic to Envoy.
        iptables -t nat -N AGENT_SANDBOX_EGRESS || true
        iptables -t nat -F AGENT_SANDBOX_EGRESS

        # Do not redirect Envoy's own upstream connections back to Envoy.
        iptables -t nat -A AGENT_SANDBOX_EGRESS -m owner --uid-owner {{ $ctx.Values.envoy.uid }} -j RETURN

        # Do not touch loopback traffic.
        iptables -t nat -A AGENT_SANDBOX_EGRESS -d 127.0.0.0/8 -j RETURN

        # Intercept normal HTTP and HTTPS. The agent still connects to
        # port 80/443; only the local destination is changed.
        iptables -t nat -A AGENT_SANDBOX_EGRESS -p tcp --dport 80 -j REDIRECT --to-ports 15001
        iptables -t nat -A AGENT_SANDBOX_EGRESS -p tcp --dport 443 -j REDIRECT --to-ports 15006
        iptables -t nat -C OUTPUT -p tcp -j AGENT_SANDBOX_EGRESS 2>/dev/null || iptables -t nat -A OUTPUT -p tcp -j AGENT_SANDBOX_EGRESS

        # Filter chain: block non-web egress from the agent process.
        iptables -N AGENT_SANDBOX_FILTER || true
        iptables -F AGENT_SANDBOX_FILTER

        # Keep local pod traffic working.
        iptables -A AGENT_SANDBOX_FILTER -o lo -j ACCEPT

        # Let Envoy connect to approved upstreams after it checks Host/SNI.
        iptables -A AGENT_SANDBOX_FILTER -m owner --uid-owner {{ $ctx.Values.envoy.uid }} -j ACCEPT

        # Allow DNS; NetworkPolicy limits this to kube-dns.
        iptables -A AGENT_SANDBOX_FILTER -p udp --dport 53 -j ACCEPT
        iptables -A AGENT_SANDBOX_FILTER -p tcp --dport 53 -j ACCEPT

        # Allow redirected connections into Envoy and the original web
        # ports before NAT rewrites them.
        iptables -A AGENT_SANDBOX_FILTER -p tcp --dport 15001 -j ACCEPT
        iptables -A AGENT_SANDBOX_FILTER -p tcp --dport 15006 -j ACCEPT
        iptables -A AGENT_SANDBOX_FILTER -p tcp --dport 80 -j ACCEPT
        iptables -A AGENT_SANDBOX_FILTER -p tcp --dport 443 -j ACCEPT
{{- range $ctx.Values.agent.allowedEndpoints }}
{{- $parts := splitList ":" . }}

        # Allow direct access to internal endpoint {{ . }}
        iptables -A AGENT_SANDBOX_FILTER -p tcp -d {{ index $parts 0 }} --dport {{ index $parts 1 }} -j ACCEPT
{{- end }}

        # Everything else from the agent is out of scope for this sandbox.
        iptables -A AGENT_SANDBOX_FILTER -j REJECT
        iptables -C OUTPUT -j AGENT_SANDBOX_FILTER 2>/dev/null || iptables -A OUTPUT -j AGENT_SANDBOX_FILTER

        echo ""
        echo "=== NAT rules (AGENT_SANDBOX_EGRESS) ==="
        iptables -t nat -L AGENT_SANDBOX_EGRESS -n -v
        echo ""
        echo "=== Filter rules (AGENT_SANDBOX_FILTER) ==="
        iptables -L AGENT_SANDBOX_FILTER -n -v
        echo ""
        echo "=== Agent sandbox iptables setup complete ==="
  # Envoy egress proxy as a native sidecar (restartPolicy: Always).
  - name: agent-sandbox-envoy
    image: {{ $ctx.Values.envoy.image | quote }}
    imagePullPolicy: {{ $ctx.Values.envoy.imagePullPolicy | quote }}
    restartPolicy: Always
    args: ["-c", "/etc/envoy/envoy.yaml"]
    securityContext:
      runAsUser: {{ $ctx.Values.envoy.uid }}
      runAsGroup: {{ $ctx.Values.envoy.uid }}
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
      - name: agent-sandbox-envoy
        mountPath: /etc/envoy
        readOnly: true
containers:
  - name: {{ $ctx.Values.agent.container.name }}
    image: {{ $ctx.Values.agent.container.image | quote }}
    imagePullPolicy: {{ $ctx.Values.agent.container.imagePullPolicy | quote }}
{{- with $ctx.Values.agent.container.command }}
    command:
{{ toYaml . | indent 6 }}
{{- end }}
    env:
      - name: HOME
        value: /home/agent
{{- with $ctx.Values.agent.container.env }}
{{ toYaml . | indent 6 }}
{{- end }}
    securityContext:
      runAsUser: 1000
      runAsGroup: 1000
      runAsNonRoot: true
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
    volumeMounts:
      - name: agent-home
        mountPath: /home/agent
{{- with $ctx.Values.agent.container.volumeMounts }}
{{ toYaml . | indent 6 }}
{{- end }}
volumes:
  - name: agent-home
    emptyDir: {}
  - name: agent-sandbox-envoy
    configMap:
      name: agent-sandbox-envoy
{{- with $ctx.Values.agent.volumes }}
{{ toYaml . | indent 2 }}
{{- end }}
{{- end -}}
