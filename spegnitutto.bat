for /f %%i in (listaip.txt) do start psshutdown -u xp2\andrea -p password -m "Spegnimento automatico in corso premere CANCEL per annullare" -s -f -c \\%%i 