;;----------------------------------------------------------------------
;; Partitioning of addresspace
;; In use $900-$7000. Note $2000-$2500 reserverd for preprogrammed 
;; subroutines.
;; suggestion is to use 1000 1100 1200 ... etc for your
;; own subroutines in assignment 1 
;; 
;; $1000 	: start (pc at start)
;; $7000	:suggested top of stack
;;----------------------------------------------------------------------
;; Given sobroutines
;; 
;; $20EC PINIT 
;;   	 sets PA7-PA0,PB7-PB0 as out, CA1,CA2,CB1,CB2 
;; 	 programmed to interput on positive (flank:-)
;;
;; $2020  SKABAK
;; 	  Prints to terminal BAKGRUNDSPROGRAM to the left.
;; 
;; $2048 SKAVV
;;  	 Prints to center of the terminal (1s intervall)
;;       AVBROTT vänster 
;;	 *
;;	 *
;;	 *
;;	 *	 
;;	 SLUT vänster
;;  	 soubroutin asummes interupt level 2
;;
;; $20A6 SKAVH
;;  	 Prints to the right hand side of the terminal
;;       AVBROTT höger 
;;	 *
;;	 *
;;	 *
;;	 *	 
;;	 SLUT höger
;;  	 soubroutin asummes interupt level 5 
;;
;; $2000 DELAY
;; 	 delay takes param in D0 interpeted as ms
;;
;;----------------------------------------------------------------------
;; 	
;; Cheet sheet 	
;; 	
;;  C300 SKYFFLA  	
;;  20EC PINIT
;;  $2020 SKBAK	
;;  $2048 SKAVV 	
;;  $20A6 SKAVH	
;;  $2000 DELAY
;; 
;;  CB = IRQB =I1 =IRQ2 = interruptlevel 2 = interuptvector @$68 = Interuptroutine @$1100
;;  CA = IRQA =I0/2 = IRQ5 = interruptlevel 5 = interuptvector @$74 = Interuptroutine @$1200
;;  IRQ7 = black button always get priority
;;
;;   Above in short CB generats interuppt at level2. Which looks upp its routine-address at $68
;;   Above in short CA generats interuppt at level5. Which looks upp its routine-address at $74
;; 
;;   SR=2700 pay attention to what happens to 7 that number setting IPL0-3
;;   (bits 8,9,10 in SR )
;;  
;;   External signal CA1 sets CRA7
;;   External signal CA2 sets CRA6
;;   These are automatically reset when we read PIAA    
;;
;;   When interuppt occurs SR and PC are pushed on stack. 
;;   When returning from interuppt PC and SR are reset.
;;   Implication of this is that the INTERUPTLEVEL IS RESET
;;   to it's previous level when returning from interuppt
;;   since interupptlevel is indicated in SR I0-2
;;  
;;  
;;  
;;   15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;;   ------------------------------------------------ :SR  
;;  | T|  | S|  |  |I2|I1|I0|  |  |  |X |N |Z |V |C |  
;;   ------------------------------------------------
;;  
;;
;;   7  6  5  4  3  2  1  0
;;   ------------------------ :CRA      $10080 data direction A (bit 2 in CRA=0)
;;  |  |  |  |  |  |  |  |  |           $10080 PIAA dataregister A (bit 2 in CRA=1)
;;   ------------------------           $10084 CRA Cotntrol register A
;;  ------ -------- -- -----            $10082 data direction B
;;    |        |     |   |Styr CA1      $10082 data PIAB dataregister B
;;    |        |     |                  $10086 CRB Control register B
;;    |        |     |0:DDRA
;;    |        |     |1:PIAA
;;    |        |
;;    |        |styr CA2
;;    |
;;    |signalflaggor
;;     avbrott
;;
;;
;;   15 14 13 12 11 10 9  8  7  6  5  4  3  2  1  0
;;   ------------------------------------------------
;;  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  
;;   ------------------------------------------------
;;   
;;-----------------------------------------------------------------------
;;
;;jsr  $C300			för att skyffla 
 ($1000-$1036 1040 with trap instruction ) 
INIT      
	lea $7000,A7	       	; set stackpointer
	jsr PINIT	       	; initiat pia $20EC
	move.L #$1100,$068     	; interruptvector for irq-level 2
	move.L #$1200,$074     	; interruptvector for irq-level 5
				; set IPL0/2=1 IPL1=1 interrupt level0 interupt mask
	 			; these are found in sr bit 10,9,8
				; according to manual these are reset at a read of pia datareg
				; AND.W #data,SR  as priviliged operation
	tst.b $10080		;nollställ interupt ca1
	tst.b $10082		;nollställ interupt cb1	
	move.w #$2000,SR	;change to and at some point	
UPPGIFT1
	jsr SKBAK      		;$2020
	MOVE.L #1000,D0
	jsr DELAY      		;$2000
	jmp UPPGIFT1 		;$1028

