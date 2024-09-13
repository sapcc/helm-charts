# percona-operator
A Helm chart to deploy MySQL instances using Percona Operator For MySQL custom resource definitions.

## Prerequisites
```shell=bash
helm dependency update helm
```

## Validate the Operator templates
```shell=bash
helm template percona-operator helm --namespace pxc-operator --values helm/operator.yaml
```

## Validate the Database templates
```shell=bash
helm template keystone-mysql helm --namespace keystone-pxc --values helm/database.yaml
```

## Installing the Operator resources
```shell=bash
helm upgrade percona-operator helm --install --namespace pxc-operator --create-namespace --values helm/operator.yaml
```

## Installing the database
```shell=bash
helm upgrade keystone-mysql helm --install --namespace keystone-pxc --create-namespace --values helm/database.yaml
```