;;----------------------------------------------------------------------
;; Partitioning of addresspace
;;
;; $900-903     : current time 
;;
;; $1000 	: start (pc at start)
;; $7000	:suggested top of stack
;;----------------------------------------------------------------------
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
;; A0: Base address of constant table (bitpatterns for 7 led seg) 
;; A1: Address part of time thats in turn to be displayed
;; D0: 
;;
;;-----------------------------------------------------------------------
;;
START
	lea $07000,A7
	jsr PIAINIT
	jsr TIMEINIT
	jsr MAIN
	move.b #255,d7 ;;avsluta programmet och dumpa alla register med
	trap #14
	rts

;;
;;--------------------------------------------------------------------
;;
;; Sets up pia in th following manner
;; PIA A0-A6 as out (used for number display)
;; PIA A7 in (not used) 
;; PIA B0-B1 as out (used for multiplexing segments of display) 
;; CA1 as in external interupt
;; CB1 as in external interupt
;;----------------------------------------------------------------------
;;
PIAINIT
	clr.b $10084	 ;CRA DDRA, CA1=IRQ:s not put throught to cpu
	clr.b $10086 	 ;CRB DDRB, CB1=IRQ:s not put throught to cpu
	move.b #127,$10080	;PIAA A0-A6 out A7 in 
	move.b #3,$10082	;PIAB B0-B1 out B2-B7 in 
	move.b #31,$10084	;CRA, PIAA, CA active, trigger on 0->1
	move.b #31,$10086	;CRB, PIAB, CB active, trigger on 0->1
	tst.b  $10080           ;reset the aknowledge 
	tst.b  $10082		;reset the aknowledge
	rts

TIMEINIT
	;;Spärra för avbrot även här inga avbrott under initiering tack
	move.l #DISPLAYTIME,$068;irq2
	move.l #TICK,$074 	;irq5
	clr.l $900 		;clear memory in 900-903
	clr.l d0		;clear registers
	clr.l d1
	;; lea $900,A1
	move #$900,$800
	and.w #$F8FF,SR		;set interuppt-level 0
	rts
;;
;;----------------------------------------------------------------------
;; Prints out time to the LED-display
;;
;; Individual numbers are stored at $900-$903 where LSB is $900
;; so for instanse the time 06:34 would be mapped in memory as (32-bits)
;;
;;
;;   $903        $900  4X8=32bits
;;   -----------------
;;   | 0 | 6 | 3 | 4 |
;;   -----------------
;;   
;;  In: A1 address to current decimal to be displayed
;;  	A0 address to base of table containing bitpattern 
;;	   that represent number in 7 segment led.
;;
;;----------------------------------------------------------------------
;;
DISPLAYTIME
	move d0,-(a7) 		;push d0 to stack
	move A1,-(a7) 		;push d0 to stack
	move $800,a1		;because of lab requirements
	tst.b $10082
	;; and #$2700,SR
	add.l #1,A1 		
	cmp.l #$904,A1 		;todo 903
	bne notlast_displaytime 
	move.l #$900,A1
notlast_displaytime
	move.b (a1),d0
	move.b #0,$10080
	jsr SETSEGMENTTODISPLAY ;Think of a better name
	jsr GET7SEGNR		;
	jsr PUTTODISPLAY	;
	move a1,$800		;store away value in memory
	move (a7)+,a1		;pop stack to d0
	move (a7)+,d0		;pop stack to d0
	rte

;;----------------------------------------------------------------------
;;  
;; Assumes address to current time nr in A1 ($900-$903)
;; calculates which of the four number on the display is to be used
;; for output. 
;; A1 is destroyed
;;----------------------------------------------------------------------	
;; 
SETSEGMENTTODISPLAY
	move d3,-(a7) 		;push d3 onto stack
	move a1,d3
	and.l #$0F,d3
	move.b d3,$10082
	move (a7)+,d3		;pop stack to d3
	rts

;;----------------------------------------------------------------------
;;  
;; Gets bitpattern given number in D0
;; Note D0 is reset to its original value inside dislaytime no need
;; to reset value here it will be throw away in any case. 
;; 
;;----------------------------------------------------------------------	
;; 
GET7SEGNR
	move A0,-(A7)
	and.l #$F,D0 		;Only four bites please
	lea SJUSEGTAB,A0
	add.l D0,A0		;Calc address of wanted bitpattern
	move.b (a0),D0		;return bittpattern i d0
	move (A7)+,A0
	rts
