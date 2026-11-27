# Agent Sandbox

Proof of concept for running a coding agent with transparent domain-based egress control in Kubernetes.

The chart deploys an agent pod with an iptables init container and an Envoy sidecar.
TCP/80 and TCP/443 are redirected to Envoy on high local ports inside the pod.
Envoy allows HTTP by `Host` and HTTPS by TLS SNI.

## Install

Allow domains (wildcards supported) and use the default `ghcr.io/anomalyco/opencode` agent:

```bash
helm upgrade --install agent-sandbox ./common/agent-sandbox \
  --set 'allowedDomains[0]=github.com' \
  --set 'allowedDomains[1]=*.github.com'
```

Or pass a custom agent image:

```yaml
agent:
  container:
    name: agent
    image: your-agent-image:latest
```

The chart creates:

- `agent-sandbox`: the agent workload (Deployment, Job, or CronJob — see [Workload kind](#workload-kind)) with the agent, iptables init container, and Envoy sidecar
- `agent-sandbox-envoy`: Envoy config with the domain allowlist
- `agent-sandbox`: NetworkPolicy for pods labeled `agent-sandbox.cloud.sap/enforce=true`
- `owner-info`: org-required owner metadata

## Workload kind

`agent.workload.kind` selects how the agent runs:

- `Deployment` (default): long-lived service, restarted continuously. Uses `agent.workload.replicas`.
- `Job`: one-off task that runs once and stops. Use this for a single agent run.
- `CronJob`: scheduled task. Uses `agent.workload.schedule` (and `agent.workload.concurrencyPolicy`).

For `Job`/`CronJob`, `agent.workload.restartPolicy` (`Never` or `OnFailure`) and
`agent.workload.backoffLimit` control retry behavior, and the optional
`agent.workload.ttlSecondsAfterFinished` cleans up finished pods.

> Setting a container-level `restartPolicy` on a `Deployment` does **not** make
> the agent run once — the Deployment recreates the pod, so it crashloops. Use
> `agent.workload.kind=Job` for run-once behavior.

The Envoy proxy runs as a native sidecar (an init container with
`restartPolicy: Always`) so that in `Job`/`CronJob` mode the run completes once
the agent exits instead of hanging on the always-on proxy.

## Test

From the agent container:

```bash
wget -T 5 -q --spider https://github.com      # allowed
wget -T 5 -q --spider https://api.github.com  # allowed
wget -T 5 -q --spider https://google.com      # blocked
wget -T 5 -q --spider https://1.1.1.1         # blocked: no allowed SNI
```

## Demo with Local OpenCode Config and Thalamus

Suppose you have your opencode config at `${HOME}/.config/opencode/opencode.json` with your API key and other settings. Create a ConfigMap from it:
```bash
kubectl create cm opencode-config --from-file="${HOME}/.config/opencode/opencode.json"
```

Then, you can install the chart with the ConfigMap mounted into the agent container and the `OPENCODE_CONFIG` environment variable set:
```bash
helm upgrade --install agent-sandbox ./common/agent-sandbox \
  --set 'allowedDomains[0]=github.com' \
  --set 'allowedDomains[1]=*.github.com' \
  --set 'allowedDomains[2]=*.thalamus.eu-de-1.cloud.sap' \
  --set 'allowedDomains[3]=*.opencode.ai' \
  --set 'allowedDomains[4]=opencode.ai' \
  --set 'allowedDomains[5]=registry.npmjs.org' \
  --set 'agent.container.volumeMounts[0].name=opencode-config' \
  --set 'agent.container.volumeMounts[0].mountPath=/root/.config/opencode/opencode.json' \
  --set 'agent.container.volumeMounts[0].subPath=opencode.json' \
  --set 'agent.container.volumeMounts[0].readOnly=true' \
  --set 'agent.volumes[0].name=opencode-config' \
  --set 'agent.volumes[0].configMap.name=opencode-config' \
  --set 'agent.workload.kind=Job' \
  --set 'agent.container.env[0].name=OPENCODE_CONFIG' \
  --set 'agent.container.env[0].value=/root/.config/opencode/opencode.json' \
  --set 'agent.container.command[0]=opencode' \
  --set 'agent.container.command[1]=run' \
  --set 'agent.container.command[2]=try and access github.com\, api.github.com\, google.com\, and report which ones are allowed'
```

Look at the logs (this runs as a `Job`, so address it with `job/`):
```bash
$ kubectl logs job/agent-sandbox -c agent

Results (tested via `wget`, since `curl` isn't installed):

| Site | Status |
|---|---|
| github.com | **Allowed** — HTTP 200 OK |
| api.github.com | **Allowed** — HTTP 200 OK |
| google.com | **Blocked** — TLS handshake reset by peer (`Connection reset by peer`) |

GitHub domains are fully reachable; google.com is cut off at the SSL connection stage, suggesting a network-level block on that domain.
```

That's because the Envoy sidecar is enforcing the domain allowlist, and google.com is not on it. You can see the Envoy logs for more details:
```bash
$ kubectl logs job/agent-sandbox -c agent-sandbox-envoy

DENY sni=google.com src=10.1.24.37:54548
DENY sni=google.com src=10.1.24.37:54564
ALLOW sni=github.com dst=140.82.121.3:443 bytes_tx=37629 bytes_rx=1715
ALLOW sni=github.com dst=140.82.121.3:443 bytes_tx=37629 bytes_rx=1715
ALLOW sni=models.opencode.ai dst=172.66.173.149:443 bytes_tx=308856 bytes_rx=919
ALLOW sni=opencode.ai dst=172.65.90.22:443 bytes_tx=57521 bytes_rx=147580
ALLOW sni=opencode.ai dst=172.65.90.22:443 bytes_tx=13342 bytes_rx=33792
```

## Limits

- `*.example.com` matches subdomains only, not `example.com` itself — list both if needed
- SNI/Host based, no TLS decryption
- ECH or missing SNI fails closed
- NetworkPolicy is only a coarse guardrail; Envoy enforces domains
- only the init container gets `NET_ADMIN`
