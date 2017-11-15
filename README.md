# zbx_backup
Making simple backup of Zabbix instance. It can save to archive some directories and database (MySQL only).  
Current stable verson:  
<b>0.5.2</b>  

## Using of v0.5
v0.5 has many improvements and got something like user-friendly interface.  
Now, you can use arguments in command-line, decide which program to use for backing up database and compress result files.  
Also I've added much more checks, error processing, so I hope it can helps to prevent some user's errors.  
So, main fiature - command line arguments. Now you needn't to set all variables in executable file (except ZBX_CATALOGS), you can just use arguments. Next you can see full list of them:  
1. Now we have '--help' option, which can show you simple help message with examples  
![alt text](https://pp.userapi.com/c841132/v841132025/38baf/kdHb0Pp3R94.jpg)  
2. Also, I've added '--version' and '--debug' keys. The first one just prints script version, and the second one prints the list with result of all settings you have set at startup and exit.  
![alt_text](https://pp.userapi.com/c834104/v834104412/2479e/oVe0ybMtguw.jpg)  
3. We can use different utils for comression. I've hardcoded the most popular in my opinion - gzip, bzip2, lbzip2, pbzip2 and xz. Each may be set in '--compress-with' option. If you will not set it, as result you will get just 'tar' file.  
4. Option '--db-only' can be used to save database only, without directories hardcoded in "ZBX_CATALOGS" variable.  
5. Added '--rotation' option. It can be used to redefine default old copies count. It has default value: 10.  
6. Next three options set your connection to MySQL database, it's '--db-name', '--db-user' and '--db-password'. I don't think that they need to be explained. One moment: '--db-name' redefines hardcoded database name - 'zabbix', so you can miss it, if your database has such name.  
7. Options '--use-mysqldump' and '--use-xtrabackup' give you choise which utility to use for database backup. The first one works longer and locks table, so your Zabbix instance can be slower for some time, but second one works quicker and if you have one database per server, I'd recomend to use it. Using of xtrabackup will save all of your MySQL server instance, but mysqldump will save Zabbix server database only.  
8. In v0.5.2 added option '--save-to' which set location where will be saved final archive file. It has default value: your current folder.  
9. Also in v0.5.2 added option '--temp-folder', which set folder for temporary files. It's nessecery and must be ready to accept all MySQL data for all saving procedure time. It has default value: /tmp.  
Each argument has short version of itself, you can find notice it in '--help'. So, most short usage example can looks like that:  
```bash
# zbx_backup -x -u root -p P@ssw0rd
```
It will use 'xtrabackup' utility and connect to MySQL database with root:P@ssw0rd credentials.  
As result of script working you will got compressed file contains zabbix database and config files. The file will named with template 'zbx_backup_dd.mm.yyyy.hhmmss' with extension of utility you set (tar.bz2, for example).