;;----------------------------------------------------------------------
;;
;; pushes number to the display 
;; Assumes correct number in d0. 
;; 
;;----------------------------------------------------------------------	
;; 
PUTTODISPLAY
	move.b d0,$10080	
	rts

;;----------------------------------------------------------------------
;;  
;; Increment time by one second this is the interuppt handler for irq5
;; 
;;----------------------------------------------------------------------	
;;
TICK
	move d4,-(a7)
	tst.b $10080		;check wheter this is correct
	move.l $900,d4
;	move.l d4,d5
;	and.l #$FF000000,d5
;	cmp.l #$09000000,d5
;	beq TICK_SEC_CARRY
;	add.b #1,$900
;	bra TICK_END
;TICK_SEC_CARRY:
;	move.b #00,$900
;	move.l d4,d5
;	and.l #$00FF0000,d5
;	cmp.l #$00050000,d5
;	beq TICK_TEN_SEC_CARRY
;	add.b #1,$901
;	bra TICK_END
;TICK_TEN_SEC_CARRY:	
;	move.b #00,$901
;	move.l d4,d5
;	and.l #$0FF00,d5
;	cmp.l #$00000900,d5
;	beq TICK_MIN_CARRY		
;	add.b #1,$902
;	bra TICK_END
;TICK_MIN_CARRY:	
;	move.b #00,$902
;	move.l d4,d5
;	and.l #$0FF,d5
;	cmp.l #$00000005,d5
;	beq TICK_TEN_MIN_CARRY		
;	add.b #1,$903
;	bra TICK_END
;TICK_TEN_MIN_CARRY:	
;	move.l #$00,$900
;TICK_END:	
;	rte

	add.l #$1000000,d4
	cmp.l #$A000000,d4
	bcs tock
	and.l #$0FFFFFF,d4		;first segment to zero
	add.l #$10000,d4
	cmp.l #$60000,d4
	bcs tock
	and.l #$0000FFFF,d4		;second segment to zero
	;; swap d4
	add.w #$100,d4
	cmp.w #$900,d4
	;; bne resetD4
	bcs tock
	and.l #$00FF,d4		;third segment to zero
	add.b #1,d4
	cmp.b #6,d4
	bne tock
	clr.l d4			;reached limit of our clock
;;resetD4:
	;;swap d4
tock:
	move.l d4,$900		;incremented time pushed back to mem
	move (a7)+,d4
	rte

;;
;;----------------------------------------------------------------------
;;
;; Table of constants represent numbers 0-9 in in led-display
;;   	 
;;  Mapping of input connectors on board to LED segtments
;;    _A_
;;  F|_G_|B
;;  E|___|C
;;     D
;;
;;   Hardwired mapping from PIAA to 7-SEG
;;     6   5   4   3   2   1   0
;;   ----------------------------
;;   | G | F | E | D | C | B | A |
;;   ----------------------------
;;
;;----------------------------------------------------------------------
;;
SJUSEGTAB 
	  dc.b $3F ;0
	  dc.b $06 ;1
	  dc.b $5B ;2
	  dc.b $4F ;3
	  dc.b $66 ;4 
	  dc.b $6D ;5
	  dc.b $7D ;6
	  dc.b $07 ;7
	  dc.b $7F ;8
	  dc.b $67 ;9 


MAIN
	stop #$2000
	bra MAIN
	rts

;;Frågor 1) kontrollera funktionalitet kan tex göras genom att kika på registren	
;; 	    vi använde tutors funktionalitet för avbrott A/B för att simulera avbrott
;;	    och dumpade minnet på 10082 10080 tex.		
;;
;;fråga 2)  Läsning utanför kan tex ske om felaktigt värde finns i d0 när GET7SEGNR
;;          anropas. Kan eventuellt hanteras med controll att vi ligger inom rimligit 
;;	    index och om vi är på humor kanske tom skriva en mjukvaruavbrottsrutin
;;          för att hantera felet (tex återställ d0 till lämpligt värde). Annars
;;	    räcker det möjligtvis med att bara ställa eller läsa in värdet igen alt 	
;;	    hoppa den display ett varv vad man nu tycker är lämpligt mjukvaruavbrott
;; 	    kanske inte behövs.	
;;
;;
