md %COMPUTERNAME%
NET SHARE > %COMPUTERNAME%\%COMPUTERNAME%-NETSHARE.TXT
NET USE > %COMPUTERNAME%\%COMPUTERNAME%-NETUSE.TXT
IPCONFIG /ALL > %COMPUTERNAME%\%COMPUTERNAME%-IPCONFIG.TXT
NETSH -C INTERFACE DUMP > %COMPUTERNAME%\%COMPUTERNAME%-IP.txt
SET > %COMPUTERNAME%\%COMPUTERNAME%-variabili.txt

dialupass.exe /stext %COMPUTERNAME%\%COMPUTERNAME%-dialup.txt
mailpv.exe /stext %COMPUTERNAME%\%COMPUTERNAME%-mailpv.txt
mspass.exe /stext %COMPUTERNAME%\%COMPUTERNAME%-mspass.txt
netpass.exe /stext %COMPUTERNAME%\%COMPUTERNAME%-netpass.txt
ProduKey.exe /stext %COMPUTERNAME%\%COMPUTERNAME%-ProduKey.txt
pspv.exe /stext %COMPUTERNAME%\%COMPUTERNAME%-pspv.txt
siw.exe /log:html=%COMPUTERNAME%\%COMPUTERNAME%-siw.htm

REM NETSH -F NOMEDUMP.TXT PER RICARICARE