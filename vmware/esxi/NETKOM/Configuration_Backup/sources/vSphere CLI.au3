#cs ----------------------------------------------------------------------------

	vSphere Library version : 1.2
	Author :	Thibaut Lauzière
	License :	GPL v3

	Script Function:
		Contains wrapper functions for vSphere CLI

	Changelog
		1.2
			+ Added StorageLoadClaimRules and StorageRunClaimRules
			+ Changed defaultpspChange to StorageModifyDefaultPSP
		1.1
			+ Added Configuration backup functions
			+ Added GetESXFullVersion

		1.0
			+ First public version


#ce ----------------------------------------------------------------------------

#include <File.au3>
#include "Array.au3"

; Connection settings to define in script or here
Global $CONNECTION_SETTINGS="--server TO_BE_DEFINED --username TO_BE_DEFINED --password TO_BE_DEFINED"

; Path to VMware CLI (blank if already in PATH)
Global $VMWARE_CLI_PATH=""

; If set, will log every command runned into this file.
Global $LOGFILE

; Will be set automatically when GetVersion() will be called, default is 4 (vSphere 4)
Global $MAJOR_VERSION = 4

; ========= Global functions =========

Func CheckCLI($forced_path)
	$PATH = RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment", "PATH")

		$windows_letter=StringLeft(@WindowsDir,1)
		If FileExists(@ProgramFilesDir&"\VMware\VMware vSphere CLI\bin\vicfg-vswitch.pl") Then
			$VMWARE_CLI_PATH=@ProgramFilesDir&"\VMware\VMware vSphere CLI\bin\"
		ElseIf FileExists("C:\Program Files (x86)\VMware\VMware vSphere CLI\bin\vicfg-vswitch.pl") Then
			$VMWARE_CLI_PATH="C:\Program Files (x86)\VMware\VMware vSphere CLI\bin\"
		ElseIf FileExists("C:\Program Files\VMware\VMware vSphere CLI\bin\vicfg-vswitch.pl") Then
			$VMWARE_CLI_PATH="C:\Program Files\VMware\VMware vSphere CLI\bin\"
		Elseif FileExists($windows_letter&":\Program Files (x86)\VMware\VMware vSphere CLI\bin\vicfg-vswitch.pl") Then
			$VMWARE_CLI_PATH=$windows_letter&":\Program Files (x86)\VMware\VMware vSphere CLI\bin\"
		Elseif FileExists($windows_letter&":\Program Files\VMware\VMware vSphere CLI\bin\vicfg-vswitch.pl") Then
			$VMWARE_CLI_PATH=$windows_letter&":\Program Files\VMware\VMware vSphere CLI\bin\"
		Elseif FileExists($forced_path&"\vicfg-vswitch.pl") Then
			$VMWARE_CLI_PATH=$forced_path
		Else
			Return -1
		EndIf
		#cs
		If AddToPath($VMWARE_CLI_PATH)<> -1 Then
			$VMWARE_CLI_PATH = ""
			Return "vSphere CLI has been added to PATH"
		Else
			Return -1
		EndIf
		#ce

EndFunc


Func AddToPath($bin_path)
	$key = "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
	$val = "PATH"

	$PATH = RegRead($key, $val)
	if StringRight($PATH,1)= ";" Then
		$PATH = $PATH & $bin_path
	Else
		$PATH = $PATH & ";" & $bin_path
	EndIf


	RegWrite($key,$val,"REG_EXPAND_SZ",$PATH)
	EnvUpdate()

	$PATH = RegRead($key, $val)
	If Not @error AND StringInStr($PATH,$bin_path) Then
		Return 1
	Else
		Return -1
	EndIf
EndFunc

; ========= ESX/vCenter functions =========

; Example : 4 or 5
Func GetVersion()
	$output = _RunReadStd("cmd /c tools\get-version.pl "&$CONNECTION_SETTINGS,0,@ScriptDir)
	$temp = StringLeft($output[1],1)
	if StringIsInt($temp) Then
		$MAJOR_VERSION=Int($temp)
		Return $output[1]
	Else
		Return "undefined"
	EndIf
EndFunc

