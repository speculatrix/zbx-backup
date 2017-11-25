#!/usr/bin/env bash

#
# This script can help you to create backup of simple Zabbix instance.
# It makes tar archives of config and scripts directories. Also it makes MySQL backup with
# Percona Xtrabackup utility (xtrabackup) whitch you should install yourself.
# After all it makes compressed archive contains all collected data using gzip, bzip2 or xz.
# After a few tests I reccomend to use lbzip2. It makes archive faster, but almost
# two times bigger than xz. Gzip it fine too, but as bzip2, rather slow (in my case).
#

VERSION="0.6.0 (dev)"

# Current timestamp
TIMESTAMP=$(date +%d.%m.%Y.%H%M%S)
# These catalogs will save too
ZBX_CATALOGS=("/usr/lib/zabbix" "/etc/zabbix")
### END Static settings ###

# The function just print help message
function PrintHelpMessage() {
echo "
zbx_backup, version: $VERSION
(c) Khatsayuk Alexander, 2017
Usage:
-s|--save-to		- choose location to save result archive file (default: current directory)
-t|--temp-folder	- temp folder where will be place database dump (default: /tmp)
-c|--compress-with	- gzip|bzip2|lbzip2|pbzip2|xz
-r|--rotation		- set copies count what we will save (default: 10, set 'no' if rotation needn't)
-x|--use-xtrabackup	- will use 'xtrabackup' utility to backup database
-m|--use-mysqldump	- will use 'mysqldump' utility to backup database
-d|--db-only		- backing up database only without Zabbix config files etc
-u|--db-user		- username for connection to zabbix database (must be 'root' for xtrabackup)
-p|--db-password	- password for database user; also can be path to file with password or '-' for prompt
-n|--db-name		- database name (default: 'zabbix')
-e|--exclude-tables	- list of database tables to exclude from backup (has one preset: 'data')
-h|--help		- print this help message
-v|--version		- print version number
--debug			- print result ingormation and exit

Examples:
# Making backup of Zabbix database and config files with xtrabackup. compress it with lbzip2.
zbx_backup --compress-with lbzip2 --use-xtrabackup --db-user root --db-password P@ssw0rd
# Making backup of Zabbix database and config files with xtrabackup. compress it with lbzip2.
zbx_backup --compress-with gzip --use-mysqldump --db-user zabbix --db-password /root/.mysql --db-name zabbix_database
# Making backup of Zabbix database only and compress it with xz utility.
zbx_backup --compress-with xz --db-only -u root -p P@ssw0rd

More on GitHub (https://github.com/asand3r/zbx_backup)
"
exit 0
}

# Parsing given arguments
if [[ $# -eq 0 ]]
then
	PrintHelpMessage
fi

# Ooh, it makes me mad. I've almost get it, but my pythoted brain refuses constructions like this. %)
while [[ $# -gt 0 ]]
do
	ARG="$1"
	case "$ARG" in
		"-c"|"--compress-with")
			USE_COMPRESSION="YES"
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
		"-t"|"--temp-folder")
			TMP=$2
			if [[ $TMP =~ /$ ]]; then TMP=${TMP%?}; fi
			shift
			shift
			;;	
		"-x"|"--use-xtrabackup")
			USE_XTRABACKUP="YES"
			shift
			;;
		"-s"|"--save-to")
			DEST=$2
			LOGFILE="$DEST/zbx_backup.log"
			if [[ $DEST =~ /$ ]]; then DEST=${DEST%?}; LOGFILE="$DEST/zbx_backup.log"; fi
			shift
			shift
			;;
		"-m"|"--use-mysqldump")
			USE_MYSQLDUMP="YES"
			shift
			;;
		"-d"|"--db-only")
			DB_ONLY="YES"
			shift
			;;
		"-u"|"--db-user")
			DB_USER=$2
			shift
			shift
			;;
		"-p"|"--db-password")
			DB_PASS=$2
			if [[ -f "$DB_PASS" ]]
			then
				DB_PASS=$(cat "$DB_PASS")
				if [[ $? -eq 1 ]]
				then
					echo "ERROR: Cannot read password from file '$DB_PASS'. Check it permissions."
					exit 1
				fi
			fi
			shift
			shift
			;;
		"-n"|"--db-name")
			DB_NAME=$2
			shift
			shift
			;;
		"-e"|"--exclude-tables")
			EXCLUDE_TABLES=$2
			shift
			shift
			;;
		"-r"|"--rotation")
			ROTATION=$2
			shift
			shift
			;;
		"-h"|"--help")
			PrintHelpMessage
			;;
		"-v"|"--version")
			echo "$VERSION"
			exit 0
			;;
		"--debug")
			DEBUG="YES"
			shift
			;;
		*)
			echo "Syntax error! Please, use '--help' to view usage examples."
			exit 1
			;;
	esac
