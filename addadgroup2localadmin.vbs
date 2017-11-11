' Aggiungi un gruppo di AD  al gruppo Administrators locali
Dim strUser, StrGroup, StrComputer, objNetwork, StrDomain
Set objNetwork = CreateObject("Wscript.Network")
'Gets local computer name
StrComputer =objNetwork.ComputerName
'Put the name of the user or group here
StrDomainGroup = "Domain Users"
'Put your Netbios domain name here
StrDomain= "yuppies"
'Put the local group name you want to add the user/group to.
StrLocalGroup = "Administrators"
Call AddToLocalGroup(strComputer, strLocalGroup, strDomainGroup, strDomain)
Sub AddToLocalGroup(strComputer, strLocalGroup, strDomainGroup, strDomain)
Dim objLocalGroup, objDomainGroup
Set objLocalGroup = GetObject("WinNT://" & strComputer & "/" & strLocalGroup & ",Group")
Set objDomainGroup = Getobject("WinNT://" & strDomain & "/" & strDomainGroup & ",Group")
If Not objLocalGroup.IsMember(objDomainGroup.AdsPath) Then
objLocalGroup.Add(objDomainGroup.AdsPath)
End If
End Sub