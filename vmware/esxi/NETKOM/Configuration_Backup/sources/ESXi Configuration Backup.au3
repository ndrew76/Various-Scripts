#region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=beta
#AutoIt3Wrapper_Icon=ESXi Configuration Backup.ico
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=This software will automatically backup your ESXi configurations
#AutoIt3Wrapper_Res_Description=Backup your ESXi
#AutoIt3Wrapper_Res_Fileversion=1.0.8.8
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=y
#AutoIt3Wrapper_Res_LegalCopyright=GPL v3 - Thibaut Lauziere
#AutoIt3Wrapper_Res_SaveSource=y
#AutoIt3Wrapper_Res_Field=AutoIt Version|%AutoItVer%
#AutoIt3Wrapper_Res_Field=Compile Date|%date% %time%
#AutoIt3Wrapper_Run_Tidy=y
#endregion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------
	
	Author  :	Thibaut Lauzière
	Contact :	esxi-conf-backup@slym.fr
	Licence :	GPL v3
	
	Script Description:
	This software will automatically backup your ESXi configurations
	
#ce ----------------------------------------------------------------------------

#include <Date.au3>
#include "vSphere CLI.au3"

Global $software_version = "1.0"
Global $settings_ini = @ScriptDir & "\settings.ini"

Global $LOGFOLDER = @ScriptDir & "\logs\"
Global $LOGFILE = $LOGFOLDER & @YEAR & "-" & @MON & "-" & @MDAY & ".log"

$check_cli = CheckCLI(ReadSetting("Advanced", "vmware_cli_path"))
If $check_cli = -1 Then
	$return = MsgBox(20, "ERROR", "vSphere CLI not found." & @CRLF & "If you have already installed, please set 'vsphere_cli_path variable' in settings.ini" & @CRLF & @CRLF & "Would you like to download vSphere CLI ? (You may have to login/logout afterwards)")
	If $return = 6 Then
		ShellExecute("http://www.vmware.com/support/developer/vcli/")
	EndIf
	Exit
EndIf

; Connection Settings
$servers = StringSplit(ReadSetting("Connection", "servers"), "#", 3)
$username = ReadSetting("Connection", "username")
$password = ReadSetting("Connection", "password")

$backup_folder = ReadSetting("Config", "backup_folder")
$retention = ReadSetting("Config", "retention")

If StringRight($backup_folder, 1) <> "\" Then $backup_folder &= "\"
If Not FileExists($backup_folder) Then DirCreate($backup_folder)

$temp_backup_folder = @ScriptDir & "\temp\" & @YEAR & "-" & @MON & "-" & @MDAY & "\"
$destination_archive = $backup_folder & @YEAR & "-" & @MON & "-" & @MDAY & ".zip"


AddToLog("Starting ESXi Configuration Backup version " & $software_version _
		 & @CRLF & "+++ ESXi to backup : " & StringReplace(ReadSetting("Connection", "servers"), "#", ",") _
		 & @CRLF & "+++ Backup folder : " & $backup_folder _
		 & @CRLF & "+++ Backups size : " & DirGetSizeHuman($backup_folder) _
		 & @CRLF & "+++ Retention : " & $retention _
		 & @CRLF & "+++ Path to vSphere CLI : " & $VMWARE_CLI_PATH & @CRLF)

; Deleting expired backups and associated logs
DeleteOldBackups($backup_folder, $retention)
DeleteOldLogs($LOGFOLDER, $retention)

; Creating temporary folder
If DirCreate($temp_backup_folder) <> 1 Then
	AddToLog("Failed while trying to create folder : " & $temp_backup_folder)
EndIf

; Backing up each server
For $server In $servers
	ConsoleWrite(@CRLF & "Starting backup process." & @CRLF & "Fetching ESXi version then backing up.")
	$custom_username = ReadSetting("Connection", $server & "-username")
	$custom_password = ReadSetting("Connection", $server & "-password")
	If $custom_username <> "" And $custom_password <> "" Then
		ConsoleWrite(@CRLF & "Login using " & $custom_username & "@" & $server)
		$CONNECTION_SETTINGS = "--server " & $server & " --username " & $custom_username & " --password " & $custom_password
	Else
		ConsoleWrite(@CRLF & "Login using " & $username & "@" & $server)
		$CONNECTION_SETTINGS = "--server " & $server & " --username " & $username & " --password " & $password
	EndIf
	$full_version = GetESXFullVersion()
	If $full_version == "ERROR" Then
		AddToLog("Could not connect to '" & $server)
		FileWrite($temp_backup_folder & "ESXi Versions.txt", "Could not connect to '" & $server & @CRLF)

	Else
		AddToLog("Server '" & $server & "' is running " & $full_version)
		FileWrite($temp_backup_folder & "ESXi Versions.txt", "Server '" & $server & "' is running " & $full_version & @CRLF)
		AddCommand("Backing up ESXi " & $server, BackupConfiguration($temp_backup_folder & $server & ".tar.gz"))
	EndIf
Next

; Compressing configuration backups in destination archive
ZipIt($temp_backup_folder & "*", $destination_archive)

; Deleting temporary folder
DirRemove(@ScriptDir & "\temp", 1)
ConsoleWrite(@CRLF & "Done. This program will exit in 10 seconds")
Sleep(10000)


Func AddCommand($description, $cmd)
	$output = ExecuteCLI($cmd)

	If $output[0] == 0 Then
		If StringStripWS($output[1], 3) <> "" Then
			$status = "Success (" & $output[1] & ")"
		Else
			$status = "Success."
		EndIf
	Else
		$status = "ERROR ! " & $output[1] & $output[2]
	EndIf
	AddToLog($description & " : " & $status)