done

# Set defaults if arguments not present
if ! [[ $TMP ]]; then TMP="/tmp"; fi					# -t|--temp-dir
if ! [[ $DB_NAME ]]; then DB_NAME="zabbix"; fi				# -n|--db-name
if ! [[ $DEST ]]; then DEST=$(pwd); LOGFILE="$DEST/zbx_backup.log"; fi	# -s|--save-to
if ! [[ $ROTATION ]]; then ROTATION=10; fi				# -r|--rotation
if [[ $USE_COMPRESSION ]] && ! [[ $(command -v "$COMPRESS_WITH") ]]; then echo "ERROR: Utility '$COMPRESS_WITH' not found."; exit 1; fi

# List of Zabbix tables contains data - like history, trends etc.
ZBX_DATA_TABLES=("history" "history_uint" "trends" "trends_uint")

#
# A lot of checks, sorry, trying to make this script more friendly
#

# Checking TEMP directory existing
if ! [[ -d "$TMP" ]]
then
	mkdir -p $TMP
	if [[ $? -ne 0 ]]; then echo "ERROR: Cannot create temp directory ($TMP)."; exit 1; fi
fi

# Enter the password if it equal to '-'
if  [[ $DB_PASS == "-" ]]
then
	read -s -p "Please, enter the password for user '$DB_USER' ('$DB_NAME' database): " DB_PASS
	echo -e "\n"
fi

# We cannot use both '-m' and '-i' options, so breaks here
if [[ "$USE_XTRABACKUP" ]] && [[ "$USE_MYSQLDUMP" ]]
then
	echo "ERROR: You cannot use '-m' and '-i' options together!"
	exit 1
# Also we should use at least one of them
elif ! [[ "$USE_XTRABACKUP" ]] && ! [[ "$USE_MYSQLDUMP" ]] && ! [[ "$DB_ONLY" ]]
then
	echo "ERROR: You must specify at least one database backup utility. Use '--help' to learn how."
	exit 1
fi

