//running chipscope
//module add xilinx/14.4i
//analyzer
//JTAG Chain->Digilent USB JTAG Cable

//ladda in config filen  i chipscope
//play knappen f�r att b�rja analysera 
//testade commadot m 9fff0000 1234abcd i gtkterm 

//terminalen
//gtkterm -s 115200 -p /dev/ttyACM0

//l f�r ladda fil och sedan file->send raw file  fr�n menyn

//////////////////////////////////////////////////////////////////////
//F�reberedelse uppgift F1 Antag att cachens parametrar �r A = 4 , CL= 16 och CM = 256 kB, 
//precis som i avsnitt 3.1.1 och att processorn har f�tt en cachemiss p� 
//M ($12345678) = $ DEADBEEF . En CL kommer att h�mtas och skrivas in i CM. Ok�nda
//minnesdata kallas f�r X . Fyll i diagrammet nedan: 

//index : tag |byte0-3| byte4-7| byte8-11| byte12-15 :
//------------|-------|--------|---------|----------
// 567  : 1234|   X   |   X    |    X    | DEADBEEF
//////////////////////////////////////////////////////////////////////
//
// 5.2 F�rberedelseuppgift F.2 I figur 5 finns ett exempel p� hur det ser
// ut i ChipScope n�r en cachemiss intr�ffar i samband med en l�sning p�
// adress $82000000 . Notera att detta, till skillnad ifr�n F.1, �r taget
// direkt ifr�n det system ni ska anv�nda i laborationen och allts� inte
// ett p�hittat exempel
// 
// givet busstrafiken i figur 5 s� kan du best�mma n�gra viktiga
// parametrar i det system du anv�nder i labo- rationen; Hur l�ng
// f�rdr�jning �r det fr�n det att en l�sning startar till att det f�rsta
// ordet i burstl�sningen kommer tillbaka? Hur l�ng �r en cacheline?
svar: read signal allts� rikttning slave till master. L�sning 
      inleds med att address l�ggs araddr l�ggs p� addressbussen varp� 
      vi signalerar att att valid address ligger p� buss med arvalid. 
      Vi master �r vill allts� p�b�rja l�sning. N�r f�rsta datat ligger
      stabilt p� read data channel s� signalerar data bussen med hj�lp av
      rvalid att s� �r fallet varp� l�sning fr�n data bussen kan p�b�rjas.
      Notera att b�de RREADY och AREADY g�r h�ga under hela denna tid(cykel).
      Allts� 
      74-53 = 21 (klockcykler???)

      Vi antar att det som sker h�r �r att en hel cacheline l�ses in fr�n 
      PM till CM. ARLEN = 7 allts� och ARSIZE �r 2. skall tolkas som 
      8 ord a 4byte (breda). Dvs en cacheline skulle vara 8 ord  a 4 byte
      8*4 32byte eller 8*4*8 =  bitar
