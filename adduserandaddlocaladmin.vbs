'Questo script serve per aggiungere un utente locale (con password settata e senza scadenza) al gruppo Administrators Locale
'computer locale
strComputer = "."

' name of user to be added 
sUser = "nome utente"

Set colAccounts = GetObject("WinNT://" & strComputer)
Set objUser = colAccounts.Create("user",sUser)
' password utente
objUser.SetPassword "password"
' impostazione per: Nessuna Scadenza Password 
objUser.Put "userFlags", &H10000 
objUser.SetInfo

 

' name of the group the user is to be added to 
sGroupname = "Administrators" 

' get computer name 
Set oWshNet = CreateObject("WScript.Network") 
sComputerName = oWshNet.ComputerName 

' connect to the group 
Set oGroup = GetObject("WinNT://" & sComputerName & "/" & sGroupname)
' connect to the user 
Set oUser = GetObject("WinNT://" & sComputerName & "/" & sUser & ",user") 

' Add the user to the group 
' Use error handling in case the account is a member already 
On Error Resume Next 
oGroup.Add(oUser.ADsPath) 
On Error Goto 0