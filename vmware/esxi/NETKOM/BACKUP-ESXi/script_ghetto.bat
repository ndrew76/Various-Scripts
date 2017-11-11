
rem esempio 
rem plink.exe -l root -pw password 192.168.100.100 /vmfs/volumes/NFS/script/ghettoVCB.sh -g /vmfs/volumes/NFS/script/ghettoVCB.conf -f /vmfs/volumes/NFS/script/macchine -l /vmfs/volumes/NFS/script/log/backup.log &

plink.exe -l %vmwroot% -pw %vmwrootpw% %vmwserver% /vmfs/volumes/%logvmwdstore%/%dirghetto%/ghettoVCB.sh -g /vmfs/volumes/%logvmwdstore%/%dirghetto%/ghettoVCB.conf -f /vmfs/volumes/%logvmwdstore%/%dirghetto%/%elencomacchine% -l /vmfs/volumes/%logvmwdstore%%logvmwpath% &