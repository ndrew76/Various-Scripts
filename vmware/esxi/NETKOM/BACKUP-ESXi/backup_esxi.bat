@echo off

set vmwserver=10.18.254.100
rem IP esxi utilizzato anche da log2mail.bat
set vmwroot=root
rem Utente esxi utilizzato anche da log2mail.bat
set vmwrootpw=CCmm10.l
rem Passowrd utente esxi utilizzato anche da log2mail.bat
set logvmwdstore=VM_BACKUP
rem Nome datat store dove c'e' ghettovcb utilizzato anche da log2mail.bat
set	dirghetto=admin/scripts
rem Directory dove e' contenuto ghettovcb
set logvmwpath=/admin/scripts/log/backup.log
rem Nome e path log del backup utilizzato anche da log2mail.bat
set	elencomacchine=macchine
rem Elenco macchine utilizzato da ghettovcb
set logpath=C:\NETKOM\BACKUP-ESXi\logs
rem directory locale dove vengono depositati i log
set logfile=backup.log
rem nome del file di log

rem Used in subject line of email sent.  Cosmetic. Utilizzato da log2mail.bat
set esxiserver=BACKUP ESXi ASAC

rem Define your email environment ... Utilizzato da log2mail.bat

set emailfrom=esxi@asac.mo.it
set emailto=tecnici@netkom.net
set emailsmtp=smtp.acantho.net
set emailport=25

rem If you require SMTP auth, edit these lines. Utilizzato da log2mail.bat

set emailauth=0
set emailauthu=username
set emailauthp=password

set pathlocale=C:\NETKOM\BACKUP-ESXi
rem path dove sono contenuti gli script




call %pathlocale%\script_ghetto.bat
call %pathlocale%\log2mail.bat
call %pathlocale%\cancella_log.bat