@echo off
cls

:: Start config params
:: ------------------------------------------------------
:: Edit these parameters to match your environment. 0=OFF/NO 1=ON/YES

:: Use WGET, Yes or No?  

set usewget=1

:: WGET Server parameters, if the above is 0 then we skip these.

:: IP or hostnames are ok.

:: set vmwserver=192.168.100.100

:: root or user with access to browse datastores over HTTPS

:: set vmwroot=root
:: set vmwrootpw=password

:: Datastore containing the path/file below.

:: set logvmwdstore=NFS

::    This is the path and filename of the logfile defined in your ghettoVCB.sh command line.
::    NOTE: That the filename must not be automatically rotated by gVCB.  It should be the same
::    name in every backup.
::
::   File and Pathnames are CASE SENSITIVE!!

:: set logvmwpath=/script/log/backup.log

:: ---- End WGET Params

::  This is the path to the BLAT.EXE mailer and WGET.EXE

set progpath=%pathlocale%

:: IF USING WGET, then you only need to modify the logpath where you want the logs pulled and rotated.
::
:: IF NOT USING WGET:
::
::    These are the path and filename of the logfile defined in your ghettoVCB.sh command line.
::    NOTE: That the filename must not be automatically rotated by gVCB.  It should be the same
::    name in every backup. 
::
::    If not using WGET, and pulling a file off of a NAS share, etc, you can put a network location for logpath.
::
:: set logpath=c:\netkom\logs
:: set logfile=backup.log

:: Temp path, you can leave this unchanged usually.
set temppath=%temp%


:: Used in subject line of email sent.  Cosmetic
:: set esxiserver=BACKUP ESXI DI CASA

:: Define your email environment ... 

:: set emailfrom=esxi@nodominio.local
:: set emailto=ndrew76@gmail.com
:: set emailsmtp=out.alice.it
:: set emailport=25

 :: If you require SMTP auth, edit these lines.  
 
:: set emailauth=0
:: set emailauthu=username
:: set emailauthp=password

:: ------------------------------------------------------
:: End config params

:: ************************STARTUP**************************************

:START

echo log2mail by Andrea Orlandi 
echo -------------------------------------------------------------------------------
echo Starting up .. ver 0.1
echo Performing environment check..
if %usewget%==0 goto NEXTCHK
if %vmwserver%. == . goto PARAERR
if %vmwroot%. == . goto PARAERR
if %vmwrootpw%. == . goto PARAERR
if %logvmwdstore%. == . goto PARAERR
if %logvmwpath%. == . goto PARAERR

:NEXTCHK
if %emailfrom%. == . goto PARAERR
if %emailto%. == . goto PARAERR
if %emailsmtp%. == . goto PARAERR
if %emailport%. == . goto PARAERR
if %emailauth%. == . goto PARAERR

echo All the parameters checked out..
if %temppath%. == . echo .. Um, actually you didn't specify a "temppath" variable, so we'll use %TEMP% 

if %temppath%. == . set temppath=%temp%

echo -------------------------------------------------------------------------------
echo  Params are:
echo  Email From:          %emailfrom%
echo  Email To:            %emailto%
echo  Email SMTP Server:   %emailsmtp%
echo  Email Auth Required? %emailauth%
if %emailauth% == "1" echo  Email Auth Username: %emailauthu%
if %emailauth% == "1" echo  Email Auth Password: %emailauthp%

echo.
if not exist "%progpath%\blat.exe" goto NOBERR
echo Found BLAT at %progpath%\blat.exe..
if not exist "%progpath%\wget.exe" goto NOBERR
echo Found WGET at %progpath%\wget.exe..

if %usewget%==1 goto GETLOG
if %usewget%==0 goto LOGSTART
goto LOGSTART

:GETLOG
echo off
echo Running WGET.EXE to retrieve %logvmwpath% from %logvmwdstore% on %vmwserver%
"%progpath%\wget.exe" --no-check-certificate --user %vmwroot% --password %vmwrootpw% "https://%vmwserver%/folder%logvmwpath%?dcPath=ha-datacenter&dsName=%logvmwdstore%" --output-document %logpath%\%logfile% 

:LOGSTART
if not exist "%logpath%\%logfile%" goto NOFERR

:: Check to see if an error condition exists in the logfile.
echo -------------------------------------------------------------------------------
echo Checking to see if there are errors in the logfile..
find /I "Final status: ERROR" "%logpath%\%logfile%" > nul
if errorlevel 1 goto GOOD0
goto BAD1

:GOOD0

:: This was probably a good backup, but the file may be empty... Let's double check.

find /I "Final status: All" "%logpath%\%logfile%" > nul
if errorlevel 1 goto BAD0

