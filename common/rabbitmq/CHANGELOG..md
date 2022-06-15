Rabbitmq CHANGELOG
==============

This file is used to list changes made in each version of the common chart rabbitmq.

0.4.0
-----
b.alkhateeb@sap.com
 - Updating rabbitmq docker image to 3.10.5-management (release note: https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.10.5).
 - using lifecycle postStart script to configure the upstream rabbitmq image.
 - removing rabbitmq-start script as it is not needed for configuring the container anymore.

==============