EndFunc   ;==>AddCommand

Func AddToLog($status, $console = 1)
	If $console == 1 Then ConsoleWrite(@CRLF & $status)
	_FileWriteLog($LOGFILE, $status)
EndFunc   ;==>AddToLog

Func WriteSetting($category, $key, $value)
	IniWrite($settings_ini, $category, $key, $value)
EndFunc   ;==>WriteSetting

Func ReadSetting($category, $key)
	$val = IniRead($settings_ini, $category, $key, "")
	Return StringStripWS($val, 3)
EndFunc   ;==>ReadSetting

Func ZipIt($source, $destination)
	FileDelete($destination)
	$output = _RunReadStd('"' & @ScriptDir & '\tools\7z.exe" a "' & $destination & '" -tZIP "' & $source & '"', 360, @ScriptDir, @SW_HIDE, -1, @CRLF)
	If $output[0] == 0 Then
		$status = "Success"
	Else
		$status = "ERROR ! " & $output[1] & $output[2]
	EndIf
	AddToLog("Creating backup archive : " & $status)
	Return $output[0]
EndFunc   ;==>ZipIt


Func DeleteOldBackups($folder, $retention)
	$retention_date = ConvertRetentionToNumber($retention)
	AddToLog("Retention is set to " & $retention & " so retention date is " & $retention_date)
	AddToLog("Deleting expired backups")
	; Shows the filenames of all files in the current directory
	$search = FileFindFirstFile($folder & "*.*")

	; Check if the search was successful
	If $search = -1 Then
		AddToLog("No backup found in folder " & $folder)
		Return 0
	EndIf
	$backups = 0
	$expired = 0
	$expired_deleted = 0
	While 1
		$file = FileFindNextFile($search)
		If @error Then ExitLoop
		If GetExtension($file) == "zip" Then
			$backups += 1
			$t = FileGetTime($folder & $file, 0)
			$diff = _DateDiff('D', $retention_date, $t[0] & "/" & $t[1] & "/" & $t[2])
			If $diff < 0 Then
				$expired += 1
				If FileDelete($folder & $file) <> 1 Then
					AddToLog(@CRLF & "Backup " & $file & " COULD NOT BE DELETED (" & $diff & " day older than retention)", 0)
				Else
					$expired_deleted += 1
					AddToLog(@CRLF & "Backup " & $file & " has been deleted (" & $diff & " day older than retention)", 0)
				EndIf
			Else
				AddToLog(@CRLF & "Backup " & $file & " is OK (" & $diff & " older than retention)", 0)
			EndIf
		EndIf
	WEnd
	If $backups <> 0 Then ConsoleWrite(@CRLF & "Found " & $backups & " backups, " & $expired & " expired (" & $expired_deleted & " deleted)")
	FileClose($search)
EndFunc   ;==>DeleteOldBackups

Func DeleteOldLogs($folder, $retention)
	$retention_date = ConvertRetentionToNumber($retention)

	; Shows the filenames of all files in the current directory
	$search = FileFindFirstFile($folder & "*.*")

	; Check if the search was successful
	If $search = -1 Then
		Return 0
	EndIf

	While 1
		$file = FileFindNextFile($search)
		If @error Then ExitLoop
		$t = FileGetTime($folder & $file, 1)
		$diff = _DateDiff('D', $retention_date, $t[0] & "/" & $t[1] & "/" & $t[2])
		If $diff < 0 Then FileDelete($folder & $file)
	WEnd
	FileClose($search)
EndFunc   ;==>DeleteOldLogs

Func ConvertRetentionToNumber($retention)
	$retention_split = StringSplit($retention, "-", 3)
	If $retention_split[1] = "year" Or $retention_split[1] = "years" Then
		$retention_date = _DateAdd('Y', -$retention_split[0], _NowCalcDate())
	ElseIf $retention_split[1] = "month" Or $retention_split[1] = "month" Then
		$retention_date = _DateAdd('M', -$retention_split[0], _NowCalcDate())
	ElseIf $retention_split[1] = "weeks" Or $retention_split[1] = "week" Then
		$retention_date = _DateAdd('w', -$retention_split[0], _NowCalcDate())
	Else
		$retention_date = _DateAdd('D', -$retention_split[0], _NowCalcDate())
	EndIf
	Return $retention_date
EndFunc   ;==>ConvertRetentionToNumber

Func DirGetSizeHuman($folder)
	$value = DirGetSize($folder)
	$suffix = "B"
	If $value < 2 ^ 10 Then
		Return $value & " " & $suffix
	ElseIf $value < 2 ^ 20 Then
		Return Round($value / 2 ^ 10, 2) & " k" & $suffix
	ElseIf $value < 2 ^ 30 Then
		Return Round($value / 2 ^ 20, 2) & " M" & $suffix
	ElseIf $value < 2 ^ 40 Then
		Return Round($value / 2 ^ 30, 2) & " G" & $suffix
	Else
		Return Round($value / 2 ^ 40, 2) & " T" & $suffix
	EndIf
EndFunc   ;==>DirGetSizeHuman

Func GetExtension($filepath)
	$short_name = StringSplit($filepath, '.')
	If Not @error And IsArray($short_name) Then
		Return ($short_name[$short_name[0]])
	Else
		Return "ERROR"
	EndIf
EndFunc   ;==>GetExtension

