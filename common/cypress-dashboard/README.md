for tests:

- https://github.wdf.sap.corp/cc/secrets/blob/master/ci/shared/task-helm-upgrade.sh

```
helm3  --namespace cypress upgrade cypress-dashboard helm-charts/common/cypress-dashboard --install --namespace cypress --reset-values --timeout 300s --values secrets/qa-de-1/values/globals.yaml --values secrets/qa-de-1/values/domain-seeds.yaml --values secrets/scaleout/s-qa-de-1/values/cypress-dashboard.yaml --set-string version=20211216112555 --create-namespace
```

deployment is based on: https://github.com/sorry-cypress/sorry-cypress/blob/master/docker-compose.minio.yml

## Upgrade

1. check first the latest release and what was changed https://github.com/sorry-cypress/sorry-cypress
2. check also the docker-compose [file](https://github.com/sorry-cypress/sorry-cypress/blob/master/docker-compose.minio.yml) for changes (on this is based the deployment)
3. adjust the values.yaml file and increase the version number for `dashboard`, `api` and `director`
4. before commit the changes you need to pull the images into the `keppel docker mirror` (you need to logon to `eu-de-1/ccadmin` first) otherwise the deployment will fail

```bash
  docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/agoldis/sorry-cypress-api:VERSION
  docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/agoldis/sorry-cypress-director:VERSION
  docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/agoldis/sorry-cypress-dashboard:VERSION
```

6. commit the changes and check the deployment
7. if everything comes up without issues you can update the minion in the values.yaml file
8. for latest version of minio [check](https://github.com/minio/minio/releases), for latest version of minio-mc [check](https://github.com/minio/mc/releases) and adjust the version for `minio` and `minio_mc` in the values.yaml file
9. pull the image into the `keppel docker mirror`

```bash
  docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/minio/minio:VERSION
  docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/minio/mc:VERSION
```

10. commit the changes and check the deployment
11. optional check the version of mongodb that is used [here](https://github.com/sorry-cypress/sorry-cypress/blob/master/docker-compose.minio.yml) and adjust the version in the values.yaml file
12. also pull the image into the `keppel docker mirror`

```bash
  docker pull keppel.eu-de-1.cloud.sap/ccloud-dockerhub-mirror/library/mongo:VERSION
```

13. commit the changes and check the deployment
