# Elktools for Hermes

[Elktools](https://github.com/sapcc/hermes/elktools)

Current elktools:

## Elasticsearch restore from swift

By default the value in the values file for elasticsearch_restore_enabled is set to false.  This is to prevent an unintentional restore of elasticsearch data which could result in duplicate entries.  The current restore process is meant to restore to an elasticsearch which has none of the data currently backed up in swift.

Restore process:

 1. Populate your values files with the correct values for your environment or point to a values file that is correct.

 2. cd to the elktools directory

 3. Helm install the chart.  Note that you must override the value for hermes.elastic_search_restore_enabled in order to deploy the chart.
    
         `helm upgrade --install hermes-elastic-restore . --namespace hermes --set hermes.elasticsearch_restore_enabled=true -f <location to values file>`

 4. Optionally override the elasticsearch host location in your values file by adding an override to the helm install command:
        
        `--set hermes.elasticsearch_host=someelasticsearch` 

 5. This will create a job in the hermes namespace and a pod to run the job.  You can monitor this job with `kubectl get jobs -n hermes` and `kubectl describe job -n hermes restore-elasticsearch` or read the logs of the pod with `kubectl logs -n hermes elasticsearch-restore`

 6.  When the job has completed it will have loaded all events from the swift container specified in your values file to the elasticsearch host specified in your values file, or the elasticsearch overridden on the cli.
