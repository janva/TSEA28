;;----------------------------------------------------------------------
;; Partitioning of addresspace
;; In use $900-$7000. Note $2000-$2500 reserverd for preprogrammed 
;; subroutines.
;; 
;; $1000 	: start (pc at start)
;; $7000	:suggested top of stack
;;----------------------------------------------------------------------
;; The following subroutines from the ROM was used in this part
;; 
;; $20EC PINIT 
;;   	 sets PA7-PA0,PB7-PB0 as out, CA1,CA2,CB1,CB2 
;; 	 programmed to interput on positive (flank:-)
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
;; D0: Tidsfördröjning vid anrop av DELAY.
;; D2: Lagring av hur lysdioderna är tända.
;; D3: Resultatregister spelare A.(vänster)
;; D4: Resultatregister spelare B.(höger)
;; D5: Flyttningsriktning: 00=vänster, FF=höger.
;; D6: Servstatus: 00=ej serve, FF=serve.	
;;
;;-----------------------------------------------------------------------
;;
start
	lea $7000,A7		;set stackpointer
;;; 	jsr $C300		;special inte subrutin?
	jsr $20EC	    	;PINIT
	jsr setupInterrupts   	;maps interuppts to there handler subroutines
	jsr initNewGame
	jsr run
	move.b #255,d7
	trap #14
	rts

setupInterrupts
	move.l leftButton,$068 	;irq-level2 handler @$1100
	move.l rightButton,$074 	;irq-level2 handler @$1200
	tst.b $10080		;nollställ interupt ca1
	tst.b $10082		;nollställ interupt cb1
	;;TODO chang to and or or instead
	move.w #$2700,SR	;We don't want any interrupts during initiation
	rts
	;; problem vill ha kunna nollställa spelet utan  att behöva
	;; köra setupInterrupts, är det ok att tillfälligt stänga av
	;; irq via CRA,CRB hmm inte tillåtet,
	;; ser två lösngingar
	;; 1) använd tillfälliga irq-hanterare (1100, 1200) till subrutin
	;; som bara dumpar inkommande interupter
	;; 2) start alltid från början med initNewGame sedan setupInterupts
	;;    dock löser nog dettta inte problemet
initNewGame
	or.w #$0700,SR		;Don't handle irq:s during init
	move.l #500,D0		;Time each diode will be lit
	move.l #$80,D2		;Start ball in left  position
	move.l #$00,D3		;Player A score 0
	move.l #$00,D4		;Player B score 0
	move.b #$00,D5		;Starting from left 
	move.b #$FF,D6		;Start in serving state
	and.w #$F8FF,SR		;Handle interrupts let floodgates open 
	rts

;;----------------------------------------------------------------------
;;
;; Description: this is the main entry point for game after setup
;;              has finnished. Starts and runs the game.
;;
;; 
;;----------------------------------------------------------------------
;; 
run
waitServe_run:	
	cmp.b #$FF,D6 		;Are we in serve state?
	beq waitServe_run
	or #$0700,SR		;we don't want to allow interupts inside here
	jsr moveBall
	jsr out?		;gick bollen ut?
	cmp.b $FF,D1		;out return FF in D1 if ball outside
	bne continue_run        ;ball was not out so new round trip
	jsr score
	jsr newServe
continue_run:	
	and #$F8FF,SR		;Ok receive irq maybe can narrow it down later
	bra waitServe_run 
	rts 			;we might want to add quite button

;;----------------------------------------------------------------------
;;
;; Description: Checks whether ball inside table or not.
;;
;; In: none  
;; out: D1 set to $FF ball went outside else $00
;; 
;;----------------------------------------------------------------------
;; 
out?
	cmp.b #$00,D2
	beq inside_out
	move.b #$FF,D1
	rts
inside_out:
	move.b #$00,D1	
	rts

;;----------------------------------------------------------------------
;;
;; Description: Increases score to the deserving player
;;
;; In: none  
;; out: D3 or D4 is incremented by one 
;; 
;;----------------------------------------------------------------------
;;
score
	cmp $00,D5		;was ball moving i left direction
	beq rightPoint_score
	jsr pointLeft
	rts
