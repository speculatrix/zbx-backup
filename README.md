# zbx_backup
Zabbix Share page: https://share.zabbix.com/databases/mysql/zabbix-backup-script  
Also you can contact me with vk.com or Telegram: https://vk.com/asand3r  @asand3r
This script makes simple backup of Zabbix instance. It can save to archive some directories and database (MySQL only).  
Current stable verson:  
<b>0.6</b>  

## Main features
- Dumps the database with two ways;
- Can exclude some tables in the database;
- Saves pointed catalogs of filesystem;
- Writes errors to logfile;
- Configurable old copies rotation;
- Final result compression with couple of utilities  

## TODO List
- [x] Add autocompletion script for bash-completion  
- [x] Separate tables backup (config or data tables)
- [ ] Add PostgreSQL support  

## Usage of current stable
For more details look at project wiki page.  
Since v0.5 has been released it has many improvements and got something like user-friendly interface, so now I'm keeping follow this way.    
Full arguments list:  
1. __'--help'__ option, which can show you simple help message with examples  
![alt text](https://pp.userapi.com/c824603/v824603198/3fdca/u-cd9-f58xo.jpg)  
2. Added __'--version'__ and __'--debug'__ options. The first one just prints script version, and the second one prints the list with result of all settings you have set at startup and exit.  
![alt_text](https://pp.userapi.com/c834104/v834104412/2479e/oVe0ybMtguw.jpg)  
3. We can use different utils for comression. I've hardcoded the most popular in my opinion - __gzip, bzip2 (lbzip2, pbzip2) and xz__. Each may be set in __'--compress-with'__ option. If you will not set it, get just 'tar' file as result.  
4. Option __'--db-only'__ can be used to save database only, without directories hardcoded in "ZBX_CATALOGS" variable.  
5. Added __'--rotation'__ option. It can be used to redefine default old copies count. It has default value: 10. Also, you can set it to __'no'__ to disable rotation.  
6. Next three options set your connection to MySQL database, it's __'--db-name'__, __'--db-user'__ and __'--db-password'__. I don't think that they need to be explained. One thing - '--db-name' has default value: __'zabbix'__, so may be skipped.
7. __DEPECATED! You should use --backup-with option__ Options __'--use-mysqldump'__ and __'--use-xtrabackup'__ give you choise which utility to use for database backup. Using of xtrabackup will save all of your MySQL server instance, but mysqldump will save Zabbix server database only. One more thing that you should know - backup file created with mysqldump smaller than with xtrabackup (maybe for 3 to 4 times).  
8. Since v0.6 I've replace '-x' and '-m' options with one '-b|--backup-with' which sets backup utility - mysqldump or xtrabackup. Old option saved to compability, but you shouldn't you it anymore.
8. Option __'--save-to'__ sets location where will be saved final archive file. It has default value: current folder.  
9. Option __'--temp-folder'__ sets folder for temporary files. It's nessecery and must be ready to accept all MySQL data for all saving procedure time. It has default value: /tmp.
10. Option '--exclude-tables' can be use to exclude some tables from database backup. It has two present: 'data' and 'config'. The first excludes all zabbix large tables, contains data like 'history' and 'trends' (15 total in Zabbix 3.4), and the second saves all other tabases. Tables list forming dynamically with next regular expression:  
```bash
"^(history|acknowledges|alerts|auditlog|events|trends)"
```
Except two presets you can set tables list manually, just enter their names to one string in double quotes after '--exclude-tables' option.  

Each argument has short version of itself, you can find notice it in '--help'. So, most short usage example can looks like that:  
```bash
root@server:~# zbx_backup -b mysqldump -u root -p P@ssw0rd
```
It will use 'mysqldump' utility and connect to MySQL database with root/P@ssw0rd credentials. As result you will get tar archive contains zabbix database and config files. The file will named with template __'zbx_backup_dd.mm.yyyy.hhmmss.tar'__.

## Autocompletion
There is the folder 'bash_completion.d' contains 'zbx_backup.bash' file. You can place it to folder /etc/bash_completion.d (if you have 'bash-completion' packet installed) and source it:  
```bash
root@server:~# . /etc/bash_completion.d/zbx_backup.bash
```
After this you can find simple autocompletion with TAB (you must place executable file somewhere where $PATH will find it and should name it as 'zbx_backup'; for example, I've placed it to /usr/local/bin)  
![alt text](https://pp.userapi.com/c841536/v841536677/37165/HhL-1GMUAxg.jpg)
