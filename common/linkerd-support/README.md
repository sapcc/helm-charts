# linkerd-support

This chart contains some helpful bits and pieces for Linkerd enablement.
[Linkerd](https://linkerd.io/) is a service mesh that we mostly use for the purpose of encrypting in-cluster traffic.
This document will explain how to add your service to the Linkerd mesh.

## Step 1: Add this chart as a dependency

On each chart that you deploy, add this chart as a dependency:

```
$ cat Chart.yaml
...
dependencies:
  - name: linkerd-support
    repository: https://charts.eu-de-2.cloud.sap
    version: 0.1.0
```

Run `helm dep up` in the chart's root directory to generate the `Chart.lock` file.

### Control precisely when to enable meshing

By default, the chart will become active once the `.Values.global.linkerdEnabled` flag is set to true in the regional `globals.yaml`.
That means that, once Linkerd is deployed, your next deployment will add your service to the mesh.
If you need to control when the meshing takes place, you can add this chart as a conditional dependency.
For example:

```
$ cat Chart.yaml
...
dependencies:
  - name: linkerd-support
    repository: https://charts.eu-de-2.cloud.sap
    version: 0.1.0
    condition: linkerd_enabled
```

This will avoid Linkerd integration until you set `linkerd_enabled: true` in your chart's `values.yaml`.

## Step 2: Annotate your pods and services

Linkerd provides encrypted networking within the cluster, even if your applications communicate in plain text (e.g. HTTP instead of HTTPS)..
This is achieved by injecting a sidecar container into every pod.
The sidecar decrypts incoming traffic before passing it on to your application, and encrypts outgoing traffic as needed.

Similarly, each service needs to be similarly altered to handle incoming traffic from outside the mesh (unencrypted -> encrypted),
as well as traffic within the mesh (encrypted -> encrypted).

### Option 1: This Helm release is the only one in its namespace

You can add an annotation on the namespace level to make Linkerd inject itself into all pods and services at once.
Maintaining namespace labels as part of a Helm release is a bit tricky, so this Helm chart does it for you if you set:

```
$ cat values.yaml
...
linkerd-support:
  annotate_namespace: true
...
```

### Option 2: This Helm release shares its namespace with other deployments

Add this annotation to every PodSpec and every Service that you deploy:

```
metadata:
  annotations:
    linkerd.io/inject: enabled
```

If you used a conditional dependency in step 1, gate the annotation on the same conditional.
For example:

```
metadata:
  annotations:
    {{- if .Values.linkerd_enabled }}
    linkerd.io/inject: enabled
    {{- end }}
```

### Option 3: This Helm chart is part of different releases

Library charts, e.g. those in `common/`, may be included in different top-level charts with different opinions on Linkerd support.
You need to add annotations to all pods and services manually, as described in option 2.
To detect whether the top-level chart wants Linkerd support or not, check the `.Values.global.has_linkerd_support_chart` flag.

```
metadata:
  annotations:
    {{- if .Values.global.has_linkerd_support_chart }}
    linkerd.io/inject: enabled
    {{- end }}
```

## Step 3: Annotate your ingresses

If you have Ingress objects, the ingress-nginx needs to be told to talk to the service IP instead of the individual pod IPs.
This chart defines a template which you can add to the annotations of your Ingress objects.
For example:

```
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  annotations:
    kubernetes.io/tls-acme: "true"
    {{- include "linkerd_annotations_for_ingress" . | nindent 4 }}
```

If you used a conditional dependency in step 1, gate the annotations on the same conditional.
For example:

```
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  annotations:
    kubernetes.io/tls-acme: "true"
    {{- if .Values.linkerd_enabled }}
    {{- include "linkerd_annotations_for_ingress" . | nindent 4 }}
    {{- end }}
```