# Check if username and password provided by user
if [[ ${#DB_USER} == 0 ]]
then
	echo "ERROR: You must provide not Null username for database '$DB_NAME'. Use '--help' to learn how."
	exit 1
fi

#
# End of checks
#

# The function cleans $TMP directory
function TmpClean() {
	if [[ -d "$TMP"  ]]
	then
		rm -rf $TMP/zbx_*
	else
		echo "WARNING: $TIMESTAMP : Cannot clean TMP directory ($TMP)." >> "$LOGFILE"
	fi
}

# The function makes all backup operations
function BackingUp() {
	# Cleaning TMP before starting
	TmpClean

	# If '--db-only' option not set
	if ! [[ "$DB_ONLY" ]]
	then
		ZBX_FILES_TAR=$TMP/zbx_files_$TIMESTAMP.tar
		# Making initial files tar archive
		if [[ -d ${ZBX_CATALOGS[0]} ]]
		then
			tar cf "$ZBX_FILES_TAR" ${ZBX_CATALOGS[0]} 2>/dev/null
			if [[ $? -eq 2 ]]; then echo "ERROR: You have no permission to save '${ZBX_CATALOGS[0]}'"; exit 1; fi
		else
			echo "WARNING: $TIMESTAMP : Cannot find catalog ${ZBX_CATALOGS[0]} to save it." >> "$LOGFILE"
		fi
		# Add all other catalogs in $ZBX_CATALOGS array to initial tar archive
		if [[ -f $ZBX_FILES_TAR ]]
		then
			for (( i=1; i < ${#ZBX_CATALOGS[@]}; i++ ))
			do
				if [[ -d ${ZBX_CATALOGS[$i]} ]]
				then
					tar -rf "$ZBX_FILES_TAR" ${ZBX_CATALOGS[$i]} 2>/dev/null
					if [[ $? -eq 2 ]]; then echo "ERROR: Catalog '${ZBX_CATALOGS[$i]}' cannot be append to the archive."; exit 1; fi
				else
					echo "WARNING: $TIMESTAMP : Cannot find catalog ${ZBX_CATALOGS[0]} to save it." >> "$LOGFILE"
				fi
			done
		else
			echo "ERROR: Cannot create TAR archive ($ZBX_FILES_TAR) with data files."
			TmpClean
			exit 1
		fi
	fi

	# Backing up database
	# If we want to use mysqldump to backup database
	if [[ "$USE_MYSQLDUMP" ]]
	then
		# If excluding detected, forming --ignore-table arguments
		if [[ "$EXCLUDE_TABLES" ]]
		then
			IGNORE_ARG=""
			case "$EXCLUDE_TABLES" in
				"data")
					for TABLE in ${ZBX_DATA_TABLES[@]}
					do
						IGNORE_ARG+="--ignore-table=\"$TABLE\" "
					done
				;;
				*)
					for TABLE in ${EXCLUDE_TABLES[@]}
					do
						IGNORE_ARG+="--ignore-table=\"$TABLE\""
					done
				;;
			esac
		fi

		DB_BACKUP_DST=$TMP/zbx_db_dump_$TIMESTAMP.sql
		MYSQLDUMP_PATH=$(command -v mysqldump)
		
		# Forming basic arguments
		MYSQLDUMP_ARGS="--user=\"$DB_USER\" --password=\"$DB_PASS\" --databases \"$DB_NAME\" --single-transaction "
		# Add --ignore-table if needs
		if [[ $EXCLUDE_TABLES ]]
		then
			MYSQLDUMP_ARGS+=$IGNORE_ARG
		fi
		# Running mysqldump
		if [[ "$MYSQLDUMP_PATH" ]]
		then
			$MYSQLDUMP_PATH "$MYSQLDUMP_ARGS" > "$DB_BACKUP_DST"
		else
			echo "ERROR: 'mysqldump' utility not found."
			TmpClean
			exit 1
		fi
	# If we want to use xtrabackup to backup database
	elif [[ "$USE_XTRABACKUP" ]]
	then
		DB_BACKUP_DST=$TMP/zbx_mysql_files_$TIMESTAMP
		XTRABACKUP_PATH=$(command -v xtrabackup)
		if [[ $? -eq 0 ]]
		then
			$XTRABACKUP_PATH --backup --user="$DB_USER" --password="$DB_PASS" --no-timestamp --parallel=4 --target-dir="$DB_BACKUP_DST" 2>/dev/null 2>"$LOGFILE"
			$XTRABACKUP_PATH --prepare --user="$DB_USER" --password="$DB_PASS" --no-timestamp --apply-log --target-dir="$DB_BACKUP_DST" 1>/dev/null 2>"$LOGFILE"
		else
			echo "ERROR: Cannot find 'xtrabackup' utility ($XTRABACKUP_PATH)."
			exit 1
		fi
	fi

	# Chech last exit code
	if [[ $? -ne 0 ]]
	then
		echo "ERROR: $TIMESTAMP : Cannot create database backup" >> "$LOGFILE"
		TmpClean
		return 1
	fi
}


# The function making rotation of old backup files
function RotateOldCopies() {
	# Getting old copies list and it's count
	OLD_COPIES=($(ls -1t "$DEST"/zbx_backup_*))
	COUNT=${#OLD_COPIES[@]}

	if [[ $COUNT -gt $ROTATION ]] && [[ $ROTATION -ne 0 ]]
	then
		for OLD_COPY in "${OLD_COPIES[@]:$ROTATION}"
		do
			if [[ -f "$OLD_COPY" ]]
			then
				rm -f "$OLD_COPY"
			else
				echo "WARNING: $TIMESTAMP : Something was wrong while deleting $OLD_COPY" >> "$LOGFILE"
			fi
		done
	else
		echo "INFO: $TIMESTAMP : We have less or equal $ROTATION old copies: $COUNT. Do nothing..." >> "$LOGFILE"
	fi
}

if [[ "$DEBUG" == "YES" ]]
then
	function join { local IFS="$1"; shift; echo "$*"; }

	printf "%-20s : %-25s\n" "Database name" "$DB_NAME"
	printf "%-20s : %-25s\n" "Database user" "$DB_USER"
	printf "%-20s : %-25s\n" "Database password" "$DB_PASS"
	printf "%-20s : %-25s\n" "Use compression" "$USE_COMPRESSION"
	printf "%-20s : %-25s\n" "Compression utility" "$COMPRESS_WITH"
	printf "%-20s : %-25s\n" "Old copies count" "$ROTATION"
	printf "%-20s : %-25s\n" "Logfile location" "$LOGFILE"
	printf "%-20s : %-25s\n" "Temp directory" "$TMP"
	printf "%-20s : %-25s\n" "Final distination" "$DEST"
	printf "%-20s : %-30s\n" "Zabbix catalogs" "$(join ', ' "${ZBX_CATALOGS[@]}")"
	if [[ "$USE_MYSQLDUMP" ]]; then printf "%-20s : %-25s\n" "Use mysqldump" $USE_MYSQLDUMP; fi
	if [[ "$USE_XTRABACKUP" ]]; then printf "%-20s : %-25s\n" "Use xtrabackup" $USE_XTRABACKUP; fi
	exit 0
fi

# Running backup function
BackingUp

# Compressing if resulted files exists
if [[ "$USE_COMPRESSION" ]]
then
	case $COMPRESS_WITH in
		"gzip")
			EXT="gz"
			;;
		"bzip2"|"lbzip2"|"pbzip2")
			EXT="bz2"
			;;
		"xz")
			EXT="xz"
			;;
	esac
	
	FULL_ARC="$DEST/zbx_backup_$TIMESTAMP.tar.$EXT"
	if [[ "$DB_ONLY" ]]
	then
		tar cf "$FULL_ARC" -I "$COMPRESS_WITH" "$DB_BACKUP_DST" 2>/dev/null
	elif [[ -f "$ZBX_FILES_TAR" ]]
	then
		tar cf "$FULL_ARC" -I "$COMPRESS_WITH" "$ZBX_FILES_TAR" "$DB_BACKUP_DST" 2>/dev/null
	fi
else
	FULL_ARC="$DEST/zbx_backup_$TIMESTAMP.tar"
	if [[ "$DB_ONLY" ]]
	then
		tar cf "$FULL_ARC" "$DB_BACKUP_DST" 2>/dev/null
	elif [[ -f "$ZBX_FILES_TAR" ]]
	then
		tar cf "$FULL_ARC" "$ZBX_FILES_TAR" "$DB_BACKUP_DST" 2>/dev/null
	fi
fi

# Cleaning temp 
TmpClean

# Running rotation
if ! [[ "$ROTATION" =~ ^[Nn][Oo]$ ]]
then
	RotateOldCopies
fi

# Cheking and logging results
if [[ -f "$FULL_ARC" ]]
then
	FULL_SIZE=$(du -sh "$FULL_ARC" | cut -f1)
	echo "INFO: $TIMESTAMP : Backup job success. Result file sise is $FULL_SIZE." >> "$LOGFILE"
	exit 0
else
	echo "ERROR: $TIMESTAMP : Backup job failed, archive wasn't created." >> "$LOGFILE"
	exit 1
fi

exit $?
