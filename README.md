# zbx_backup
Making simple backup of Zabbix instance.

## Using
You must necessarily specify some variables on the top of the script:

<b>DEST: the place where we should store final archive.</b>

<b>TMP: the script creates some temporary files and one of them is SQL backup folder. So, you must specify catalog of relevant size.</b>

<b>ROTATION. How many old copies you want to hold.</b>

Example:
DEST=/mnt/nfs/zabbix
TMP=/var/tmp/zbx_backup
ROTATION=10

For database backup v0.4 expects what you have innobackupex utility installed. Also, you must specify user for MySQL instance and his passoword. Password can be set plaintext or placed to some file, which content you can get with 'cat' utility.
Example:
DB_USER="root"
DB_PASS=`cat /root/.mysql`
