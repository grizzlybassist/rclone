#!/bin/sh
SHELL=/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin
localname=`hostname`
unraid="/mnt/unraid"
working="$unraid/Cronjobs/rclone"
archive="b2:kile-nas1-archive"

now=$(date +"%Y-%m-%d")
month=$(date +"%Y-%m")
smonth=$(date +"%m")
year=$(date +"%Y")
wlogs="$working/logs"
mkdir -p $wlogs
ropts="--retries 20 --transfers 32 --bwlimit 4M -q move"

exec 1>> $wlogs/archive-$month.log
exec 2>> $wlogs/archive-$month.log

config="$working/config/$localname-archive.cfg"
echo "-------------------------------start----------------------------"
echo "$(date) $localname Archive to BackBlaze B2"

exclmonth=2

create_exclude()
{
	exclmonth=$1
	touch $2
	c=$exclmonth
	while [ $c -ge 0 ]
	do
		mo=`expr $smonth - $c`
		if [ $mo -gt 0 ]
		then
			mo=$(printf "%02d" $mo)
			echo "/$year-$mo/**" >> $2
		elif [ $mo -le 0 ]
		then
			ys=$(( 1 + ($mo / -12) ))
			ad=$(( $ys * 12 ))
			mo=$(( $mo + $ad ))
			lyear=$(( $year - $ys ))
			mo=$(printf "%02d" $mo)
			echo "/$lyear-$mo/**" >> $2
		fi
		c=$(( $c - 1 ))
	done
}

folder_archive()
{
	rando=`cat /dev/urandom | tr -cd 'a-f0-9' | head -c 32`
	exclfile="/tmp/excl$rando"

	rcin="$1"
	rcout="$archive/$2"
	ropts2="--exclude-from $exclfile"

	if [ -d $rcin ]
	then
		create_exclude $3 $exclfile
		echo "----------------------------------------------------------------"
		echo "Moving files from $rcin to $rcout at $(date)"
		rclone $ropts2 $ropts $rcin $rcout
		echo "Completed archive of $rcin at $(date) with error $?"
		find "$rcin/"* -empty -type d -delete
		rm $exclfile
	else
		echo "----------------------------------------------------------------"
		echo "Skipping $rcin, folder does not exist"
	fi
}

if [ $# -ge 3 ]
then
	folder_archive $1 $2 $3
else
	loca=`cat $config | awk '{print $1}' | tr "\n" " "`
	for s in ${loca}
	do
		nama=`grep $s $config | awk '{print $2}'`
		keep=`grep $s $config | awk '{print $3}'`
		folder_archive $s $nama $keep
	done
fi

echo "-------------------------------done-----------------------------"
