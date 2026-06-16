# neutron-linuxbridge-agent

A Helm `type: library` chart that lets a consumer chart embed a
`neutron-linuxbridge-agent` container into its own Pod spec, in any namespace
or cluster.

The library exposes three named templates:

| Template                                  | Renders                                   |
|-------------------------------------------|-------------------------------------------|
| `neutron-linuxbridge-agent.configmap-etc` | A full ConfigMap with `neutron.conf`      |
| `neutron-linuxbridge-agent.container`     | One container spec for the agent          |
| `neutron-linuxbridge-agent.volumes`       | Pod-level `linuxbridge-agent-etc` + `modules` volumes |

The library does **not** own the Pod, StatefulSet, or DaemonSet, and it does
**not** create the Secret with `OS_*__*` env keys — the consumer brings both.

## Usage

Add the dependency to your consumer chart:

```yaml
# Chart.yaml
dependencies:
  - name: neutron-linuxbridge-agent
    version: '>= 0.0.0'
    repository: oci://keppel.eu-de-1.cloud.sap/ccloud-helm
```

The image is resolved as
`{{ .Values.global.registry }}/loci-neutron:<imageVersion>`, where
`<imageVersion>` cascades through
`linuxbridge_agent.imageVersion` →
`imageVersionNetworkAgentLinuxBridge` →
`imageVersionNetworkAgent` →
`imageVersion`. So an umbrella chart that already sets `imageVersion` will
just work.

There are two modes for `neutron.conf`. Pick one.

### Mode A — bring your own ConfigMap

Use this when your chart already has a ConfigMap with a usable
`neutron.conf` — for example the umbrella `neutron` chart's `neutron-etc`.

```yaml
# values.yaml of the consumer chart
linuxbridge_agent:
  secretName: linuxbridge-agent-secret
  configMap:
    name: neutron-etc        # existing ConfigMap, same release/namespace
    key: neutron.conf        # key inside it that holds the file body
```

In the Pod spec:

```yaml
spec:
  containers:
    {{- include "neutron-linuxbridge-agent.container" (dict "root" . "values" .Values.linuxbridge_agent) | nindent 4 }}
  volumes:
    {{- include "neutron-linuxbridge-agent.volumes" (dict "root" . "values" .Values.linuxbridge_agent) | nindent 4 }}
```

No call to `configmap-etc` — you're not generating one.

### Mode B — let the library generate the ConfigMap

Use this when you want the library to produce a minimal `neutron.conf` for
you, parameterized through the values surface.

```yaml
# values.yaml
linuxbridge_agent:
  secretName: linuxbridge-agent-secret
  configMap:
    name: ""                 # empty = library-rendered
  host: ""                   # default: node hostname
  agent:
    polling_interval: 2
  vxlan:
    enable: true
  securitygroup:
    firewall_driver: iptables
```

In a consumer template, render the ConfigMap as a full top-level resource:

```yaml
{{- include "neutron-linuxbridge-agent.configmap-etc" (dict "root" . "values" .Values.linuxbridge_agent) }}
```

Pod spec is identical to Mode A.

## Secret contract

The consumer creates a Secret whose keys are named after the
`OS_<SECTION>__<KEY>` convention. oslo.config maps each one onto its config
tree at startup, so nothing in `neutron.conf` needs to reference them.

| Key                                            | Maps to (in oslo.config)                       |
|------------------------------------------------|-------------------------------------------------|
| `OS_DEFAULT__TRANSPORT_URL`                    | `[DEFAULT] transport_url`                       |
| `OS_LINUX_BRIDGE__PHYSICAL_INTERFACE_MAPPINGS` | `[linux_bridge] physical_interface_mappings`    |
| `OS_DEFAULT__HOST`                             | `[DEFAULT] host` (alternative to `.values.host`) |

The library uses `envFrom: secretRef:` — every key in the Secret becomes an
env var with the same name.

## Required capabilities and host volumes

- `NET_ADMIN`, `SYS_ADMIN`, `DAC_OVERRIDE`, `DAC_READ_SEARCH`, `SYS_PTRACE`.
- `/lib/modules` mounted read-only from the host so the agent can verify
  bridge / vxlan kernel modules are present.

## Errors

- `.Values.global.registry is required` — set it on the consumer.
- `Set imageVersionNetworkAgentLinuxBridge, imageVersionNetworkAgent, or imageVersion` — same.
- `.values.secretName is required` — set `linuxbridge_agent.secretName` on the consumer.

## Smoke test

```sh
helm lint openstack/neutron-linuxbridge-agent
helm dependency update openstack/neutron-linuxbridge-agent/ci/consumer-fixture
helm template openstack/neutron-linuxbridge-agent/ci/consumer-fixture
```
