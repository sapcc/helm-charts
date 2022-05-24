#!/usr/bin/env bash

BACKUP=Backup-$(date +"%Y-%m-%d-%H%M%S")
BACKUPDIR=/root/backup/$BACKUP

mkdir -p $BACKUPDIR \
  && cp -r /host/etc/rancher/ $BACKUPDIR \
  && cp -r /host/var/lib/rancher/k3s/server $BACKUPDIR \
  && rm -rf $BACKUPDIR/server/db/ \
  && ls -la $BACKUPDIR \
  && aws s3 sync /root/backup/ s3://$AWS_BUCKET/ \
  && aws s3 ls $AWS_BUCKET/$BACKUP --recursive

if [ "$?" != "0" ]
then
  touch $BACKUPDIR/latest
  echo $BACKUP > $BACKUPDIR/latest
  aws s3 cp $BACKUPDIR/latest s3://$AWS_BUCKET/
fi
rm -rf $BACKUPDIR
