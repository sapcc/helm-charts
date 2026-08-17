# Agent Sandbox

Running agents inside an internal network can be dangerous. If agents access the public internet, they may be subjected to prompt injection, which can be used to exfiltrate sensitive internal information.

To mitigate this issue, this repo provides a Helm chart that you can drop into your agent's namespace, restricting access to specific whitelisted domains. In this way, the chance of your agent encountering malicious prompts can be reduced.

This helm chart can be applied to any namespace and will restrict the network access of pods with the label `agent-sandbox=enforce` to only allow access to a set of whitelisted domains. All other traffic will be blocked. Agents can call the proxy instead of the upstream URL to reach the whitelisted domains.

## Example Usage

Start minikube with Calico CNI to enable network policies:
```bash
minikube start --cni=calico
```

Create network policies and proxy setup, allowing access to `github.com`:
```bash
helm upgrade --install agent-sandbox helm/chart --set proxy.allowedDomains={.github.com}
```

Wait for the proxy to be ready:
```bash
kubectl wait --for=condition=Ready pod -l app=agent-sandbox-egress-proxy --timeout=120s
```

Test that the agent can reach allowed domains and is blocked from others:
```bash
kubectl run netcheck --rm -it --restart=Never \
-l="agent-sandbox"=enforce \
--image=curlimages/curl:latest \
-- sh -c '
echo "github.com directly: $(curl -m 5 -s -o /dev/null -w %{http_code} https://github.com)"
echo "example.com directly: $(curl -m 5 -s -o /dev/null -w %{http_code} https://example.com)"

P=http://agent-sandbox-egress-proxy:3128
echo "github.com via proxy: $(curl -m 5 -s -o /dev/null -w %{http_code} -x $P https://github.com)"
echo "example.com via proxy: $(curl -m 5 -s -o /dev/null -w %{http_code} -x $P https://example.com)"
'
```

Result:
```
github.com directly: 000
example.com directly: 000
github.com via proxy: 200
example.com via proxy: 000
```

Note: `000` means the connection was blocked by the proxy, and `200` means the connection was successful.

Test that other pods can reach any domain:
```bash
kubectl run netcheck --rm -it --restart=Never \
--image=curlimages/curl:latest \
-- sh -c '
echo "github.com directly: $(curl -m 5 -s -o /dev/null -w %{http_code} https://github.com)"
echo "example.com directly: $(curl -m 5 -s -o /dev/null -w %{http_code} https://example.com)"
'
```

Result:
```
github.com directly: 200
example.com directly: 200
```
