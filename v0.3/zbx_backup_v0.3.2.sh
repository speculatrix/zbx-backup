#!/bin/bash

### Setttings ###

# Directories and files
dest=/mnt/nfs/vlxc02/vmon01
tmp=/tmp
fullBackup=$dest/zbx_backup_$(date +%d.%m.%Y).tar.xz
logFile=$dest/backuplog.log

# Database backup settings
user="zabbix"
pass="zabbix"
DB="zabbix"
sqlDump=$tmp/zbx_sqldump_$(date +%d.%m.%Y).sql
sqlDumpHash=$tmp/zbx_sqldump_$(date +%d.%m.%Y).md5

# Web-interface backup settings
webSource=/usr/share/zabbix
webArchive=$tmp/zbx_webArchive_$(date +%d.%m.%Y).tar
webArchiveHash=$tmp/zbx_webArchive_$(date +%d.%m.%Y).md5

### END Settings ###

# Creating sql and file archives
function BackingUp() {
	mysqldump -u$user -p$pass --databases $DB > $sqlDump
		md5sum $sqlDump > $sqlDumpHash
	tar cPf $webArchive $webSource
		md5sum $webArchive > $webArchiveHash
}

function TmpClean() {
	rm $tmp/zbx_*
}

# Backing up
BackingUp

# Arciving results in XZ if files exist
if [[ -f $sqlDump ]] && [[ -f $webArchive ]]
	then
		tar cPf $fullBackup -I pxz $sqlDump $webArchive $sqlDumpHash $webArchiveHash
	else
		echo -e "ERROR: BackingUP function hasn't finished correctly!\n" >> $logFile
fi

# Cheking and logging results
if [[ -f $fullBackup ]]
	then
		echo -e "SUCCESS: Backup date: $(date)\n" >> $logFile
	else
		echo -e "ERROR: Backup wasn't created on $(date +%d.%m.%Y)\n" >> $logFile
fi

# Cleaning temp files
TmpClean

exit 0
