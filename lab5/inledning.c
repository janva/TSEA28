//(set-face-attribute 'default nil :height 200)
• associativitet. A = K.
• cachelinens storlek. CL = 4 · 2 L Byte
• cachens storlek. CM = K · 2 N · 4 · 2 L Byte
---------------------------------------------------------------------
Sammanfattning av L2 cachen 
L2 cache to 512KB
L2 cacheline 32Byte
   ger totalt antal cachelines (fördelat över x antal cachar)
512kb =524288 byte
524288/32 = 16384 lines = 4000 hex
16384/8 = 2048 antalet index
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

   Fördröjningen är 74-53=21 klockcykler
   En cache-line är förmodligen 8 ord a 4byte = 32 byte långa  
   Size=2 indikerar ordbred 4byte,Len=7 indikerar 8 ord ska överföras
------------------------------------------------------------------------------
Uppgift 1

Följande instruktioner lägg på instruktionscachen vid första transaktionen.
transaktion inleder med att hämta instructioner från 82000010 som ligger i spanet
82000000-8200001f (sista ordet börjar  8200001c). 
Alltså blir cachelinen 82000000-8200001f

82000000 <chipscope_dummy>:
82000000:	e3a03482 	mov	r3, #-2113929216	; 0x82000000
82000004:	e5930000 	ldr	r0, [r3]
82000008:	e2800001 	add	r0, r0, #1
8200000c:	e12fff1e 	bx	lr

