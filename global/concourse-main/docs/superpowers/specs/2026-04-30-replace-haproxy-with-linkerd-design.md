# Replace HAProxy Ingress with Linkerd for Git Resource Proxy Load Balancing

**Date:** 2026-04-30  
**Status:** Approved  
**Author:** Claude Code

## Overview

Replace the outdated HAProxy ingress controller (helm chart v1.49.0) with Linkerd service mesh for load balancing traffic to git-resource-proxy pods. This migration leverages the existing Linkerd deployment in the cluster to provide superior load balancing (P2C + EWMA algorithm), mTLS encryption, and enhanced observability.

## Context

The current setup uses HAProxy ingress controller with least-connections load balancing to distribute requests from Concourse web and worker pods to 10 git-resource-proxy pods. The HAProxy ingress helm chart (v1.49.0) is outdated and needs replacement. Since Linkerd is already deployed cluster-wide, we can eliminate this dependency entirely and gain better load balancing capabilities.

## Goals

1. Remove HAProxy ingress dependency from the helm chart
2. Enable Linkerd-based load balancing with P2C + EWMA algorithm (superior to least-connections)
3. Add mTLS encryption between all Concourse components
4. Ensure proper HTTP protocol detection for L7 features
5. Maintain or improve load balancing quality for git-resource-proxy

## Architecture

### Current State
```
Concourse Web (unmeshed) ──┐
                            ├──> HAProxy Ingress ──> git-resource-proxy pods (unmeshed)
Concourse Workers (unmeshed)┘    (least-conn LB)
```

### Target State
```
Concourse Web (meshed) ──┐
                         ├──> git-resource-proxy pods (meshed)
Concourse Workers (meshed)┘   (Linkerd P2C + EWMA)
```

### Load Balancing Behavior

Linkerd's Power of Two Choices (P2C) with Exponentially Weighted Moving Average (EWMA):
1. Client-side Linkerd proxy discovers all 10 git-resource-proxy pod endpoints
2. For each request, selects 2 random endpoints
3. Chooses the endpoint with lower score based on:
   - Active request count
   - Recent response latency (exponentially weighted)
   - Success/failure rate
4. Automatically avoids slow or failing endpoints

This is superior to HAProxy's simple least-connections because it's latency-aware and adapts faster to changing conditions.

## Components

### 1. Concourse Web Pods
- **Change:** Inject Linkerd sidecar
- **Purpose:** Enable client-side load balancing and endpoint discovery
- **Configuration:** Add `linkerd.io/inject: "enabled"` annotation via values.yaml

### 2. Concourse Worker Pods
- **Change:** Inject Linkerd sidecar
- **Purpose:** Enable client-side load balancing for worker-to-proxy communication
- **Configuration:** Add `linkerd.io/inject: "enabled"` annotation via values.yaml

### 3. Git Resource Proxy Pods
- **Change:** Inject Linkerd sidecar
- **Purpose:** Enable server-side telemetry, mTLS, and request handling
- **Configuration:** Add `linkerd.io/inject: "enabled"` annotation via values.yaml

### 4. Git Resource Proxy Service
- **Change:** Add explicit HTTP protocol annotation and name port
- **Purpose:** Ensure Linkerd detects HTTP traffic immediately (no protocol detection delay)
- **Configuration:**
  - Add `config.linkerd.io/protocol: "http"` annotation
  - Name port as "http" instead of unnamed

### 5. HAProxy Ingress Controller
- **Change:** Remove completely
- **Justification:** No longer needed; Linkerd provides superior load balancing

## Detailed Changes

### Chart.yaml
**Remove dependency:**
```yaml
# DELETE these lines:
- name: kubernetes-ingress
  version: 1.49.0
  repository: "https://haproxytech.github.io/helm-charts"
  condition: gitResourceProxy.enabled
```

### Chart.lock
**Regenerate:** Run `helm dependency update` to regenerate lock file without kubernetes-ingress dependency.

### values.yaml

**Add Linkerd injection for Concourse components:**
```yaml
concourse:
  web:
    # existing configuration...
    podAnnotations:
      linkerd.io/inject: "enabled"
  
  worker:
    # existing configuration...
    podAnnotations:
      linkerd.io/inject: "enabled"
```

**Add Linkerd injection for git-resource-proxy:**
```yaml
gitResourceProxy:
  enabled: true
  replicas: 10
  # existing configuration...
  podAnnotations:
    linkerd.io/inject: "enabled"
```

**Remove entire HAProxy configuration block (lines 146-185):**
```yaml
# DELETE entire kubernetes-ingress section
```

### templates/git-resource-proxy.yaml

**Update Service (git-resource-proxy-svc):**
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: git-resource-proxy
  annotations:
    config.linkerd.io/protocol: "http"  # ADD: Explicit HTTP declaration
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/targets: kubernetes
  name: git-resource-proxy-svc
spec:
  ports:
  - name: http  # CHANGE: Name the port explicitly
    port: 8080
    protocol: TCP
    targetPort: 8080
  selector:
    app: git-resource-proxy
  sessionAffinity: None
  type: ClusterIP
