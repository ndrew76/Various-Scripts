rem rsm.exe refresh /LF"HP Ultrium 1-SCSI SCSI Sequential Device"
rem sleep 90
for /f "Tokens=1-4 Delims=/ " %%i in ('date /t') do set dt=%%i-%%j-%%k-%%l
for /f "Tokens=1" %%i in ('time /t') do set tm=-%%i
set tm=%tm::=-%
set dtt=%dt%%tm%
Echo.|Command /C Date|Find "corrente">NOMEGIORNO
set /p today=<NOMEGIORNO
set NOMEGIORNO=%today:~19,3%
c:\windows\system32\ntbackup.exe backup "@C:\Bat\Exchange.bks" /n "Exchange-%dt%" /d "Exchange-%dt%" /v:no /r:no /rs:no /hc:on /m normal /j "Backup" /l:S /f "\\192.168.200.200\Backup\EXCHANGE\Exchange-%NOMEGIORNO%.bkf" /SNAP:off
del NOMEGIORNO
Sleep 10
rem C:\windows\system32\ntbackup.exe backup "@C:\Bat\Backup.bks" /n "%computername%-%dtt%" /d "daily %dtt%" /v:yes /r:no /rs:no /hc:on /m normal /j "Backup" /l:S /p "LTO Ultrium" /SNAP:off /UM
Rem rsm.exe eject /PF"%computername%-%dtt% - 1" /astart
exit

rem le righe commentate servivano per il salvataggio su nastro dei dati