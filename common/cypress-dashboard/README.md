for tests:

```
helm3  --namespace cypress upgrade cypress-dashboard helm-charts/common/cypress-dashboard --install --namespace cypress --reset-values --timeout 300s --values secrets/qa-de-1/values/globals.yaml --values secrets/qa-de-1/values/domain-seeds.yaml --values secrets/scaleout/s-qa-de-1/values/cypress-dashboard.yaml --set-string version=20211216112555 --create-namespace
```