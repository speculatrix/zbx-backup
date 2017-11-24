# zbx_backup
Zabbix Share page: https://share.zabbix.com/databases/mysql/zabbix-backup-script  
Also you can contact me with vk.com: https://vk.com/asand3r  
This script makes simple backup of Zabbix instance. It can save to archive some directories and database (MySQL only).  
Current stable verson:  
<b>0.5.3</b>  

## TODO List
- [x] Add autocompletion script for bash-completion  
- [ ] Add PostgreSQL support  

## Using of v0.5
v0.5 has many improvements and got something like user-friendly interface.  
Now, you can use arguments in command-line, decide which program to use for backing up database and compress result files.  
Also I've added much more checks, error processing, so I hope it can helps to prevent some user's errors.  
So, main fiature - command line arguments. Now you needn't to set all variables in executable file (except ZBX_CATALOGS), you can just use arguments. Next you can see full list of them:  
1. Now we have __'--help'__ option, which can show you simple help message with examples  

2. Also, I've added __'--version'__ and __'--debug'__ options. The first one just prints script version, and the second one prints the list with result of all settings you have set at startup and exit.  
![alt_text](https://pp.userapi.com/c834104/v834104412/2479e/oVe0ybMtguw.jpg)  
3. We can use different utils for comression. I've hardcoded the most popular in my opinion - __gzip, bzip2 (lbzip2, pbzip2) and xz__. Each may be set in __'--compress-with'__ option. If you will not set it, as result you will get just 'tar' file.  
4. Option __'--db-only'__ can be used to save database only, without directories hardcoded in "ZBX_CATALOGS" variable.  
5. Added __'--rotation'__ option. It can be used to redefine default old copies count. It has default value: 10. Also, you can set it to __'no'__ to disable rotation.  
6. Next three options set your connection to MySQL database, it's __'--db-name'__, __'--db-user'__ and __'--db-password'__. I don't think that they need to be explained, but '--db-name' has default value: __'zabbix'__.
7. Options __'--use-mysqldump'__ and __'--use-xtrabackup'__ give you choise which utility to use for database backup. The first one works longer and locks table, so your Zabbix instance can be slower for some time (I'm using '--single-transaction' option, so it's almost not such important), but second one works quicker and if you have one database per server, I'd recomend to use it. Using of xtrabackup will save all of your MySQL server instance, but mysqldump will save Zabbix server database only. One more thing that you should know - backup file created with mysqldump smaller than with xtrabackup (maybe for 3 to 4 times).  
8. In v0.5.2 added option __'--save-to'__ which set location where will be saved final archive file. It has default value: your current folder.  
9. Also in v0.5.2 added option __'--temp-folder'__, which set folder for temporary files. It's nessecery and must be ready to accept all MySQL data for all saving procedure time. It has default value: /tmp.

Each argument has short version of itself, you can find notice it in '--help'. So, most short usage example can looks like that:  
```bash
root@server:~# zbx_backup -x -u root -p P@ssw0rd
```
It will use 'xtrabackup' utility and connect to MySQL database with root:P@ssw0rd credentials.  
As result of script working you will got compressed file contains zabbix database and config files. The file will named with template __'zbx_backup_dd.mm.yyyy.hhmmss'__ with extension of utility you set (tar.bz2, for example).

## Autocompletion
There is the folder 'bash_completion.d' contains 'zbx_backup.bash' file. You can place it to folder /etc/bash_completion.d (if you have 'bash-completion' packet installed) and source it:  
```bash
root@server:~# . /etc/bash_completion.d/zbx_backup.bash
```
After this you can find simple autocompletion with TAB (you must place executable file somewhere where $PATH will find it and should name it as 'zbx_backup'; for example, I've placed it to /usr/local/bin)  
![alt text](https://pp.userapi.com/c841536/v841536677/37165/HhL-1GMUAxg.jpg)
