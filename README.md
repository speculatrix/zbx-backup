# zbx_backup
Making simple backup of Zabbix instance.

## Using
You must necessarily specify some variables on the top of the script:

<b>DEST: the place where we should store final archive.</b>

Example:

DEST=/mnt/nfs/zabbix

<b>TMP: the script creates some temporary files and one of them is SQL backup folder. So, you must specify catalog of relevant size.</b>
Example:

TMP=/var/tmp/zbx_backup

<b>ROTATION. How many old copies you want to hold.</b>

Example:

ROTATION=6
