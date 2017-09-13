(set-face-attribute 'default nil :height 200)
• associativitet. A = K.
• cachelinens storlek. CL = 4 · 2 L Byte
• cachens storlek. CM = K · 2 N · 4 · 2 L Byte
---------------------------------------------------------------------
Sammanfattning av L2 cachen 
L2 cache to 512KB
L2 cacheline 32Byte
   ger totalt antal cachelines (fördelat över x antal cachar)
512kb =524288 byte
524288/32 = 16384 lines 

----------------------------------------------------------------------
Förberedelse uppgift F.1

-Antag att cachens parametrar är A = 4 , CL = 16 och CM = 256 kB,
precis som i avsnitt 3.1.1 och att processorn har fått en cachemiss på
M ($12345678) = $ DEADBEEF . En CL kommer att hämtas och skrivas in i
CM. Okända minnesdata kallas för X. Fyll i diagrammet nedan:

dvs. associatitivitet är 4 
     en CacheLine är 16 byte?

index : tag  byte0-3 byte4-7  byte8-11   byte12-1
 567  : 1234    X      X     $DEADBEEF     X
------------------------------------------------------------------------
Förberedelseuppgift F.2

   Fördröjningen är 74-53=51 enheter (klockcykler) 
   En cache-line är förmodligen 8 ord a 4byte = 32 byte långa  
   Size=2 indikerar ordbred 4byte,Len=7 indikerar 8 ord ska överföras
------------------------------------------------------------------------
Uppgift 1

512kb =524288 byte
524288/32 = 16384 lines 
notera slumpmässig ersättnings policy används 

Vid räkning kom vi fram till att 
om 2-vägs cache så är tagen 14 bitar index 13 bitar w 3 och B 2
om 4-vägs cache så är tagen 15 bitar index 12 bitar w 3 och B 2
om 8-vägs cache så är tagen 16 bitar index 11 bitar w 3 och B 2

