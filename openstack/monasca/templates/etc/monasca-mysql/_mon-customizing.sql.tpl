USE `mon`;

SET foreign_key_checks = 1;

/* provide data for enum tables */
INSERT IGNORE INTO `alarm_state` VALUES ('UNDETERMINED');
INSERT IGNORE INTO `alarm_state` VALUES ('OK');
INSERT IGNORE INTO `alarm_state` VALUES ('ALARM');

INSERT IGNORE INTO `alarm_definition_severity` VALUES ('LOW');
INSERT IGNORE INTO `alarm_definition_severity` VALUES ('MEDIUM');
INSERT IGNORE INTO `alarm_definition_severity` VALUES ('HIGH');
INSERT IGNORE INTO `alarm_definition_severity` VALUES ('CRITICAL');

INSERT IGNORE INTO `notification_method_type` VALUES ('EMAIL');
INSERT IGNORE INTO `notification_method_type` VALUES ('WEBHOOK');
/* INSERT IGNORE INTO `notification_method_type` VALUES ('PAGERDUTY'); */
INSERT IGNORE INTO `notification_method_type` VALUES ('SLACK');

COMMIT;

CREATE OR REPLACE VIEW mon.v_leftovers AS select * from metric_definition_dimensions LEFT JOIN alarm_metric ON alarm_metric.metric_definition_dimensions_id = metric_definition_dimensions.id where alarm_metric.metric_definition_dimensions_id IS NULL;

CREATE OR REPLACE VIEW mon.v_monrows AS SELECT table_name, table_rows FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'mon';
