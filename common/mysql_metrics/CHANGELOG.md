# Changelog

## v0.6.0 - 2025/11/10
* Add new `db_instance_name_literal` option to override target DB host
* Add new `db_namespace` option to override target DB namespace

## v0.5.2 - 2025/07/18
* Update sql-exporter version to 0.8.0 (2025-07-07)

## v0.5.1 - 2025/07/11
* Remove `queryCell2` option, `connections` are now used for multiple database targets
* Bump linkerd-support chart dependency to `1.1.0`

## v0.5.0 - 2025/06/10

* Update sql-exporter version to 0.6.0 (2025-06-10)

* Add a new `connections` option to allow multiple database targets.

This, with a defined explicit configuration, will be used instead of the `queryCell2` option.

* Remove the unused `customSources` option, because it requires a full database connection URL being passed as a value and therefore can't be used.

## v0.4.4 - 2025/04/17
* add reloader annotation to the deployment

## v0.4.3 - 2025/02/25
* add option to set vpa main container

## v0.4.2 - 2025/01/08

* Updated sql-exporter version to 0.5.9 (2025-01-07)
* Chart version bumped

## v0.4.1 - 2024/11/27

* Fixed imageTag string value
* Chart version bumped

## v0.4.0 - 2024/11/15

* Updated sql-exporter version to 0.5.8 build with latest vulnerability fixes (2024-11-14)
* Set kubectl.kubernetes.io/default-container annotation
* Chart version bumped
