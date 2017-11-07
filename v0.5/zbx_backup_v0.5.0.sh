#!/usr/bin/env bash

#
# This script can help you to create backup of simple Zabbix instance.
# It makes tar archives of config and scripts directories. Also it makes MySQL backup with
# Percona Xtrabackup utility (innobackupex) whitch you should install yourself.
# After all it makes compressed archive contains all collected data using gzip, bzip2 or xz.
# After a few tests I reccomend to use lbzip2. It makes archive faster, but almost
# two times bigger than xz. Gzip it fine too, but as bzip2, rather slow (in my case).
#
VERSION="0.5.0"

### Static setttings ###
# Working directories and files
DEST=/mnt/nfs/shv-mon01			# Where we should  store final archive
TMP=/var/tmp/zbx_backup			# Where to store temp MySQL backup, before it will be compress
ROTATION=10				# How many old archives we should store
LOGFILE=$DEST/backuplog.log		# Logfile location
TIMESTAMP=`date +%d.%m.%Y.%H%M%S`	# Current timestamp

# Database backup settings
DB_USER="root"
DB_PASS=`cat /root/.mysql`
DB_BACKUP_DST=$TMP/zbx_mysql_files_$TIMESTAMP

# Backing up directories
ZBX_SCRIPTS=/usr/lib/zabbix
ZBX_CONFIGS=/etc/zabbix

ZBX_FILES_TAR=$TMP/zbx_scripts_and_configs_$TIMESTAMP.tar

### END Static settings ###

function PrintHelpMessage() {
echo "
Version: $VERSION
Using:
-c|--compress-with	- gzip|bzip2|xz|lbzip2|pbzip2
-i|--use-innobackupex	- will use 'innobackupex' utility to backup database
-m|--use-mysqldump	- will use 'mysqldump' utility to backup database
--default		- set default settings. It's uses mysqldump and gzip utilities.
-h|--help		- print this help message
-v|--version		- print version number

Example:
zbx_backup --compress-with lbzip2 --use-innobackupex
"
exit 0
}

# EXPERIMENTAL Parsing cmd args
if [[ $# -eq 0 ]]
then
	echo "Syntax error! Please, provide some arguments. Use '--help' to view examples."
	exit 1
fi

while [[ $# -gt 0 ]]
do
	ARG="$1"
	case "$ARG" in
		"-c"|"--compress-with")
			echo "Using compression detected"
			case "$2" in
				"gz"|"bzip2"|"xz"|"lbzip2"|"pbzip2")
					COMPRESS_WITH=$2
					;;
				*)
					echo "Syntax error: [-c|--compress-with] gz|bzip2|xz|lbzip2|pbzip2"
					exit 1
					;;
			esac
			echo "Will compress with $COMPRESS_WITH"
			shift
			shift
			;;
		"-i"|"--use-innobackupex")
			echo "Using innobackupex detected"
			USE_INNOBACKUPEX="YES"
			shift
			;;
		"-m"|"--use-mysqldump")
			USE_MYSQLDUMP="YES"
			echo "Using mysqldump detected"
			shift
			;;
		"--default")
			echo "INFO: Using default settings: using 'mysqldump' and compress with 'gzip'"
			COMPRESS_WITH="gzip"
			USE_MYSQLDUMP="YES"
			USE_INNOBACKUPEX="NO"
			;;
		"-h"|"--help")
			PrintHelpMessage
			;;
		"-v"|"--version")
			echo $VERSION
			exit 0
			;;
		*)
			echo "Syntax error! Please, use '--help' to view correct usage examples."
			exit 1
			;;
	esac
done

if [[ $USE_INNOBACKUPEX == "YES" ]] && [[ $USE_MYSQLDUMP == "YES" ]]
then
	echo "ERROR: You cannot use '-m' and '-i' options together!"
	exit 1
fi

# Creating sql and file archives
function BackingUp() {
	# Making tar archive with scripts and configs
	tar cf $ZBX_FILES_TAR $ZBX_SCRIPTS $ZBX_CONFIGS

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

	if [[ $count -gt $ROTATION ]]
	then
		for old_copy in ${old_copies[@]:$ROTATION}
		do
			if [[ -f $old_copy ]]
			then
				rm -f $old_copy
			else
				echo -e "Something was wrong while deleting $old_file\n" >> $LOGFILE
			fi
		done
	else
		echo -e "Less or equal $ROTATION copies: $count. Do nothing...\n" >> $LOGFILE
	fi
}

# Cleaning TMP and backing up
TmpClean && BackingUp

# Compressing if files exist
if [[ -f $ZBX_FILES_TAR ]] && [[ -d $DB_BACKUP_DST ]]
then
	if [[ $USE_LBZIP2 == 1 ]]
	then
		tar cf $FULL_ARC -I lbzip2 $ZBX_FILES_TAR $DB_BACKUP_DST
	else
		tar -zacf $FULL_ARC $ZBX_FILES_TAR $DB_BACKUP_DST
	fi
else
	echo -e "ERROR: Cannot compress all files.\n" >> $LOGFILE
fi

# Cheking and logging results
if [[ -f $FULL_ARC ]]
then
	echo -e "SUCCESS: Backup date: $TIMESTAMP\n" >> $LOGFILE
else
	echo -e "ERROR: Backup wasn't created on $TIMESTAMP\n" >> $LOGFILE
fi

# Cleaning temp files and run rotation
TmpClean && RotateOldCopies

exit 0