82000010 <fetchtest>:
82000010:	e92d0030 	push	{r4, r5}
82000014:	e5d05000 	ldrb	r5, [r0]
82000018:	e5d04001 	ldrb	r4, [r0, #1]
8200001c:	e5d03002 	ldrb	r3, [r0, #2] 

---------------------
82000020:	e0812005 	add	r2, r1, r5
82000024:	e5d05003 	ldrb	r5, [r0, #3]
82000028:	e082c004 	add	ip, r2, r4
8200002c:	e5d04004 	ldrb	r4, [r0, #4]
82000030:	e08c1003 	add	r1, ip, r3
82000034:	e5d0c005 	ldrb	ip, [r0, #5]
82000038:	e0812005 	add	r2, r1, r5
8200003c:	e5d01006 	ldrb	r1, [r0, #6]
----------
82000040:	e0823004 	add	r3, r2, r4
82000044:	e5d02007 	ldrb	r2, [r0, #7]
82000048:	e083300c 	add	r3, r3, ip
8200004c:	e5d0c008 	ldrb	ip, [r0, #8]
82000050:	e0833001 	add	r3, r3, r1
82000054:	e5d01009 	ldrb	r1, [r0, #9]
82000058:	e0833002 	add	r3, r3, r2
8200005c:	e5d0200a 	ldrb	r2, [r0, #10]
------
82000060:	e083300c 	add	r3, r3, ip
82000064:	e5d0c00b 	ldrb	ip, [r0, #11]
82000068:	e0833001 	add	r3, r3, r1
8200006c:	e5d0100c 	ldrb	r1, [r0, #12]
82000070:	e0833002 	add	r3, r3, r2
82000074:	e5d0200d 	ldrb	r2, [r0, #13]
82000078:	e083c00c 	add	ip, r3, ip
8200007c:	e5d0000e 	ldrb	r0, [r0, #14]


-fetchtest hämtas efter 55 klockcykler och tar 86 klockcykler 
   innan läsning på 0x85123456 (0224C290)
------------------------------------------------------------------------
Uppgift 2
   
   //512kb =524288 byte
   //524288/32 = 16384 lines 
notera slumpmässig ersättnings policy används 

Vid räkning kom vi fram till att 
om 2-vägs cache så är tagen 14 bitar index 13 bitar w 3 och B 2
om 4-vägs cache så är tagen 15 bitar index 12 bitar w 3 och B 2

Vi kom fram till att vårt system har 8-vägs associativitet. Vi använde
   steget hex 0x100000 detta gav oss annan tag men samma index. genom att
sedan pilla på antals parameter visade sig att vid 8 kastad fortfarande 
inga ut ur cachen men med parametern satt till 9 fick vi cache missar.
-------------------------------------------------------------------------
Uppgift 3
vi har alltså 512/8= 64kb stor enskilda cachar 
vilket ger 2'16=65536 byte 65536/32= 2048 olika index(rader i cachen)

kommentar frågan 960= 2*480, 1280=2*640 (går 2 byte på varje pixel)
------------------------------------------------------------------------
Rotation av bild
Referensbilden ligger i cachebart primärminne.
Om vi tittar på illustrationen av referencebilden i labhäftet så kan 
vi intuitivt komma fram till att vid 90 grader vridning kommer vi 
läsa rutnätet kolumnvis. Dvs med förskjutningar 0,4096,8192 osv om 
vi vrider hela rutnätet (hela referensbilden). 4096= 1000 hexadeximalt.
Referensbilden startar på 81800000. Alltså är addresser som läses in 
81801000, 81802000,81803000... där i vårt L2 cache 8180 utgör tag, 
010, 020,030 ungefär utgör index.  
  Vi kan också använda
formel (1) 2(x +2048y) + $81800000 kan också användas för med liknande 
resonemang vi x=0 för det som blir första raden i framebuffferten.raden medans y stegas upp med 1. hmm 2048 är antalet index vi har att tillgå...
2(0 +2048*1) + $81800000 =  $81801000 Notera som VL blandet hex och dec  
2(0 +2048*2) + $81800000 =  $81802000
2(0 +2048*3) + $81800000 =  $81803000

...                          $8180 F000

2(0 +2048*320) + $81800000 =  $81940000
2(0 +2048*321) + $81800000 =  $81941000
2(0 +2048*322) + $81800000 =  $81942000
...
2(0 +2048*638) +$81800000 = $81A78000 
2(0 +2048*639) +$81800000 = $81A79000 
2(0 +2048*640) +$81800000 = $81A80000 
-----------------ovan första raden i fb---------- 
2(1+2048*1) + $81800000  =  $81801002
2(1 +2048*2) + $81800000 =  $81802002
2(1 +2048*3) + $81800000 =  $81803002
..                         
2(1 +2048*638) +$81800000 = 81A7E002
2(1 +2048*639) +$81800000 = 81A7F002
2(1 +2048*640) +$81800000 = 81A80002
-------------------------ovan andra raden som läses in i fb----

------------------------------------------------------------------
8.2 totalt antal transaktion 90 grader rad 0 460. över klockcykler 8191
    första inkommande adress
Läsningar som görs
 81AC09E0    skiljer 1000 hex vår beräkningar stämmer från ovan
 81AC19E0                            
 81AC29E0
 81AC39E0
 81AC49E0
 81AC59E0
    ...
81C8A9E0
81C8B9E0

 81AC19E0- 81AC19E0= 1cb000 -> 1bc + 1 transaktioner hex ->459 +1 transaktion decimalt
antal transktioner kan skilja och vårt fall skiljer de sig. Detta då efter ett tag kan ligga saker i cachen som faktiskt är användbart. tex fick vid en körnining 460 på
rad 0 och 307 på rad 10. 


antal transaktion vid 0 grader rad 0 117 över 8191 klockcyckler.
första transaktionen börjar på address 
81B0F580
81B0F5A0      
 ...
81B11980
81B119A0 

dvs stegar 20 byte hexadecimalt vilket är 32 byte decimalt vilket är storleken av en cacheline 

8.4
antalet transaktion för rad 0 90grader fick vi till 192 vilket är stor förbrättring från tidagere 460
vi räknade till 673 klockcykler per rad(40 transaktioner) (7022)?????
------------------------------------------------------------------------------
vid 90 grader var det först över 8200 klcok 640 cache missar
efter ändringar 2989 klockcykler och 128 cache missar missar
0 grader samma för båda 2771 och 40 cachmissar.



