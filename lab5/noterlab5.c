//running chipscope
//module add xilinx/14.4i
//analyzer
//JTAG Chain->Digilent USB JTAG Cable

//ladda in config filen  i chipscope
//play knappen för att börja analysera 
//testade commadot m 9fff0000 1234abcd i gtkterm 

//terminalen
//gtkterm -s 115200 -p /dev/ttyACM0

//l för ladda fil och sedan file->send raw file  från menyn

//////////////////////////////////////////////////////////////////////
//Föreberedelse uppgift F1 Antag att cachens parametrar är A = 4 , CL= 16 och CM = 256 kB, 
//precis som i avsnitt 3.1.1 och att processorn har fått en cachemiss på 
//M ($12345678) = $ DEADBEEF . En CL kommer att hämtas och skrivas in i CM. Okända
//minnesdata kallas för X . Fyll i diagrammet nedan: 

//index : tag |byte0-3| byte4-7| byte8-11| byte12-15 :
//------------|-------|--------|---------|----------
// 567  : 1234|   X   |   X    |    X    | DEADBEEF
//////////////////////////////////////////////////////////////////////
//
// 5.2 Förberedelseuppgift F.2 I figur 5 finns ett exempel på hur det ser
// ut i ChipScope när en cachemiss inträffar i samband med en läsning på
// adress $82000000 . Notera att detta, till skillnad ifrån F.1, är taget
// direkt ifrån det system ni ska använda i laborationen och alltså inte
// ett påhittat exempel
// 
// givet busstrafiken i figur 5 så kan du bestämma några viktiga
// parametrar i det system du använder i labo- rationen; Hur lång
// fördröjning är det från det att en läsning startar till att det första
// ordet i burstläsningen kommer tillbaka? Hur lång är en cacheline?
svar: read signal alltså rikttning slave till master. Läsning 
      inleds med att address läggs araddr läggs på addressbussen varpå 
      vi signalerar att att valid address ligger på buss med arvalid. 
      Vi master är vill alltså påbörja läsning. När första datat ligger
      stabilt på read data channel så signalerar data bussen med hjälp av
      rvalid att så är fallet varpå läsning från data bussen kan påbörjas.
      Notera att både RREADY och AREADY går höga under hela denna tid(cykel).
      Alltså 
      74-53 = 21 (klockcykler???)

      Vi antar att det som sker här är att en hel cacheline läses in från 
      PM till CM. ARLEN = 7 alltså och ARSIZE är 2. skall tolkas som 
      8 ord a 4byte (breda). Dvs en cacheline skulle vara 8 ord  a 4 byte
      8*4 32byte eller 8*4*8 =  bitar
