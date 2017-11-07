#!/usr/bin/env bash

#
# This script can help you to create backup of simple Zabbix instance.
# It makes tar archives of config and scripts directories. Also it makes MySQL backup with
# Percona Xtrabackup utility (innobackupex) whitch you should install yourself.
# After all it makes compressed archive contains all collected data using gzip, bzip2 or xz.
# After a few tests I reccomend to use lbzip2. It makes archive faster, but almost
# two times bigger than xz. Gzip it fine too, but as bzip2, rather slow (in my case).
#

### Setttings ###
# Directories and files
DEST=/mnt/nfs/shv-mon01				# Where we should  store final archive
TMP=/var/tmp/zbx_backup				# Where to store temp MySQL backup, before it will be compress
TIMESTAMP=`date +%d.%m.%Y.%H%M%S`	# Current timestamp
LOGFILE=$DEST/backuplog.log			# Logfile location
ROTATION=10							# How many old archives we should store

# Database backup settings
DB_USER="root"
DB_PASS=`cat /root/.mysql`
DB_BACKUP_DST=$TMP/zbx_mysql_files_$TIMESTAMP

# Parsing arguments to find compress program
COMP_PROG=$1
case "$COMP_PROG" in
	"gz"|"xz"|"bz2")
		FULL_ARC=$DEST/zbx_backup_$TIMESTAMP.tar.$COMP_PROG
		;;
	*)
		echo "Argument error: compression extension must be 'gz', 'xz' or 'bz2'."
		exit 1
		;;
esac

# Is lbzip2 installed?
if [[ -f /usr/bin/lbzip2 ]]
then
	USE_LBZIP2=1
else
	USE_LBZIP2=0
fi

# Experimental parsing arguments

# Files
ZBX_SCRIPTS=/usr/lib/zabbix
ZBX_CONFIGS=/etc/zabbix

ZBX_SCRIPTS_TAR=$TMP/zbx_scripts_$TIMESTAMP.tar
ZBX_CONFIGS_TAR=$TMP/zbx_configs_$TIMESTAMP.tar
### END Settings ###

# Creating sql and file archives
function BackingUp() {
	# Making tar archive with scripts and configs
	tar cf $ZBX_SCRIPTS_TAR $ZBX_SCRIPTS
	tar cf $ZBX_CONFIGS_TAR $ZBX_CONFIGS

	# Making MySQL backup with innobackupex
	/usr/bin/innobackupex --user=$DB_USER --password=$DB_PASS --no-timestamp $DB_BACKUP_DST
	/usr/bin/innobackupex --apply-log --redo-only --no-timestamp $DB_BACKUP_DST
}

function TmpClean() {
	if [[ -d $TMP  ]]
	then
		rm -rf $TMP/zbx_*
	else
		echo -e "WARNING: Cannot clean TMP directory ($TMP).\n" >> $LOGFILE
	fi
}

function RotateOldCopies() {
	old_copies=(`ls -1t $DEST/zbx_backup_*`)
	count=${#old_copies[@]}
	echo -e "INFO: Rotation will delete $(($count-$ROTATION))\n files."
	
	if [[ $count -gt $ROTATION ]]
	then
		for old_copy in ${old_copies[@]:$ROTATION}
		do
			if [[ -f $old_copy ]]
			then
				echo -e "INFO: Deleting `echo $old_copy | grep -Po 'zbx_backup_.+'`" >> $LOGILE
				rm -f $old_copy
			else
				echo -e "Something was wrong while deleting $old_file\n" >> $LOGFILE
			fi
		done
	else
		echo "Less or equal $ROTATION copies: $count. Do nothing..."
	fi
}

# Cleaning and backing up
TmpClean && BackingUp

# Arciving results in XZ if files exist
if [[ -f $ZBX_SCRIPTS_TAR ]] && [[ -f $ZBX_CONFIGS_TAR ]] && [[ -d $DB_BACKUP_DST ]]
then
	if [[ $USE_LBZIP2 == 1 ]]
	then
		tar cf $FULL_ARC -I lbzip2 $ZBX_SCRIPTS_TAR $ZBX_CONFIGS_TAR $DB_BACKUP_DST
	else
		tar -zacf $FULL_ARC $ZBX_SCRIPTS_TAR $ZBX_CONFIGS_TAR $DB_BACKUP_DST
	fi
else
	echo -e "ERROR: BackingUP function hasn't finished correctly!\n" >> $LOGFILE
fi

# Cheking and logging results
if [[ -f $FULL_ARC ]]
then
	echo -e "SUCCESS: Backup date: $TIMESTAMP\n" >> $LOGFILE
else
	echo -e "ERROR: Backup wasn't created on $TIMESTAMP\n" >> $LOGFILE
fi

# Cleaning temp files
TmpClean && RotateOldCopies

exit 0