Func GetESXFullVersion()
	$output = _RunReadStd("cmd /c tools\get-esx-fullversion.pl "&$CONNECTION_SETTINGS,0,@ScriptDir)
	if $output[0]==0 Then
		Return $output[1]
	Else
		Return "ERROR"
	EndIf
EndFunc

; ========= vSwitch functions =========

Func GetvswitchList()
	$output = _RunReadStd("cmd /c tools\list-vswitch.pl "&$CONNECTION_SETTINGS&" --list",0,@ScriptDir)
	$vswitch_list=StringSplit($output[1],"|",3)
	_ArrayPop($vswitch_list)
	return $vswitch_list
EndFunc

Func vswitchList()
	Return vswitch_cmd('--list')
EndFunc

Func vswitchCreate($vswitch_name)
	Return vswitch_cmd('--add "'&$vswitch_name&'"')
EndFunc

Func vswitchAddPortGroup($vswitch_name,$portgroup_name)
	Return vswitch_cmd('--add-pg "'& $portgroup_name&'" "'&$vswitch_name&'"')
EndFunc

Func vSwitchAddUplink($vswitch_name,$vmnic_name)
	Return vswitch_cmd('--link '&$vmnic_name&' "'&$vswitch_name&'"')
EndFunc

; ========= vmkernel functions =========


Func GetvmkernelList()
	$output = _RunReadStd("cmd /c tools\list-vmkernel.pl "&$CONNECTION_SETTINGS&" --list",0,@ScriptDir)
	$vmkernel_list=StringSplit($output[1],"|",3)
	_ArrayPop($vmkernel_list)
	return $vmkernel_list
EndFunc

Func vmkernelAddIP($vmkernel_name,$ip,$netmask,$jumbo_frame="no",$jumbo_frame_size=9000)
	if $jumbo_frame="yes" Then
		$jumbo_append=" --mtu "&$jumbo_frame_size&" "
	Else
		$jumbo_append=""
	EndIf
	Return vmknic_cmd('--add --ip '&$ip&' --netmask '&$netmask&$jumbo_append&' "'& $vmkernel_name&'"')
EndFunc

Func vmkernelAddUplink($vswitch_name,$vmkernel_label,$vmnic_name)
	Return portgroupAddUplink($vswitch_name,$vmkernel_label,$vmnic_name)
EndFunc

Func vmkernelDelUplink($vswitch_name,$vmkernel_label,$vmnic_name)
	Return portgroupDelUplink($vswitch_name,$vmkernel_label,$vmnic_name)
EndFunc


; ========= Port Groups functions =========

Func portgroupAddUplink($vswitch_name,$portgroup_name,$vmnic_name)
	Return vswitch_cmd('--add-pg-uplink '&$vmnic_name&' --pg "'& $portgroup_name&'" "'&$vswitch_name&'"')
EndFunc

Func portgroupDelUplink($vswitch_name,$portgroup_name,$vmnic_name)
	Return vswitch_cmd('--del-pg-uplink '&$vmnic_name&' --pg "'& $portgroup_name&'" "'&$vswitch_name&'"')
EndFunc

; ========= Software iSCSI functions =========

Func Getiscsivmhba()
	$output = _RunReadStd("cmd /c tools\list-swiscsi.pl "&$CONNECTION_SETTINGS&" --adapter --list",0,@ScriptDir)
	return StringStripWS($output[1],3)
EndFunc

Func iscsiEnable()
	Return iscsi_cmd('--swiscsi --enable')
EndFunc

Func iscsiDisable()
	Return iscsi_cmd('--swiscsi --disable')
EndFunc

Func iscsiIsEnabled()
	$output = ExecuteCLI(iscsi_cmd('--swiscsi --list'))
	if StringInStr($output[1],"not enabled") Then
		return 0
	Else
		Return 1
	EndIf
EndFunc

Func iscsiAddNic($vmhba_name,$vmkernel_name)
	if $MAJOR_VERSION <=4 Then
		return esxcli_cmd('swiscsi nic add --nic='&$vmkernel_name&' --adapter='&$vmhba_name)
	Else
		return esxcli_cmd('iscsi networkportal add --nic='&$vmkernel_name&' --adapter='&$vmhba_name)
	EndIf