UPPGIFT2			;$1100
	tst.b 10082		;funkar tst här (utgång) behöver
	jsr SKAVV		;$2048
	rte			;behöver ipl0-2

				
	tst.b 10080		;$1200
	jsr SKAVH		;$20A6
	rte 			;återställer sr och pc behöver hantera separat
 
;;-----------------------------------------------------------------------
;;
;; Avbrottsförförfrågan på nivå 2(irqa b?) tas emot av processorn men. Men
;; men har inte tillräcklig hög "nivå" för att avbryta avbrottsrutinen på
;; nivå 5 
;;
;; AVBROTT v{nster
;;           *
;;           *
;;           *
;;                          AVBROTT h|ger
;;                                 *
;;                                 *
;;                                 *
;;                                 *
;;                                 *
;;                             SLUT h|ger
;;                          AVBROTT h|ger
;;                                 *
;;                                 *
;;                                 *
;;                                 *
;;                                 *
;;                             SLUT h|ger
;;           *
;;           *
;;       SLUT v{nster
;;    AVBROTT v{nster
;;           *
;;           *
;;           *
;;           *
;;           *
;;      SLUT v{nster
;;
;;-----------------------------------------------------------------------
;; uppgift 3
;; Under utskriften av av bakgrundsprogram kan vi höj avbrottsnivån till  
;; nivå 7. Dvs vi låser körningen kring then kritiska sektionen 
;;
;; dvs abortknappen har IRQ7 men går alltid igenom den får specialbehandling
;; för att systemet enkelst skall kunna avbrytas utan att det hänger sig
;; på nivå 7
;;-----------------------------------------------------------------------
UPPGIFT3
	move.w #$2700,SR	;set level to 7
	jsr SKBAK      		;$2020
	move.w #$2000,SR	;reset ir level use and instead
	MOVE.L #1000, D0
	jsr DELAY      		;$2000
	jmp UPPGIFT1 		;$1028

set_ir_level 7 			;($1300)
	OR.W #$0700,SR 	         ;mask interrupt to level 7
	rts 
	
	move.b #255,d7
	trap #14

;;-----------------------------------------------------------------------
;;
;; Svar uppgift 4 översta 4 bytesen är innehållet i d1(vad nu anropande programmet
;; har lagt där). Just denna gång var värdet 00 00 00 57
;; längst ner på stacken låg återhopps addressen 00 00 10 3E 
;; dvs addressen som följer efter delay anropet i huvudprogrammet.
;;
;;-----------------------------------------------------------------------
;;	--------------
;;	address | Data
;;	--------------		
;;	| 6FF8  | 00 |
;;	--------------	
;;	|   -   | 00 |  :D1-Registret
;;	--------------
;;	|   -   | 00 |
;;	--------------
;;	|   -   | 57 |
;;   ------------------------
;;	|   -   | 00 |
;;	--------------
;;	|   -   | 00 |  :Återhoppsaddress
;;	--------------
;;	|   -   | 10 |
;;	--------------
;;	| 6FFF  | 3E |
;;	--------------
;;
;;	
;;-----------------------------------------------------------------------
;;
;; Svar uppgift 5	
;; Stackpekarns värd 6FDC (stacken växer uppåt från 7000 hex, 36dec = 24hex
;; 7000-24=6FDC) Vilket också stämmer när man testkör
;;
;; Noter stacken räcknas ner sedan läggs data in uppifrån och ner
;;       	 BR lägger tillfälligt in felaktig instruction 4E73 
;;		 på den address där där "brytning" ska ske.
;;               När vi når brytpunkter kommer instruction återställas
;;               till sin ursprungs instuktion.
;;
;;-----------------------------------------------------------------------
;; Följande är tänkt att illustrera körning från det att backgrunprogrammet
;; tar vid. 1100 är vår subrutin för vänster och 1200 för höger avbrott.
;; 
;; Backgrundsprg. 
;;   |  
;;   |     .Delay
;;   |    /|      .1100
;;   |   / |     /
;;   |  /  |    /  |    .SKAVV 
;;   | /   |   /   |   / |   
;;   |/    |  /    |  /  |    .Delay
;;         | /     | /   |   / |  
;;         *IRQ_2  -     |  /  |    .SKAVH -BREAKPOINT
;; 		         | /   |   /   
;; 			 -     |  /  
;; 			       | /   
;; 			       *IRQ_5
;;---------------------------------------------------------------------- 				     
;;
;; Svar 5. Det sker inget avbrot i backgrundsprogrammet utan i delay 
;;         subrutinen. I vårt fall inträffade det efter att instruktionen
;;         på address $2002 exekverats.
;;         Likaså skede avbrottet på nivå 5 i Delay rutinen. Denna 
;;         gång å efter att insruktionen på address 2008 exekverats
;;         färdig och 200E skulle påbörjas. 
;; 
;; 
;;
;;
;;----------------------------------------------------------------------
;;  AT BREAKPOINT
;;  PC=000020A6 SR=2504=.S5..Z.. US=FFFFFFFF SS=00006FDC 
;;  D0=00000207 D1=00000067 D2=FFFFFF05 D3=00000012 
;;  D4=FFFFFFFF D5=FFFFFFFF D6=FFFFFFFF D7=FFFFFFF3 
;;  A0=0000C000 A1=FFFFFFFF A2=FFFFFFFF A3=FFFFFFFF 
;;  A4=FFFFFFFF A5=0000C181 A6=0000C181 A7=00006FDC 
;;  --------------------0020A6    2A7C0000C1A9         MOVE.L  #49577,A5 
;;  
;;  	
;;  006FDC    00 00 12 0A   22 00 00 00  20 0E 00 00   00 22 00 00  ...."... ...."..
;;  006FEC    20 6E 00 00   11 0A 20 00  00 00 20 08   00 00 00 3C   n.... ... ....<
;;  006FFC    00 00 10 3E   00 02 00 C0  04 83 10 00   00 83 00 01
;;  
;;----------------------------------------------------------------------
;;      --------------                                   --------------      
;;      address | Data			                 address | Data      
;;      --------------                                   --------------
;;      | 6FDC  | 00 | ÅTERHOPPS ADRESSEN TILL           |   -   | 00 |  JSR LÄGGER ÅTERHOPPSADDRESSEN 
;;      -------------- HÖGER-AVBROTTS-HANTERAREN	 --------------  TILL VÅR VÄNSTER-AVBROTTS-HANTERAR-
;;      |   -   | 00 |                                   |       | 00 |  SUBRUTIN NÄR HOPP TILL SKAVV SKER
;;      --------------                                   --------------  (SÅ HITTAR SKAVV TEBAX)                             
;;      |   -   | 12 |                                   |       | 11 |                               
;;      --------------                                   --------------                               
;;      |   -   | 0A |                                   |   -   | 0A |                               
;;   ----------------------                         -----------------------                           
;;      |   -   | 22 | SR DÅ ANDRA AVBROTTETT            |   -   | 20 |  -SR DÅ FÖRSTA AVBROTT                     
;;      -------------- INTRÄFFADE                        --------------   INTRÄFFADE 
;;      |   -   | 00 |                                   |   -   | 00 |   SR 16 BITTAR LÅNG                                       
;;   ----------------------                         ------------------------                          
;;      |   -   | 00 |  ÅTERHOPPSADR I DELAY             |   -   | 00 |  -ÅTERHOPPSADR TILL                              
;;      --------------  (DÅ AVBROTT NIVÅ 5               --------------   DELAY FRÅN                             
;;      |       | 00 |   INTRÄFFAR)                      |   -   | 00 |   (FRÅN FÖRSTA AVBROTTETT)                            
;;      --------------                                   --------------                               
;;      |   -   | 20 |                                   |   -   | 20 |  
;;      --------------                                   --------------    
;;      |   -   | 0E |                                   |       | 08 |                               
;;   ---------------------                           ------------------------                          
;;      |   -   | 00 | DELAY LÄGGER D0                   |   -   | 00 |                               
;;      -------------- PÅ STACKEN                        --------------                               
;;      |       | 00 |                                   |   -   | 00 |                               
;;      --------------                                   --------------                               
;;      |   -   | 00 |                                   |   -   | 00 |  -DELAY LAGRAR D0 PÅ STACK    
;;      --------------                                   --------------                               
;;      |   -   | 22 |                                   |    -  | 3C |                               
;;   ----------------------                           ------------------------                          
;;      |   -   | 00 |  ÅTERHOPPS ADDRESS                |  6FFC | 00 |                               
;;      --------------  TIILL PUNKT I SKAVV              --------------                               
;;      |   -   | 00 |  (SKAVV GÖR SUBRUTINS             |   -   | 00 |                               
;;      --------------   HOPP TILL DELAY)                --------------                               
;;      | 6FEC  | 20 |                                   |   -   | 10 | -ÅTERHOPPS ADDRESS TILL       
;;      --------------                                   --------------  HUVUDPROGRAM                 
;;      |   -   | 6E |                                   |  6FFF | 3E |                               
;;      --------------                               	---------------
;;  
;;---------------------------------------------------------------------------------------------------
;;	                                             
;;	                                                                   
;;	--------------                                 --------------      
;;	address | Data			               address | Data      
;;	--------------			               --------------          
;;	| 6FDC  | 00 |			               |       |    |      
;;	--------------			               --------------      
;;	|   -   | 00 |  :D1-Registret	               |   -   |    |  :D1-
;;	--------------			               --------------      
;;	|   -   | 00 |			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   | 57 |			               |   -   |    |      
;;   ------------------------		          ------------------------ 
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    | 			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|       |    |			               |       |    |      
;;   ------------------------		          ------------------------ 
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    | 			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|       |    |			               |       |    |      
;;   ------------------------		          ------------------------ 
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    | 			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|       |    |			               |       |    |      
;;    ------------------------		           ------------------------
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    | 			               |   -   |    |      
;;	--------------			               --------------      
;;	|   -   |    |			               |   -   |    |      
;;	--------------			               --------------      
;;	|       |    |			               |       |    |      
;;	--------------      		               --------------      
;;
            
    
