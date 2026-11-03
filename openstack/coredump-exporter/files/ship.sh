#!/bin/sh
while read line; do export "$line" ; done < /etc/os-release

rclone "${RCLONE_OPERATION}" \
  --header-upload "X-Delete-After: ${SWIFT_DELETE_AFTER}" \
  --header-upload "X-Object-Meta-gardenlinux-version: ${GARDENLINUX_VERSION}" \
  --header-upload "X-Object-Meta-gardenlinux-cname: ${GARDENLINUX_CNAME}" \
  --header-upload "X-Object-Meta-gardenlinux-commit-id: ${GARDENLINUX_COMMIT_ID}" \
  --header-upload "X-Object-Meta-hostname: ${HOSTNAME}" \
  -M /data "swift://${SWIFT_CONTAINER}/"

while sleep "${POLLING_DELAY}"; do
  rclone "${RCLONE_OPERATION}" \
    --max-age "$((POLLING_DELAY + POLLING_FUDGING))" \
    --header-upload "X-Delete-After: ${SWIFT_DELETE_AFTER}" \
    --header-upload "X-Object-Meta-gardenlinux-version: ${GARDENLINUX_VERSION}" \
    --header-upload "X-Object-Meta-gardenlinux-cname: ${GARDENLINUX_CNAME}" \
    --header-upload "X-Object-Meta-gardenlinux-commit-id: ${GARDENLINUX_COMMIT_ID}" \
    --header-upload "X-Object-Meta-hostname: ${HOSTNAME}" \
    -M /data "swift://${SWIFT_CONTAINER}/"
done
