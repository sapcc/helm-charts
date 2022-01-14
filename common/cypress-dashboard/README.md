for tests:

* https://github.wdf.sap.corp/cc/secrets/blob/master/ci/shared/task-helm-upgrade.sh

```
helm3  --namespace cypress upgrade cypress-dashboard helm-charts/common/cypress-dashboard --install --namespace cypress --reset-values --timeout 300s --values secrets/qa-de-1/values/globals.yaml --values secrets/qa-de-1/values/domain-seeds.yaml --values secrets/scaleout/s-qa-de-1/values/cypress-dashboard.yaml --set-string version=20211216112555 --create-namespace
```

deployment is based on: https://github.com/sorry-cypress/sorry-cypress/blob/master/docker-compose.minio.yml