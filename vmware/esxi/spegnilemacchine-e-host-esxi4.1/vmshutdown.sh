#!/bin/sh


# creo una lista degli ID delle vm

vim-cmd vmsvc/getallvms | grep vmx | awk '{print $1}' > /tmp/vm_ids.txt


# ciclo che spegne le VM in base agli id solo se hanno i vm tools

while read line

do

     vim-cmd vmsvc/power.shutdown $line

done < /tmp/vm_ids.txt


rm /tmp/vm_ids.txt

# attesa per essere certi che tutte le macchine si spengano

sleep 60

# spengo l'host

poweroff
