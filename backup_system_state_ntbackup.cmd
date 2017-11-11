for /f "Tokens=1-4 Delims=/ " %%i in ('date /t') do set dt=%%i-%%j-%%k-%%l
for /f "Tokens=1" %%i in ('time /t') do set tm=-%%i
set tm=%tm::=-%
set dtt=%dt%%tm%
Echo.|Command /C Date|Find "corrente">NOMEGIORNO
set /p today=<NOMEGIORNO
set NOMEGIORNO=%today:~19,3%
c:\windows\system32\ntbackup.exe backup "@C:\Bat\SystemState.bks" /n "SystemState-%dt%" /d "SystemState-%dt%" /v:no /r:no /rs:no /hc:on /m normal /j "Backup" /l:S /f "d:\systemstate\Systemstate-%NOMEGIORNO%.bkf" /SNAP:off
del NOMEGIORNO
Sleep 10
exit