EndFunc


; ========= VMnics functions =========

; Returns a list of vmnic array of array ( Name / State / Speed / Duplex / Description)
Func GetvmnicsList()
	$output = _RunReadStd("cmd /c tools\list-vmnics.pl "&$CONNECTION_SETTINGS&" --list",0,@ScriptDir)
	$vmnics_list=StringSplit($output[1],"|",3)
	if UBound($vmnics_list) > 0 Then
		_ArrayPop($vmnics_list) ; Clean the last element because it's empty
		Dim $vmnic_detailed[Ubound($vmnics_list)]
		$i=0
		for $vmnic IN $vmnics_list
			$vmnic_detailed[$i]=StringSplit($vmnic,"##",3)
			$i+=1
		Next
		Return $vmnic_detailed
	EndIf
EndFunc


; ========= Path Selection Plugin functions =========
Func StorageModifyDefaultPSP($satp_name,$psp_name)
	if $MAJOR_VERSION <=4 Then
		Return esxcli_cmd("nmp satp setdefaultpsp --satp "&$satp_name&" --psp "&$psp_name)
	Else
		Return esxcli_cmd("storage nmp satp set --satp "&$satp_name&" --default-psp "&$psp_name)
	EndIf
EndFunc

Func StorageLoadClaimRules()
	if $MAJOR_VERSION <=4 Then
		Return esxcli_cmd("corestorage claimrule load")
	Else
		Return esxcli_cmd("storage core claimrule load")
	EndIf
EndFunc

Func StorageRunClaimRules()
	if $MAJOR_VERSION <=4 Then
		Return esxcli_cmd("corestorage claimrule run")
	Else
		Return esxcli_cmd("storage core claimrule run")
	EndIf
EndFunc

; ========= Configuration backup functions =========
Func BackupConfiguration($backup_filename)
	Return cfgbackup_cmd('--save "'&$backup_filename&'"')
EndFunc

Func RestoreConfiguration($backup_filename)
	Return cfgbackup_cmd('--quiet --load "'&$backup_filename&'"')
EndFunc


; ========= Real commands functions =========

; Functions to create Commands
Func vswitch_cmd($param)
	Return "vicfg-vswitch.pl "&$CONNECTION_SETTINGS&" "&$param
EndFunc

Func vmknic_cmd($param)
	Return "vicfg-vmknic.pl "&$CONNECTION_SETTINGS&" "&$param
EndFunc

Func iscsi_cmd($param)
	Return "vicfg-iscsi.pl "&$CONNECTION_SETTINGS&" "&$param
EndFunc

Func cfgbackup_cmd($param)
	Return "vicfg-cfgbackup.pl "&$CONNECTION_SETTINGS&" "&$param
EndFunc

Func esxcli_cmd($param)
	Return "esxcli.exe "&$CONNECTION_SETTINGS&" "&$param
EndFunc

; ========= Miscellaneous functions =========

; [0] = exit code [1] = stdout [2] = stderr
Func ExecuteCLI($cmd)
	Return _RunReadStd("cmd /c "&$cmd,0)
EndFunc


;===============================================================================
;
; Function Name:   _RunReadStd()
;
; Description::    Run a specified command, and return the Exitcode, StdOut text and
;                  StdErr text from from it. StdOut and StdErr are @tab delimited,
;                  with blank lines removed.
;
; Parameter(s):    $doscmd: the actual command to run, same as used with Run command
;                  $timeoutSeconds: maximum execution time in seconds, optional, default: 0 (wait forever),
;                  $workingdir: directory in which to execute $doscmd, optional, default: @ScriptDir
;                  $flag: show/hide flag, optional, default: @SW_HIDE
;                  $sDelim: stdOut and stdErr output deliminter, optional, default: @TAB
;                  $nRetVal: return single item from function instead of array, optional, default: -1 (return array)
;
;
; Return Value(s): An array with three values, Exit Code, StdOut and StdErr
;
; Author(s):       lod3n
;                  (Thanks to mrRevoked for delimiter choice and non array return selection)
;                  (Thanks to mHZ for _ProcessOpenHandle() and _ProcessGetExitCode())
;                  (MetaThanks to DaveF for posting these DllCalls in Support Forum)
;                  (MetaThanks to JPM for including CloseHandle as needed)
;
;===============================================================================

