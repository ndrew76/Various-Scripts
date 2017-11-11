'*******************************************************
'* File:  mappa_unità.vbs (Primordiale VBScript)       *
'* Autore: Fernando Luccarini 2002                     *
'* Commenti:   Mappa \\server\documenti sull' unità X: *
'*******************************************************

Set WshNetwork=WScript.CreateObject("WScript.Network")
On Error Resume Next
WshNetwork.MapNetworkDrive "F:", "\\ys-w2k-server\nw_o"
WshNetwork.MapNetworkDrive "G:", "\\ys-w2k-server\nw_r"
ErrCheck Err.Number