rightPoint_score:
	jsr pointRight
	rts

;;----------------------------------------------------------------------
;;
;; Description: Hands point to right hand side player
;;
;; In: none  
;; out: D3 or D4 is incremented by one 
;; 
;;----------------------------------------------------------------------
;; 
pointRight
	add.b #1,d4
	rts
;;----------------------------------------------------------------------
;;
;; Description: Hands point to left hand side player
;;
;; In: none  
;; out: D3 incremented by one
;; 
;;----------------------------------------------------------------------
;; 
pointleft
	add.b #1,d3
	rts
;;----------------------------------------------------------------------
;;
;; Description: Move ball we step in direction of balls current direction
;;              
;;
;; In: D2 Current position of the ball.
;;     D5 Current direction of ball 
;; out: D2 Current positon of ball move on step in its direction
;; 	
;;----------------------------------------------------------------------
;;
moveBall
	cmp #$00,d5
	beq moveLeft_moveBall
	lsl.b #1,d2
	rts
moveLeft_moveBall:
	lsr.b #1,d2
	rts
;;----------------------------------------------------------------------
;;
;; Description: Sets up game for new serve shall only be called when
;;              when ball is outside. Othervise behaivour UNDEFINED. 
;;
;; In: D5 takes current direction of ball to decide who serves next
;; out: D2 the ball(diode) set in serve position.
;; 
;;----------------------------------------------------------------------
;;
;;; lurigt men skulle kanske kunna uttnyttja interuppt för att se vem som skall 
newServe
	;;Om interuppt slog in behöver jag inte använda denna
	;; denna anropas bara om bollen går utanför kanske kan lägga testen
        ;; för om bollen är utanför här returnera felflagga. hmmmm several
	;; responsibilitys
	cmp.b d5,00
	beq right_newServe
	jsr newServeLeft
	rts
right_newServe:	
	jsr newServeRight
	rts
;;----------------------------------------------------------------------
;;
;; Description: Sets ball in serveposition for left player and signals
;;              signals sereve 
;;
;; In: D5 takes current direction of ball to decide who serves next
;; out: D2 the ball(diode) set in serve position.
;;      D6 set serve signal to serve  (FF)
;; 
;;----------------------------------------------------------------------
;;
newServeLeft
	move.b #%10000000,d2
	move.b #$FF,D6
	rts

;;----------------------------------------------------------------------
;;
;; Description: Sets up game for new serve shall only be called when
;;              when ball is outside. Othervise behaivour UNDEFINED. 
;;
;; In: D5 takes current direction of ball to decide who serves next
;; out: D2 the ball(diode) set in serve position.
;; 	D6 set serve signal to serve  (FF)
;;----------------------------------------------------------------------
;;
newServeRight
	move.b #%00000001
	move.b #$FF,D6
	rts




	
;;kolla står bollen i position
;;Om i position är det serve?
;;om serve set inte serve
;;ändra riktning
;;
;; om inte i position
;; dela ut poäng till motståndaren 
rightButton
	;; what policy on reseting interrupt should this be critical (irq7 probably) ?
	;; raise interupt level to  seve
	or.w #$0700,SR
	tst.b 10080			;
	cmp #$1,d2 			;ball in position?
	beq ballInPosition_rightButton 
	jsr scoreLeft
	jsr setupServeLeft
	bra resetIRQLevel
ballInPosition_rightButton:
	jsr setDirectionLeft
	cmp #$FF,d6			;is serve indicator on
	beq serveOn_rightButton
	bra resetIRQLevel
serveOn_rightButton:	
	jsr turnServeOff
resetIRQLevel:
	and.w #$F8FF,SR	
	rte
	;;Testing how constants work
	;; exempel TABS DC.B 'Provstrang' allokera minne storlek byte lägg boksttäverna där
	;; TABS pekar ut addressen nästa rad (DC.B $0D) ligger direct efter dessa?
	;; 		DC.B $0D
		
	;; cmp.l #buffer_start, a0 är addressen i A0 första addressen där konstanterna börjar
	;;buffer _start:
	;; dc.b 0,0,0,0,0,0,0
	;;buffer _end
	