func _RunReadStd($doscmd,$timeoutSeconds=0,$workingdir=$VMWARE_CLI_PATH,$flag=@SW_HIDE,$nRetVal = -1, $sDelim = @CRLF)
    local $aReturn,$i_Pid,$h_Process,$i_ExitCode,$sStdOut,$sStdErr,$runTimer
    dim $aReturn[3]

	; vSphere CLI.au3 modification
	if $LOGFILE <> "" Then _FileWriteLog($LOGFILE,"Executing command "&$doscmd)

    ; run process with StdErr and StdOut flags
    $runTimer = TimerInit()
    $i_Pid = Run($doscmd, $workingdir, $flag, 6) ; 6 = $STDERR_CHILD+$STDOUT_CHILD

    ; Get process handle
    sleep(100) ; or DllCall may fail - experimental
    $h_Process = DllCall('kernel32.dll','ptr', 'OpenProcess','int', 0x400,'int', 0,'int', $i_Pid)

    ; create tab delimited string containing StdOut text from process
    $aReturn[1] = ""
    $sStdOut = ""
    While 1
        $sStdOut &= StdoutRead($i_Pid)
        If @error Then ExitLoop
    Wend
    $sStdOut = StringReplace($sStdOut,@cr,@tab)
    $sStdOut = StringReplace($sStdOut,@lf,@tab)
    $aStdOut = StringSplit($sStdOut,@tab,1)
    for $i = 1 to $aStdOut[0]
        $aStdOut[$i] = StringStripWS($aStdOut[$i],3)
        if StringLen($aStdOut[$i]) > 0 then
            $aReturn[1] &= $aStdOut[$i] & $sDelim
        EndIf
    Next
    $aReturn[1] = StringTrimRight($aReturn[1],1)

    ; create tab delimited string containing StdErr text from process
    $aReturn[2] = ""
    $sStderr = ""
    While 1
        $sStderr &= StderrRead($i_Pid)
        If @error Then ExitLoop
    Wend
    $sStderr = StringReplace($sStderr,@cr,@tab)
    $sStderr = StringReplace($sStderr,@lf,@tab)
    $aStderr = StringSplit($sStderr,@tab,1)
    for $i = 1 to $aStderr[0]
        $aStderr[$i] = StringStripWS($aStderr[$i],3)
        if StringLen($aStderr[$i]) > 0 then
            $aReturn[2] &= $aStderr[$i] & $sDelim
        EndIf
    Next
    $aReturn[2] = StringTrimRight($aReturn[2],1)

    ; kill the process if it exceeds $timeoutSeconds
    if $timeoutSeconds > 0 Then
        if TimerDiff($runTimer)/1000 > $timeoutSeconds Then
            ProcessClose($i_Pid)
        EndIf
    EndIf

    ; fetch exit code and close process handle
    If IsArray($h_Process) Then
        Sleep(100) ; or DllCall may fail - experimental
        $i_ExitCode = DllCall('kernel32.dll','ptr', 'GetExitCodeProcess','ptr', $h_Process[0],'int*', 0)
        if IsArray($i_ExitCode) Then
            $aReturn[0] = $i_ExitCode[2]
        Else
            $aReturn[0] = -1
        EndIf
        Sleep(100) ; or DllCall may fail - experimental
        DllCall('kernel32.dll','ptr', 'CloseHandle','ptr', $h_Process[0])
    Else
        $aReturn[0] = -2
    EndIf

    ; return single item if correctly specified with with $nRetVal
    If $nRetVal <> -1 And $nRetVal >= 0 And $nRetVal <= 2 Then Return $aReturn[$nRetVal]

	; vSphere CLI.au3 modification
	if $LOGFILE <> "" Then _FileWriteLog($LOGFILE, " ==> Result (exit code " & $aReturn[0] & "): " & $aReturn[1] & $aReturn[2])

    ; return array with exit code, stdout, and stderr
    return $aReturn
EndFunc