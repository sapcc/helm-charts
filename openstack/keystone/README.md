# Keystone

This chart deploys Keystone's API, a role-assignment repair CronJob, and their
database/cache dependencies. Startup and upgrade ordering is implemented by
ordinary Kubernetes Jobs and `kubernetes-entrypoint` dependency checks.

## Jobs

- **`db-expansion`** runs when `run_db_migration` is true: full `db_sync` on
  installation, or `db_sync --expand` on upgrade.
- **`job-bootstrap`** waits for database preparation, when enabled, then runs
  native and extension bootstrap. API and repair pods wait for this Job.
- **`job-creds-migrate`** re-encrypts credentials with the current primary key
  in a separate Job, once the database Service is ready.
- **`db-contraction`** runs after expansion on upgrades. It waits for
  bootstrap and credential migration, checks the target API revision is ready, then runs
  `db_sync --contract` and verifies the final schema. Earlier revisions of
  these Jobs must no longer be able to run,
  old API ReplicaSets must have no replicas, and old pods must have terminated.
- **`repair-assignments`** is scheduled by its CronJob. Each run waits for
  expansion and bootstrap before repairing role assignments.

The initialization/expansion Job retains the existing pre-migration
`keystone-status upgrade check` (warnings are accepted) and post-migration
`keystone-manage doctor` diagnostics. These checks are not yet consolidated.

## Dependencies

Solid arrows show Job/Service prerequisites; dashed arrows show resource-state
checks. Transitive dependencies are omitted. Job names include the release name
and Helm revision. The API never waits for contraction.

Complete an upgrade before starting the next: previous-revision Jobs and
script ConfigMaps are not retained when Helm replaces them.

The graphs assume `run_db_migration: true`. When false, both database migration
Jobs are omitted and the schema must already be prepared. Installation uses a
full synchronization and does not need a separate contraction Job.

### Installation

```mermaid
flowchart TD
    DB[Database] --> MIG[db-expansion]
    MIG --> BOOT[job-bootstrap]
    CACHE[Memcached] --> BOOT
    DB --> CREDS[job-creds-migrate]
    BOOT --> API[API]
    BOOT --> REPAIR[repair-assignments Job]
```

### Upgrade

```mermaid
flowchart TD
    DB[Database] --> MIG[db-expansion]
    MIG --> BOOT[job-bootstrap]
    CACHE[Memcached] --> BOOT
    DB --> CREDS[job-creds-migrate]
    BOOT --> API[API]
    BOOT --> REPAIR[repair-assignments Job]
    BOOT --> CONTRACT[db-contraction]
    CREDS --> CONTRACT
    API -.-> CONTRACT

    subgraph OLD[Previous-revision Jobs and resources]
        OLD_MIG[db-expansion]
        OLD_BOOT[job-bootstrap]
        OLD_CREDS[job-creds-migrate]
        OLD_CONTRACT[db-contraction]
        OLD_REPAIR[repair-assignments Job]
        OLD_RS[ReplicaSets]
        OLD_PODS[Pods]
    end
    OLD -.-> CONTRACT
```
