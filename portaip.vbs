strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set objNewPort = objWMIService.Get _
    ("Win32_TCPIPPrinterPort").SpawnInstance_

objNewPort.Name = "IP_192.168.0.198"
objNewPort.Protocol = 1
objNewPort.HostAddress = "192.168.0.198"
objNewPort.PortNumber = "9100"
objNewPort.SNMPEnabled = True
objNewPort.Put_
