#!/bin/bash

### Setttings ###
# Directories and files
DEST=/mnt/nfs/shv-mon01
TMP=/var/tmp/zbx_backup
TIMESTAMP=`date +%d.%m.%Y.%H%M%S`
LOGFILE=$DEST/backuplog.log

# Parsing arguments to find compress program
COMP_PROG=$1
case "$COMP_PROG" in
	"gz"|"xz"|"bz2")
		FULL_ARC=$DEST/zbx_backup_$TIMESTAMP.tar.$COMP_PROG
		;;
	*)
		echo "Argument error: compression program must be 'gz', 'xz' or 'bz2'."
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

# Database backup settings
DB_USER="root"
DB_PASS=`cat /root/.mysql`
DB_BACKUP_DST=$TMP/zbx_mysql_files_$TIMESTAMP

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

# Backing up
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
TmpClean

exit 0
