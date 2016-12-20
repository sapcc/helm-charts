{{- define "monasca_mysql_mon_schema_sql_tpl" -}}
CREATE DATABASE IF NOT EXISTS `mon` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `mon`;

SET foreign_key_checks = 0;

/*
 * Enum tables
 */
CREATE TABLE IF NOT EXISTS `alarm_state` (
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`name`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `alarm_definition_severity` (
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`name`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `notification_method_type` (
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`name`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `alarm` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alarm_definition_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `state` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OK',
  `lifecycle_state` varchar(50) DEFAULT NULL,
  `link` varchar(512) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `state_updated_at` datetime,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `alarm_definition_id` (`alarm_definition_id`),
  CONSTRAINT `fk_alarm_definition_id` FOREIGN KEY (`alarm_definition_id`) REFERENCES `alarm_definition` (`id`) ON DELETE CASCADE
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `alarm_action` (
  `alarm_definition_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alarm_state` enum('UNDETERMINED','OK','ALARM') COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`alarm_definition_id`,`alarm_state`,`action_id`),
  CONSTRAINT `fk_alarm_action_alarm_definition_id` FOREIGN KEY (`alarm_definition_id`) REFERENCES `alarm_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_alarm_action_notification_method_id` FOREIGN KEY (`action_id`) REFERENCES `notification_method` (`id`) ON DELETE CASCADE
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `alarm_definition` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenant_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expression` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `severity` enum('LOW','MEDIUM','HIGH','CRITICAL') COLLATE utf8mb4_unicode_ci NOT NULL,
  `match_by` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT '',
  `actions_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `tenant_id` (`tenant_id`),
  KEY `deleted_at` (`deleted_at`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `alarm_metric` (
  `alarm_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `metric_definition_dimensions_id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  PRIMARY KEY (`alarm_id`,`metric_definition_dimensions_id`),
  KEY `alarm_id` (`alarm_id`),
  KEY `metric_definition_dimensions_id` (`metric_definition_dimensions_id`),
  CONSTRAINT `fk_alarm_id` FOREIGN KEY (`alarm_id`) REFERENCES `alarm` (`id`) ON DELETE CASCADE
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `metric_definition` (
  `id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenant_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `metric_definition_dimensions` (
  `id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `metric_definition_id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `metric_dimension_set_id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  KEY `metric_definition_id` (`metric_definition_id`),
  KEY `metric_dimension_set_id` (`metric_dimension_set_id`),
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

/*
 * mysql limits the size of a unique key to 767 bytes. The utf8mb4 charset requires
 * 4 bytes to be allocated for each character while the utf8 charset requires 3 bytes.
 * The utf8 charset should be sufficient for any reasonable characters, see the definition
 * of supplementary characters for what it doesn't support.
 * Even with utf8, the unique key length would be 785 bytes so only a subset of the
 * name is used. Potentially the size of the name should be limited to 250 characters
 * which would resolve this issue.
 *
 * The unique key is required to allow high performance inserts without doing a select by using
 * the "insert into metric_dimension ... on duplicate key update dimension_set_id=dimension_set_id
 * syntax
 */
CREATE TABLE IF NOT EXISTS `metric_dimension` (
  `dimension_set_id` binary(20) NOT NULL DEFAULT '\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0',
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `value` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
   UNIQUE KEY `metric_dimension_key` (`dimension_set_id`,`name`(252)),
   KEY `dimension_set_id` (`dimension_set_id`)
) DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci COMMENT='PRIMARY KEY (`id`)';

CREATE TABLE IF NOT EXISTS `notification_method` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenant_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `address` varchar(512) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `period` int NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sub_alarm_definition` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alarm_definition_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `function` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `metric_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `operator` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `threshold` double NOT NULL,
  `period` int(11) NOT NULL,
  `periods` int(11) NOT NULL,
  `is_deterministic` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_sub_alarm_definition` (`alarm_definition_id`),
  CONSTRAINT `fk_sub_alarm_definition` FOREIGN KEY (`alarm_definition_id`) REFERENCES `alarm_definition` (`id`) ON DELETE CASCADE
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sub_alarm_definition_dimension` (
  `sub_alarm_definition_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `dimension_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  CONSTRAINT `fk_sub_alarm_definition_dimension` FOREIGN KEY (`sub_alarm_definition_id`) REFERENCES `sub_alarm_definition` (`id`) ON DELETE CASCADE
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `sub_alarm` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alarm_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `sub_expression_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `expression` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `state` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'OK',
  PRIMARY KEY (`id`),
  KEY `fk_sub_alarm` (`alarm_id`),
  KEY `fk_sub_alarm_expr` (`sub_expression_id`),
  CONSTRAINT `fk_sub_alarm` FOREIGN KEY (`alarm_id`) REFERENCES `alarm` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_alarm_state` FOREIGN KEY (`state`) REFERENCES `alarm_state` (`name`),
  CONSTRAINT `fk_sub_alarm_expr` FOREIGN KEY (`sub_expression_id`) REFERENCES `sub_alarm_definition` (`id`)
);

CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `version` varchar(255) NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) DEFAULT CHARSET=latin1;

/*
 * The tables needed by Monasca for event stream definitions
 */
CREATE TABLE IF NOT EXISTS `stream_actions` (
  `stream_definition_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_type` enum('FIRE','EXPIRE') COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`stream_definition_id`,`action_id`,`action_type`),
  KEY `stream_definition_id` (`stream_definition_id`),
  KEY `action_type` (`action_type`),
  KEY `fk_stream_action_notification_method_id` (`action_id`),
  CONSTRAINT `fk_stream_action_stream_definition_id` FOREIGN KEY (`stream_definition_id`) REFERENCES `stream_definition` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_stream_action_notification_method_id` FOREIGN KEY (`action_id`) REFERENCES `notification_method` (`id`) ON DELETE CASCADE
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `stream_definition` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenant_id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(190) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `select_by` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `group_by` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fire_criteria` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `expiration` int(10) UNSIGNED DEFAULT '0',
  `actions_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `deleted_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenant_name` (`tenant_id`,`name`),
  KEY `name` (`name`),
  KEY `tenant_id` (`tenant_id`),
  KEY `deleted_at` (`deleted_at`),
  KEY `created_at` (`created_at`),
  KEY `updated_at` (`updated_at`)
) DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

GRANT SELECT ON mon.* TO 'notification'@'%' IDENTIFIED BY '{{.Values.monasca_mysql_notification_password}}';
GRANT SELECT ON mon.* TO 'notification'@'localhost' IDENTIFIED BY '{{.Values.monasca_mysql_notification_password}}';

GRANT ALL ON mon.* TO 'monapi'@'%' IDENTIFIED BY '{{.Values.monasca_mysql_monapi_password}}';
GRANT ALL ON mon.* TO 'monapi'@'localhost' IDENTIFIED BY '{{.Values.monasca_mysql_monapi_password}}';

GRANT ALL ON mon.* TO 'thresh'@'%' IDENTIFIED BY '{{.Values.monasca_mysql_thresh_password}}';
GRANT ALL ON mon.* TO 'thresh'@'localhost' IDENTIFIED BY '{{.Values.monasca_mysql_thresh_password}}';

/* grant access to local agent user */
GRANT USAGE ON *.* TO 'mon-agent'@'localhost' WITH GRANT OPTION;
{{ end }}
