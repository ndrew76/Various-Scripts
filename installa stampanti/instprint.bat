regedit /s porta.reg
net stop spooler
net start spooler
rundll32 printui.dll,PrintUIEntry /if /r "\\ys-w2k-server\hp_lj4345mfp" /f "c:\pcl6\hpc4345c.inf" /m "HP LaserJet 4345 mfp PCL 6"