Function MApNetfirstDrive (path)
dim i, Connection, obj

On Error Resume Next
Set obj = WScript.CreateObject("Scripting.FileSystemObject")

'Parto da 70.. la lettera D
for i=70 to 90 
	if ((obj.GetDrive(chr(i)+":").ShareName  = "") and (obj.GetDrive(chr(i)+":").DriveLetter= "")) then
		Set Connection = WScript.CreateObject("WScript.Network") 
		Connection.MapNetworkDrive chr(i)+":", path
		MApNetfirstDrive=chr(i)+":"
		set Connection = nothing
		exit for
	end if
Next
End Function