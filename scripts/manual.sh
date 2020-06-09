#!/bin/sh
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
localname=`hostname`
unraid="/mnt/unraid"
working="$unraid/Cronjobs/rclone"

rclone move kilefam-db:/Camera\ Uploads/ $unraid/kilefam/Dropbox/Camera/
rclone copy --exlude Private/ $unraid/Photos/ kilefam-db:/
