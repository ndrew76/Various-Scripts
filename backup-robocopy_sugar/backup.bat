set pathcrm=C:\SUGARCRM
set pathlog=c:\log-backup\
set nomelog=sugarbk.log
set msgbackup=messaggiobackup.txt

net stop sugarMysql
"%pathcrm%\apache2\bin\apache.exe" -n "sugarApache" -k stop
robocopy %pathcrm% c:\backup /e /log:%pathlog%%nomelog%
blat %msgbackup% -t avvisi@yupp-serv.org -subject BACKUP-SUGARCRM -attacht %pathlog%%nomelog%

%pathcrm%\bin\servicerun.bat START