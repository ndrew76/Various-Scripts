DESCRIPTION :

 This software will automatically backup your ESXi configurations


WHAT IT DOES :
	
 -> Creates a backup archive containing ESXi configuration files + a file listing exact build numbers of the ESXi
 -> Automatically deletes expired backup


PRE-REQUISITES

	Install vSphere CLI (tested with 4.1) and login/logout (or you may experience libxml.dll errors)

HOW TO USE :

 -> Open settings.ini
 -> Enter IP/hostnames of your ESX/ESXi + username + password (will not work if a vCenter is provided instead !)
 -> if some ESXi need alternative login/password then create two entries ( %server-username= and %server-password=)
 -> Fill in backup_folder and retention (examples : 8-days / 1-year / 4-weeks)
 -> Create a scheduled task in Windows to run "ESXi COnfiguration Backup.exe" or run it manually

 
ABOUT
	
	Developped by Thibaut Lauzière : esxi-conf-backup@slymsoft.com
	Licensed under GPL v3 (Open-Source)
	Coded using the excellent AutoIT Framework (http://www.autoitscript.com/)

CHANGELOG

	1.0
		+ First public version

KNOWN BUGS		

	If you installed ESXi on a SD card or on a small disk you may encounter a "404 Not Found" error while trying to download the ESXi configuration.
	A quick fix is explained here : http://www.binbert.com/blog/2011/08/backup-and-restore-esxi-configuration-using-vmware-vsphere-cli/ or http://kb.vmware.com/kb/1037190

DISCLAIMER

 This SOFTWARE PRODUCT is provided by THE PROVIDER "as is" and "with all faults." 
 THE PROVIDER makes no representations or warranties of any kind concerning the safety, suitability, lack of viruses, inaccuracies, typographical errors, or other harmful components of this SOFTWARE PRODUCT. 
 There are inherent dangers in the use of any software, and you are solely responsible for determining whether this SOFTWARE PRODUCT is compatible with your equipment and other software installed on your equipment. 
 You are also solely responsible for the protection of your equipment and backup of your data, and THE PROVIDER will not be liable for any damages you may suffer in connection with using, modifying, or distributing this SOFTWARE PRODUCT.
