set dir1=acq
set dir2=amministrazione
set dir3=cataloghi
set dir4=commerciale
set dir5=drivers
set dir6=foto
set dir7=libretti
set dir8=novatec
set dir9=produzione
set dir10=scanner
set dir11=segreteria
set dir12=ufftecnico
set dir13=vendite

set disk1=D:\
set disk2=E:\
set disk3=


robocopy \\server2003\d$\%dir1% D:\%dir1% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir1%.txt
robocopy \\server2003\d$\%dir2% D:\%dir2% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir2%.txt
robocopy \\server2003\d$\%dir4% D:\%dir4% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir4%.txt
robocopy \\server2003\d$\%dir5% D:\%dir5% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir5%.txt
robocopy \\server2003\d$\%dir7% D:\%dir7% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir7%.txt
robocopy \\server2003\d$\%dir8% D:\%dir8% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir8%.txt
robocopy \\server2003\d$\%dir9% D:\%dir9% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir9%.txt
robocopy \\server2003\d$\%dir10% D:\%dir10% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir10%.txt
robocopy \\server2003\d$\%dir11% D:\%dir11% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir11%.txt
robocopy \\server2003\d$\%dir13% D:\%dir13% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir13%.txt


robocopy \\server2003\e$\%dir3% D:\%dir3% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir3%.txt
robocopy \\server2003\e$\%dir6% D:\%dir6% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir6%.txt
robocopy \\server2003\e$\%dir12% D:\%dir12% /E /COPYALL /MIR /R:1 /W:2 /X /ETA /LOG:C:\batch\log\%dir12%.txt