# mariadb

## Table maintenance

The mariadb chart supports the following table maintenance functions.

### analyzeTable

The [analyzeTable](https://mariadb.com/kb/en/analyze-table/) function analyzes the specified tables to [improve the query performance](https://mariadb.org/mariadb-30x-faster/). The function needs 3 parameters to be configured.
- `job.maintenance.enabled` enables the maintenance job
- `job.maintenance.function.analyzeTable.enabled` enables the `analyzeTable` function
- `job.maintenance.function.analyzeTable.tables` specifies the table names (database.table) to be analyzed, or
- `job.maintenance.function.analyzeTable.allTables` to analyze all tables in all non system databases

```yaml
job:
  maintenance:
    enabled: true
    function:
      analyzeTable:
        enabled: true
        tables:
          - keystone.user
          - keystone.project
```

```yaml
job:
  maintenance:
    enabled: true
    function:
      analyzeTable:
        enabled: true
        allTables: true
```

The [schedule](https://crontab.guru/) can be configured using the `job.maintenance.schedule` parameter. The default value is randomly generated.

- minutes (1 to 59)
- hours (9 to 15)
- any day of the month
- any month of the year
- Tuesday (2) to Thursday (4)

Examples:
```
24 10 * * 2 # Tuesday at 10:24am
5 9 * * 2 # Tuesday at 9:05am
23 15 * * 4 # Thursday at 3:23pm
5 14 * * 3 # Wednesday at 14:05pm
```

If you define a custom `.schedule` the minute value will be randomly generated only if a **simple integer** or **invalid value** has been provided. This avoids that the job will be scheduled for all database instances at the same time or that it will fail due to a syntax error.

Examples:
```
24 10 * * 2     ==> 33 10 * * 20     # only the minute value is randomly generated
x 10 * * 2      ==> 17 10 * * 2      # only the minute value is randomly generated
* 10 * * 2      ==> * 10 * * 2       # the schedule will not be randomized
? 10 * * 2      ==> ? 10 * * 2       # the schedule will not be randomized
*/5 10 * * 2    ==> */5 10 * * 2     # the schedule will not be randomized
?/5 10 * * 2    ==> ?/5 10 * * 2     # the schedule will not be randomized
1-22 10 * * 2   ==> 1-22 10 * * 2    # the schedule will not be randomized
```

```yaml
job:
  maintenance:
    enabled: true
    function:
      analyzeTable:
        enabled: true
        tables:
          - keystone.user
          - keystone.project
    schedule: "0 2 * * *" # daily at 2 AM
```

The timezone for the job schedule can be configured with the `job.maintenance.timeZone` parameter. The default value is `Etc/UTC`.

#### Maintenance Job results

If enabled 3 objects will be created in the Kubernetes cluster:
- the cronjob

`kubectl get cronjob -l app.kubernetes.io/component=mariadb-cronjob-maintenance`

```shell
NAME                          SCHEDULE      TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
keystone-mariadb-maint-myqb   */2 * * * *   <none>     False     0        44s             12m
```

- the job created by the cronjob based on the schedule

`kubectl get job -l app.kubernetes.io/component=mariadb-cronjob-maintenance`

```shell
NAME                                   STATUS     COMPLETIONS   DURATION   AGE
keystone-mariadb-maint-myqb-28989828   Complete   1/1           2s         98s
```

- the pod

`kubectl get pod -l app.kubernetes.io/component=mariadb-cronjob-maintenance`

```shell
NAME                                         READY   STATUS      RESTARTS   AGE
keystone-mariadb-maint-myqb-28989830-wzfxh   0/1     Completed   0          20s
```

The logs of the pod can be queried using the following command:
`kubectl logs -l app.kubernetes.io/component=mariadb-cronjob-maintenance`
```json
{"@timestamp":"2025-02-12T19:52:00+UTC","ecs.version":"1.6.0","log.logger":"/usr/bin/mariadb-cronjob-maintenance.sh","log.origin.function":"analyzeTable","log.level":"info","message":"analyze table keystone.user"}
{"@timestamp":"2025-02-12T19:52:00+UTC","ecs.version":"1.6.0","log.logger":"/usr/bin/mariadb-cronjob-maintenance.sh","log.origin.function":"analyzeTable","log.level":"info","message":"analyze table keystone.user done"}
{"@timestamp":"2025-02-12T19:52:00+UTC","ecs.version":"1.6.0","log.logger":"/usr/bin/mariadb-cronjob-maintenance.sh","log.origin.function":"analyzeTable","log.level":"info","message":"analyze table keystone.project"}
{"@timestamp":"2025-02-12T19:52:00+UTC","ecs.version":"1.6.0","log.logger":"/usr/bin/mariadb-cronjob-maintenance.sh","log.origin.function":"analyzeTable","log.level":"info","message":"analyze table keystone.project done"}
```

### Maintainance Job reference

```yaml
job:
  maintenance:
    enabled:
    function:
      analyzeTable:
        enabled:
        tables:
        allTables:
    schedule:
    startingDeadlineSeconds:
    jobRestartPolicy:
    concurrencyPolicy:
    successfulJobsHistoryLimit:
    failedJobsHistoryLimit:
    priority_class:
    timeZone:
    resources:
      requests:
        memory:
        cpu:
```
