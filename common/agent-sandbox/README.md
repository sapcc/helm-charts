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

- `agent-sandbox-agent`: Deployment with the agent, iptables init container, and Envoy sidecar
- `agent-sandbox-envoy`: Envoy config with the domain allowlist
- `agent-sandbox`: NetworkPolicy for pods labeled `agent-sandbox.cloud.sap/enforce=true`
- `owner-info`: org-required owner metadata

## Test

From the agent container:

```bash
wget -T 5 -q --spider https://github.com      # allowed
wget -T 5 -q --spider https://api.github.com  # allowed
wget -T 5 -q --spider https://google.com      # blocked
wget -T 5 -q --spider https://1.1.1.1         # blocked: no allowed SNI
```

## Limits

- `*.example.com` matches subdomains only, not `example.com` itself — list both if needed
- SNI/Host based, no TLS decryption
- ECH or missing SNI fails closed
- NetworkPolicy is only a coarse guardrail; Envoy enforces domains
- only the init container gets `NET_ADMIN`
