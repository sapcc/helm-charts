# linkerd-support

[Linkerd](https://linkerd.io/) is a service mesh that we mostly use for the purpose of encrypting in-cluster traffic.
This chart contains some helpful bits and pieces for Linkerd enablement.
This document explains how to add your service to the Linkerd mesh.

## Step 1: Add this chart as a dependency

On each chart that you deploy, add this chart as a dependency:

```console
$ cat Chart.yaml
...
dependencies:
  - name: linkerd-support
    repository: oci://keppel.eu-de-1.cloud.sap/ccloud-helm
    version: ~1
```

Run `helm dep up` in the chart's root directory to generate the `Chart.lock` file.

> [!NOTE]  
> OCI support in Helm is generally available since version 3.8.0. If you are still using an older version, you must first upgrade to an up-to-date version of helm.

You also need to set the field `.Values.global.linkerd_requested` in your top-level chart.
No Linkerd annotations will be rendered unless this flag is set to true.
This allows you to control when to add your service to the mesh.

```console
$ cat values.yaml
global:
  linkerd_requested: true
```

We know that the placement of this declaration is awkward, but it absolutely needs to be in the top-level chart.
This is the only location from where the declaration can be seen by all the places that need to see it (esp. across subcharts).

## Step 2: Annotate your pods and services

Linkerd provides encrypted networking within the cluster, even if your applications communicate in plain text (e.g. HTTP instead of HTTPS).
This is achieved by injecting a sidecar container into every pod.
The sidecar decrypts incoming traffic before passing it on to your application, and encrypts outgoing traffic as needed.

Similarly, each service needs to be similarly altered to handle incoming traffic from outside the mesh (unencrypted -> encrypted),
as well as traffic within the mesh (encrypted -> encrypted).

### Standard option

Add this annotation to every PodSpec and every Service that you deploy:

```yaml
metadata:
  annotations:
    {{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
    linkerd.io/inject: enabled
    {{- end }}
```

Use exactly this conditional statement around each such annotation.

Affected pods need to be restarted to get the sidecar webhook injection.

### Simplified option: This Helm release is the only one in its namespace

If your Helm release is the only one on its namespace, you can annotate the entire namespace instead of each individual pod and service.
The annotation on the namespace level to make Linkerd inject itself into all pods and services at once.
Maintaining namespace labels as part of a Helm release is a bit tricky, so this Helm chart does it for you if you set:

```console
$ cat values.yaml
...
linkerd-support:
  annotate_namespace: true
...
```

## Step 3: Annotate your ingresses

For services wrapped by Linkerd, the ingress-nginx needs to be told to talk to the service IP instead of the individual pod IPs.

Add this annotation to every Ingress that you deploy:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress

metadata:
  annotations:
    {{- if and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested }}
    ingress.kubernetes.io/service-upstream: "true"
    nginx.ingress.kubernetes.io/service-upstream: "true"
    {{- end }}
```

Use exactly this conditional statement around each such annotation.

## Step 4: Jobs and CronJobs require special care

The annotations that we added in step 2 cause Linkerd to add a sidecar container to all respective pods.
For long-running pods that are part of Deployments, DaemonSets or StatefulSets, this does not require any additional care.
For short-lived pods that are part of Jobs and CronJobs, we need to make the Linkerd sidecar container terminate once the main container is done.
Otherwise, the job pod will linger even after its work is complete.

The solution recommended by upstream is to bundle the `linkerd-await` tool into your job's container image.
This tool signals to the Linkerd sidecar container to shutdown once the main container is done, thus allowing the pod termination to proceed.
To integrate `linkerd-await`, please follow the [example from the upstream repo](https://github.com/linkerd/linkerd-await/blob/main/README.md#examples).

Once the image is updated, add this environment variable to all containers that use this image:

```yaml
spec:
  containers:
    - name: myapp
      env:
        {{- if not (and $.Values.global.linkerd_enabled $.Values.global.linkerd_requested) }}
        - name: LINKERD_AWAIT_DISABLED
          value: "Linkerd was not enabled or not requested"
        {{- end }}
```

Use exactly this conditional statement around each such environment variable declaration.
