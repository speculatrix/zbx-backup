# zbx_backup
Making simple backup of Zabbix instance. It can save to archive some directories and database (MySQL only).  
Current stable verson:  
<b>0.4.3</b>  
<b>0.5.1</b>  

## Using of v0.4
You must necessarily specify some variables on the top of the script:  
<b>DEST:</b> the place where we should store final archive.  
<b>TMP:</b> the script creates some temporary files and one of them is SQL backup folder. So, you must specify catalog of relevant size.  
<b>ROTATION:</b> How many old copies you want to hold.

Example:  
DEST=/mnt/nfs/zabbix  
TMP=/var/tmp/zbx_backup  
ROTATION=10  

For database backup v0.4 expects what you have innobackupex utility installed. Also, you must specify user for MySQL instance and his passoword. Password can be set plaintext or placed to some file, which content you can get with 'cat' utility.
Example:  
DB_USER="root"  
DB_PASS=`cat /root/.mysql`  

## Using of v0.5
v0.5 has many improvements and got something like user-friendly interface.  
Now, you can use arguments in command-line, decide which program to use for backing up database and compress result files.  
Also I've added much more checks, error processing, so I hope it can helps to prevent some user's errors.  
So, main fiature - command line arguments. Now you needn't to set all variables in executable file (except ZBX_CATALOGS), you can just use arguments. Next you can see full list of them:  
1. Now we have '--help' option, which can show you simple help message with examples  
![alt text](https://pp.userapi.com/c639426/v639426269/57d44/f4GP3k8HbKs.jpg)  
2. Also, I've added '--version' and '--debug' keys. The first one just prints script version, and the second one prints the table with result of all settings you have set at startup and exit.  
![alt_text](https://pp.userapi.com/c639426/v639426141/675f0/0JHhrLK4oQA.jpg)  
3. We can use different utils for comression. I've hardcoded the most popular in my opinion - gzip, bzip2, lbzip2, pbzip2 and xz. Each may be set in '--compress-with' option. If you will not set it, as result you will get just 'tar' file.  
4. '--db-only' key can be used to save database only without directories hardcoded in "ZBX_CATALOGS" variable.  
5. Added '--rotation' option. It can be used to redefine default old copies count (10).  
6. Next three options set your connection to MySQL database, it's '--db-name', '--db-user' and '--db-password'. I don't think that they need to be explained. One moment - '--db-name' redefines hardcoded database name - 'zabbix', so you can miss it, if your database have such name.  
7. Arguments '--use-mysqldump' and '--use-innobackupex' give you choise which utility to use for database backup.  
All of arguments has short version what you can find in '--help'.

As result of script working you will got compressed file contains zabbix database and config files. The file will named with template 'zbx_backup_dd.mm.yyyy.hhmmss' with extension of utility you set (tar.bz2, for example).
