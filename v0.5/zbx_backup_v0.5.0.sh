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
ZBX_FILES_TAR=$TMP/zbx_files_$TIMESTAMP.tar
MYSQLDUMP=/usr/bin/mysqldump
INNOBACKUPEX=/usr/bin/innobackupex

# Database backup settings
DB_USER="root"
DB_PASS=`cat /root/.mysql`
DB_NAME="zabbix"

# Backing up directories
ZBX_CATALOGS=("/usr/lib/zabbix" "/etc/zabbix")
### END Static settings ###

# Checking TEMP directory
if ! [[ -d $TMP ]]
then
	mkdir -p $TMP
fi

function PrintHelpMessage() {
echo "
zbx_backup, version: $VERSION
(c) Alexander Khatsayuk, 2017
Usage:
-c|--compress-with	- gzip|bzip2|xz|lbzip2|pbzip2
-i|--use-innobackupex	- will use 'innobackupex' utility to backup database
-m|--use-mysqldump	- will use 'mysqldump' utility to backup database
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

# Ooh, it makes me mad. I've almost get it, but my pythoted brain refuses constructions like this. %)
while [[ $# -gt 0 ]]
do
	ARG="$1"
	case "$ARG" in
		"-c"|"--compress-with")
			C_USED="YES"
			case "$2" in
				"gzip"|"bzip2"|"xz"|"lbzip2"|"pbzip2")
					COMPRESS_WITH=$2
					;;
				*)
					echo "Syntax error: [-c|--compress-with] gzip|bzip2|xz|lbzip2|pbzip2"
					exit 1
					;;
			esac
			shift
			shift
			;;
		"-i"|"--use-innobackupex")
			I_USED="YES"
			USE_MYSQLDUMP="NO"
			USE_INNOBACKUPEX="YES"
			shift
			;;
		"-m"|"--use-mysqldump")
			M_USED="YES"
			USE_MYSQLDUMP="YES"
			USE_INNOBACKUPEX="NO"
			shift
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

# We cannot use both '-m' and '-i' options, so breaks here
if [[ $I_USED == "YES" ]] && [[ $M_USED == "YES" ]]
then
	echo "ERROR: You cannot use '-m' and '-i' options together!"
	exit 1
# Also we should use at least one of them
elif [[ $I_USED != "YES" ]] && [[ $M_USED != "YES" ]]
then
	echo "ERROR: You must specify at least one database backup utility. Use '--help' to learn how."
	exit 1
fi

# Creating sql and file archives
function BackingUp() {
	ZBX_FILES_TAR=$TMP/zbx_files_$TIMESTAMP.tar
	# Making initial files tar archive
	tar cf $ZBX_FILES_TAR ${ZBX_CATALOGS[0]}
	
	# Add all other catalogs in $ZBX_CATALOGS array to initial tar archive
	if [[ -f $ZBX_FILES_TAR ]]
	then
		for (( i=1; i < ${#ZBX_CATALOGS[@]}; i++ ))
		do
			tar -rf $ZBX_FILES_TAR ${ZBX_CATALOGS[$i]}
		done
	else
		echo "ERROR: Cannot create TAR archive with zabbix data files."
		exit 1
	fi
	
	# Backing up database
	if [[ $USE_MYSQLDUMP == "YES" ]] && [[ $USE_INNOBACKUPEX == "NO" ]]
	DB_DUMP=$TMP/zbx_db_dump_$TIMESTAMP.bak
	then
		if [[ -f $MYSQLDUMP ]]
		then
			$MYSQLDUMP -u$DB_USER -p$DB_PASS --databases "$DB_NAME" > $DB_DUMP
		else
			echo "ERROR: 'mysqldump' utility wasn't found!"
		fi	
	elif [[ $USE_MYSQLDUMP == "NO" ]] && [[ $USE_INNOBACKUPEX = "YES" ]]
	DB_BACKUP_DST=$TMP/zbx_mysql_files_$TIMESTAMP
	then
		if [[ -f $INNOBACKUPEX ]]
		then
			$INNOBACKUPEX --user=$DB_USER --password=$DB_PASS --no-timestamp $DB_BACKUP_DST
			$INNOBACKUPEX --apply-log --redo-only --no-timestamp $DB_BACKUP_DST
		else
		fi
	fi
}

# Running BackingUp function
BackingUp

# The function cleans $TMP directory
function TmpClean() {
	if [[ -d $TMP  ]]
	then
		rm -rf $TMP/zbx_*
	else
		echo "WARNING: Cannot clean TMP directory ($TMP)." >> $LOGFILE
	fi
}

# The function making rotation of old backup files
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
				echo "WARNING: Something was wrong while deleting $old_file" >> $LOGFILE
			fi
		done
	else
		echo "INFO: Less or equal $ROTATION copies: $count. Do nothing..." >> $LOGFILE
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
	echo "ERROR: Cannot compress all files." >> $LOGFILE
fi

# Cheking and logging results
if [[ -f $FULL_ARC ]]
then
	echo "SUCCESS: Backup date: $TIMESTAMP" >> $LOGFILE
else
	echo "ERROR: Backup wasn't created on $TIMESTAMP" >> $LOGFILE
fi

# Cleaning temp files and run rotation
TmpClean && RotateOldCopies

exit 0