```

**Update Deployment to support podAnnotations:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: git-resource-proxy
spec:
  replicas: {{ .Values.gitResourceProxy.replicas }}
  selector:
    matchLabels:
      app: git-resource-proxy
  template:
    metadata:
      annotations:
        {{- if .Values.gitResourceProxy.podAnnotations }}
        {{- toYaml .Values.gitResourceProxy.podAnnotations | nindent 8 }}
        {{- end }}
      labels:
        app: git-resource-proxy
    spec:
      # ... rest of pod spec unchanged
```

**Remove Ingress resource (lines 54-73):**
```yaml
# DELETE entire Ingress resource
```

**Remove HAProxy selector Service (lines 76-88):**
```yaml
# DELETE the second Service that pointed to HAProxy ingress pods
```

## Protocol Detection

The git-resource-proxy uses standard HTTP/1.1 on port 8080 (Go net/http package). To ensure proper Linkerd protocol detection:

1. **Service annotation:** `config.linkerd.io/protocol: "http"` - Explicitly declares HTTP, bypassing detection
2. **Port naming:** Name port as "http" - Provides hint for protocol detection
3. **Result:** Linkerd immediately treats traffic as HTTP, enabling:
   - P2C load balancing
   - Request-level retries
   - Golden metrics (success rate, latency percentiles)
   - Traffic splitting capabilities

## Deployment Strategy

This is a direct cutover approach. The helm chart is deployed to 3 separate systems with different values files. Migration will be orchestrated manually:

1. Deploy to system 1
2. Verify load balancing and functionality
3. Deploy to system 2
4. Verify
5. Deploy to system 3

No feature toggle is needed since rollout is manual and controlled.

## Verification

After deployment to each environment, verify:

### 1. Linkerd Injection Success
```bash
kubectl get pods -n concourse -l app=git-resource-proxy -o jsonpath='{.items[0].spec.containers[*].name}'
# Should show: git-resource-proxy linkerd-proxy

kubectl get pods -n concourse -l app=concourse-ci3-web -o jsonpath='{.items[0].spec.containers[*].name}'
# Should show: concourse-ci3-web linkerd-proxy

kubectl get pods -n concourse -l app=concourse-worker-main -o jsonpath='{.items[0].spec.containers[*].name}'
# Should show: concourse-worker-main linkerd-proxy
```

### 2. HTTP Protocol Detection
```bash
linkerd viz stat svc/git-resource-proxy-svc -n concourse
# Should show HTTP metrics (success rate, RPS, latency percentiles)
```

### 3. Traffic Flow
```bash
linkerd viz tap deploy/concourse-ci3-web -n concourse | grep git-resource-proxy
# Should show live HTTP requests with response codes
```

### 4. Load Distribution
```bash
linkerd viz top deploy/git-resource-proxy -n concourse
# Should show traffic distributed across pods based on P2C algorithm
# Not uniform round-robin, but weighted by latency + load
```

### 5. mTLS Status
```bash
linkerd viz edges deploy -n concourse
# Should show "secured" status between web→proxy and worker→proxy
```

## Rollback Plan

If issues are encountered:

1. **Revert helm chart:** Deploy previous chart version with HAProxy dependency
2. **Run:** `helm dependency update` to restore kubernetes-ingress
3. **Deploy:** Standard helm upgrade with old values

Since this is a coordinated manual rollout across 3 systems, each system can be rolled back independently if needed.

## Benefits

1. **Superior load balancing:** P2C + EWMA is latency-aware, adapts faster than least-connections
2. **Reduced dependencies:** Eliminates outdated HAProxy ingress chart
3. **Security:** Automatic mTLS between all Concourse components
4. **Observability:** Golden metrics, live traffic tapping, distributed tracing support
5. **Resilience:** Automatic retries, circuit breaking, and failure detection
6. **Simplification:** One less component to maintain and upgrade

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Linkerd proxy overhead | Linkerd proxy is lightweight; overhead is minimal vs HAProxy hop |
| Protocol detection fails | Explicit `config.linkerd.io/protocol: "http"` annotation prevents this |
| Worker pods don't support podAnnotations | Standard Kubernetes feature; verify in first deployment |
| Load distribution differs from least-conn | P2C+EWMA is superior; monitor initial deployment for validation |

## Non-Goals

- Meshing other Concourse components (database, webhook broadcaster) - out of scope
- Linkerd configuration changes - using existing cluster-wide Linkerd as-is
- Multi-cluster or federation setup - single-cluster migration only
- Gradual/canary rollout within a system - direct cutover per system

## Success Criteria

1. HAProxy ingress dependency removed from Chart.yaml
2. All web, worker, and git-resource-proxy pods show 2 containers (app + linkerd-proxy)
3. Service shows HTTP protocol detection in `linkerd viz stat`
4. Live traffic visible in `linkerd viz tap`
5. Load distribution observable in `linkerd viz top`
6. No functional regressions in Concourse CI operations
7. Deployment successful across all 3 systems