:GOOD1

echo This was a good backup, let's send the email.. 
echo -------------------------------------------------------------------------------
echo Shelling out to BLAT

if %emailauth% == 1    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -u %emailauthu% -pw %emailauthp% -subject "Success: VMware Backup Completed for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%logpath%\%logfile%"
if %emailauth% == 0    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -subject "Success: VMware Backup Completed for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%logpath%\%logfile%"
goto ROTATE

:BAD0
echo This backup was neither good nor bad?, let's send the email..
echo Could be an indication of a blank logfile or ghettoVCB version issue.
echo The backup log did not indicate a good or bad backup. This could be an indication that your log was empty or does not exist. > "%temppath%\embody.txt"
echo.  >> "%temppath%\embody.txt"
type "%logpath%\%logfile%" >> "%temppath%\embody.txt"
echo -------------------------------------------------------------------------------
echo Shelling out to BLAT

if %emailauth% == 1    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -u %emailauthu% -pw %emailauthp% -priority 1 -subject "ERROR: Problem(s) Detected in Backup for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%temppath%\embody.txt"
if %emailauth% == 0    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -priority 1 -subject "ERROR: Problem(s) Detected in Backup for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%temppath%\embody.txt"

if exist "%temppath%\embody.txt" del "%temppath%\embody.txt"

goto ROTATE


:BAD1

echo This backup had errors, let's send the email..
echo -------------------------------------------------------------------------------
echo Shelling out to BLAT

if %emailauth% == 1    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -u %emailauthu% -pw %emailauthp% -priority 1 -subject "ERROR: Problem(s) Detected in Backup for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%logpath%\%logfile%"
if %emailauth% == 0    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -priority 1 -subject "ERROR: Problem(s) Detected in Backup for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%logpath%\%logfile%"

goto ROTATE


:ROTATE
echo -------------------------------------------------------------------------------
echo Rotating the backup logs...

if exist "%logpath%\Backup6.log" del "%logpath%\Backup6.log"
if exist "%logpath%\Backup5.log" ren "%logpath%\Backup5.log" "Backup6.log"
if exist "%logpath%\Backup4.log" ren "%logpath%\Backup4.log" "Backup5.log"
if exist "%logpath%\Backup3.log" ren "%logpath%\Backup3.log" "Backup4.log"
if exist "%logpath%\Backup2.log" ren "%logpath%\Backup2.log" "Backup3.log"
if exist "%logpath%\Backup1.log" ren "%logpath%\Backup1.log" "Backup2.log"
if exist "%logpath%\%logfile%"  ren "%logpath%\%logfile%" "Backup1.log"
echo Done..
goto END

:EMBAD


:: ************************ERROR HANDLING**************************************

:PARAERR
echo -------------------------------------------------------------------------------
echo ERROR: Parameters missing or incorrect.  Check the configuration.
goto END

:NOBERR
echo -------------------------------------------------------------------------------
echo ERROR: Could not find either WGET.EXE or the BLAT.EXE mailer at %progpath%.. 
echo ERROR: Without these we cannot continue.
goto END


:NOFERR
echo -------------------------------------------------------------------------------
echo ERROR: No file found at %logpath%\%logfile%. 
echo ERROR: This is normal if the backup did not run. 
echo ERROR: Alerting via email that we couldn't find a logfile.
echo Could not locate a logfile at %logpath%\%logfile%.  This could be an indication that your VMware ESXi backup did not run as expected! > "%temppath%\embody.txt"
echo -------------------------------------------------------------------------------
echo Shelling out to BLAT

if %emailauth% == 1    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -u %emailauthu% -pw %emailauthp% -priority 1 -subject "ERROR: Missing Backup Log/Job Incomplete for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%temppath%\embody.txt"
if %emailauth% == 0    "%progpath%\blat.exe" -f %emailfrom% -t %emailto% -server %emailsmtp% -port %emailport% -priority 1 -subject "ERROR: Missing Backup Log/Job Incomplete for %esxiserver% on %DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%" -BodyF "%temppath%\embody.txt"

if exist "%temppath%\embody.txt" del "%temppath%\embody.txt"

goto END

:: ************************END**************************************


:END

:: set usewget=
:: set vmwserver=
:: set vmwroot=
:: set vmwrootpw=
:: set logvmwdstore=
:: set logvmwpath=
:: set progpath=
:: set logpath=
:: set logfile=
:: set temppath=
:: set emailfrom=
:: set emailto=
:: set emailsmtp=
:: set emailport=
:: set emailauth=
:: set emailauthu=
:: set emailauthp=
:: set esxiserver=
