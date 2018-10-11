# MariaDB-specific config file.
# Read by /etc/mysql/my.cnf

[client]
# Default is Latin1, if you need UTF-8 set this (also in server section)
#default-character-set = utf8 

[mysqld]
#
# * Character sets
# 
# Default is Latin1, if you need UTF-8 set all this (also in client section)
#
#character-set-server  = utf8 
#collation-server      = utf8_general_ci 
#character_set_server   = utf8 
#collation_server       = utf8_general_ci 
max_connections		= 250
innodb_buffer_pool_size	= 512M
innodb_open_files       = 1000
