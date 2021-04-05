Chartmuseum
-----------

This helm chart installs a [helm/chartmuseum](https://github.com/helm/chartmuseum) ready for SAP Converged Cloud Enterprise Edition.  
Helm chart archives are stored in OpenStack Swift. 


Concourse integration
---------------------

Helm charts can be consumed directly from the chartmuseum.

Example for integrating the chartmuseum with the Concourse CI and the `cathive/concourse-chartmuseum-resource` resource.


```yaml
resource_types:
    
    ...

    - name: chartmuseum
      type: docker-image
      source:
        repository: cathive/concourse-chartmuseum-resource
        tag: 0.6.0
    
    ...

resources:

    ...
    - name: helm-chart-kube-monitoring
      type: chartmuseum
      source:
         server_url: < helm-chart-repository-url >
         chart_name: myChart
    
    ...

jobs:
    
    - name: test-new-chart
      plan:
      - get: myChart
        trigger: true

      - task: helm-diff
        config:
          platform: 'linux'
          image_resource:
            type: docker-image
            source:
              repository: golang
              tag: 1.12-alpine
          inputs:
            - name: myChart
          run:
            path: /bin/sh
            args:
              - -c
              - |
                helm diff upgrade <releaseName> myChart.tgz ...
```
