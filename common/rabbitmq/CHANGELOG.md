Rabbitmq CHANGELOG
==============

This file is used to list changes made in each version of the common chart rabbitmq.

0.4.0
-----
b.alkhateeb@sap.com
 - Updating rabbitmq docker image to 3.10.5-management (release note: https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.10.5).
 - using TCP socket check for the readinessProbe instead of deprecated rabbitmqctl node_health_check (resone: https://github.com/rabbitmq/cluster-operator/blob/43e7c05c4e5cf47322ef11b1b98b2bb70bf32a12/internal/resource/statefulset.go#L586-L604)
 - adding CHANGELOG

==============
