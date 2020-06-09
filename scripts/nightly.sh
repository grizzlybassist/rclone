#!/bin/sh
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
localname=`hostname`
unraid="/mnt/unraid"
working="$unraid/Cronjobs/rclone"

now=$(date +"%Y-%m-%d")
month=$(date +"%Y-%m")
year=$(date +"%Y")
wlogs="$working/logs"
mkdir -p $wlogs
#ropts='--rc --exclude .AppleDB --retries 20 --transfers 32 --bwlimit "09:00,0.625M 18:00,1.25M 22:00,off" -q sync'
ropts="--rc --exclude .AppleDB --retries 20 --transfers 32 --bwlimit 1M -q sync"

exec 1>> $wlogs/nightly-$now.log
exec 2>> $wlogs/nightly-$now.log

config="$working/config/$localname-nightly.cfg"
config2="$working/config/$localname-ec-nightly.cfg"
echo "-------------------------------start----------------------------"
echo "$(date) $localname rclone backup"

rclone_backup()
{
	rcin=$1/$2
	rcout=$3/$2

	echo "----------------------------------------------------------------"
	echo "Copying files from $rcin to $rcout at $(date)"
	rclone $ropts $rcin $rcout
	rcerror=$?
	
	sharesize=$(rclone -q size $rcout | awk '/Total size/ {print $3 " " $4}')
	sharevsize=$(rclone -q --b2-versions size $rcout | awk '/Total size/ {print $3 " " $4}')
	echo "Completed copy of $rcin at $(date) with error code $rcerror"
	echo "Total size of $rcout is:"
	echo "$sharesize"
	echo "Total size of $rcout with VERSIONS is:"
	echo "$sharevsize"
	
	if [ ! $rcerror -eq 0 ]
	then
		mkdir -p $unraid/Errors
		cp $wlogs/nightly-$now.log $unraid/Errors/rclone-nightly-$now.log
	fi
}

compute_total()
{
	echo "----------------------------------------------------------------"
	rcout=$1

	totalsize=$(rclone -q size $rcout | awk '/Total size/ {print $3 " " $4}')
	totalvsize=$(rclone -q --b2-versions size $rcout | awk '/Total size/ {print $3 " " $4}')
	echo "Total storage on $rcout is:"
	echo "$totalsize"
	echo "Total storage on $rcout with VERSIONS is:"
	echo "$totalvsize"
}

if [ $# -eq 3 ]
then
	if [ -d $1/$2 ]
	then
		rclone_backup $1 $2 $3
		compute_total $3
	fi
elif [ ! -f /tmp/rclone.pause ]
then
	touch /tmp/rclone.pause
	clone=`cat $config | awk '{print $1}' | tr "\n" " "`
	for c in ${clone}
	do
		rclone_backup /mnt $c b2:kile-nas1
	done
#	eclone=`cat $config2 | awk '{print $1}' | tr "\n" " "`
#	for e in ${eclone}
#	do
#		rclone_backup $unraid $e b2-ec:
#	done
	compute_total b2:kile-nas1
#	compute_total b2-ec:
	rm /tmp/rclone.pause
fi

echo "-------------------------------done-----------------------------"
