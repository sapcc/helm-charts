DISCO - Designate IngresS Cname Operator
----------------------------------------

Install the [DISCO](https://github.com/sapcc/kubernetes-operators/tree/master/disco) which automatically discovers Ingresses in the Kubernetes cluster and creates corresponding CNAMEs in OpenStack Desginate.

## Configuration

For a full list of configurable parameters and more details see the [values](./values.yaml).

| Parameter                 | Description                                                                                                                       | Default   |
|---------------------------|-----------------------------------------------------------------------------------------------------------------------------------|-----------|
| record                    | Record which should be used for CNAMES. e.g.: `ingress.domain.tld.`.                                                              | ``        |                    
| seed.enabled              | Enable the OpenStack seed for the service user described in the openstack section below.                                          | `false`   |
| openstack                 | Credentials of the service user who creates the recordsets in OpenStack Designate. <br> See [values](./values.yaml) for details.  | `{}`      |
| ingressAnnotation         | Only an ingress with this annotation will be considered.                                                                          | `disco`   |
| rbac.create               | Whether to create RBAC resources.                                                                                                 | `false`   |
| rbac.serviceAccountName   | The name of the service account.                                                                                                  | `default` |
