# mariadb-operator
A Helm chart to deploy MariaDB instances using MariaDB Operator custom resource definitions.

## Prerequisites
```shell=bash
helm dependency update helm
```

## Validate the Operator templates
```shell=bash
helm template mariadb-operator helm --namespace mariadb-operator --values helm/operator.yaml
```

## Validate the Database templates
```shell=bash
helm template keystone-mariadb helm --namespace keystone-mariadb --values helm/database.yaml
```

## Installing the Operator resources
```shell=bash
helm upgrade mariadb-operator helm --install --namespace mariadb-operator --create-namespace --values helm/operator.yaml
```

## Installing the database
```shell=bash
helm upgrade keystone-mariadb helm --install --namespace keystone --create-namespace --values helm/database.yaml
```