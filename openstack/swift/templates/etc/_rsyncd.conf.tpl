uid = swift
gid = swift
log file = /dev/stdout
# /var/log/swift is already writable by the user running rsyncd
pid file = /var/log/swift/rsyncd.pid
# TODO: set the replication IP here (or pass on cmdline with --address)
address = 0.0.0.0

# /etc/rsyncd: configuration file for rsync daemon mode

# See rsyncd.conf man page for more options.

# configuration example:

# uid = nobody
# gid = nobody
# use chroot = yes
# max connections = 4
# pid file = /var/run/rsyncd.pid
# exclude = lost+found/
# transfer logging = yes
# timeout = 900
# ignore nonreadable = yes
# dont compress   = *.gz *.tgz *.zip *.z *.Z *.rpm *.deb *.bz2

# [ftp]
#        path = /home/ftp
#        comment = ftp export area


[account]
max connections = 5
path = /srv/node
read only = false
lock file = /var/lock/account.lock


[container]
max connections = 15
path = /srv/node
read only = false
lock file = /var/lock/container.lock


[object]
max connections = 60
path = /srv/node
read only = false
lock file = /var/lock/object.lock
