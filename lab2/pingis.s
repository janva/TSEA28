
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
;; D3: Resultatregister spelare A.(h�ger)
;; D4: Resultatregister spelare B.(v�nster)
;; D5: Flyttningsriktning: 00=vänster, FF=höger.
;; D6: Servstatus: 00=ej serve, FF=serve.	
;;
;;-----------------------------------------------------------------------
;;
start
	lea $7000,A7		;set stackpointer
;;; 	jsr $C300		;special inte subrutin?
	jsr $20EC	    	;PINIT
	;;jsr setupAndRunTest 

	jsr setupInterrupts   	;maps interuppts to there handler subroutines
	jsr initNewGame
	jsr run
	move.b #255,d7
	trap #14
	rts

setupInterrupts
	move.l #leftButton,$068 	;irq-level2 handler @$1100
	move.l #rightButton,$074 ;irq-level2 handler @$1200
	tst.b $10080		;nollställ interupt ca1
	tst.b $10082		;nollställ interupt cb1
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
;;	or.w #$0700,SR		;Don't handle irq:s during init
	move.l #1000,D0		;Time each diode will be lit
	move.l #$80,D2		;Start ball in left  position
	move.b d2,$10080
	move.b #$00,D3		;Player A score 0
	move.b #$00,D4		;Player B score 0
	move.b #$FF,D5		;Starting from left 
	move.b #$FF,D6		;Start in serving state
	tst.b $10080		;clear to receive interupts aknowledge
	tst.b $10082
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
	move.b d2,$10080 	;varf�r g�r det inte t�nda i newserve?
	cmp.b #$FF,D6 		;Are we in serve state?
	beq waitServe_run
	or.w #$0700,SR	 ;;we don't want to allow interupts inside here
	jsr moveBall
	jsr isOut			;;gick bollen ut?
	cmp.b #$FF,D1		;out return FF in D1 if ball outside
	bne shootBall_run       ;ball was not out so new round trip
	jsr score
	jsr newServe		
	and #$F8FF,SR		;not so pretty quickfix
	bra waitServe_run
shootBall_run:	
	and #$F8FF,SR		;Ok receive irq maybe can narrow it down later
	jsr $2000
	move.l #1000,D0
	bra waitServe_run 
	rts 			;we might want to add quite button
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
	cmp.b #$00,d5		;is ball currently moving left
	beq moveLeft_moveBall
	lsr.b #1,d2
	bra writeToPIA_moveBall	;kommer hit raaaaser igenom andra bollarna
moveLeft_moveBall:
	lsl.b #1,d2
writeToPIA_moveBall:
	move.b d2,$10080 	;write ball position to display
	rts

;;----------------------------------------------------------------------
;;
;; Description: Checks whether ball inside table or not.
;;
;; In: none  
;; out: D1 set to $FF ball went outside else $00
;; 
;;----------------------------------------------------------------------
;; 
isOut
	cmp.b #$00,D2  		;ball is out?
	beq is_out		;if out 
	move.b #$00,D1
	rts
is_out:
	move.b #$FF,D1	
	rts
;;----------------------------------------------------------------------
;;
;; Description: Increases score to the deserving player based on
;; 		current direction
;;
;; In: none  
;; out: D3 or D4 is incremented by one 
;; 
;;----------------------------------------------------------------------
;;
score
	cmp.b $00,D5		;was ball moving i left direction
	bne rightPoint_score
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
	add.b #1,d3
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
pointLeft
	add.b #1,d4
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
	cmp.b #$00,d5
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
;;      D5 should be move in right  (FF)
;; 
;;----------------------------------------------------------------------
;;
newServeLeft
	move.b #%10000000,d2
	move.b #$FF,D6
	move.b #$FF,D5
	;; move.b d2,$10080
	rts
;;----------------------------------------------------------------------
;;
;; Description: Sets up game for new serve shall only be called when
;;              when ball is outside. Othervise behaivour UNDEFINED. 
;;
;; In: D5 takes current direction of ball to decide who serves next
;; out: D2 the ball(diode) set in serve position.
;; 	D6 set serve signal to serve  (FF)
;; 	D5 move in right direction
;;----------------------------------------------------------------------
;;
newServeRight
	move.b #%00000001,d2
	move.b #$00,D5
	move.b #$FF,D6
	;; move.b d2,$10080
	rts
	
;;----------------------------------------------------------------------
;;
;; Description: Interrupt-handler subroutin for the right hand side
;;  		button. Will check whether we hit the ball or not.
;;		If we did hit it ball will be returned in opposite
;;		direction othervise point is given to the oponent
;;		as well as the benefit of serving next. 
;;
;;
;; In: D2 to check if ball is in hitting position.
;;     D6 to check if we are in serve position or not
;; 
;; out: D5 to set new direction of ball.  
;; 
;;----------------------------------------------------------------------
;;
rightButton
	tst.b $10080			;eventuellt fel
	or.w #$0700,SR			;raise interrupt level 7
	cmp.b #%00000001,d2 		;ball in position?
	beq ballInPosition_rightButton	;if ball was in hitting pos
	jsr pointLeft			; point to left player
	jsr newServeLeft		; also set serve flag
	bra resetIRQLevel_rigthButton
ballInPosition_rightButton:
	move.b #$00,D5			;change balls direction (to  move left)
	cmp.b #$FF,d6                    ;is serve indicator on
	beq serveOn_rightButton		;if serve is on then turn it off
	bra resetIRQLevel_rigthButton	;maybe overkill could just turn it on
serveOn_rightButton:	
	jsr turnServeOff
resetIRQLevel_rigthButton:
	and.w #$F8FF,SR	
	rte

	
;;----------------------------------------------------------------------
;;
;; Description: Interrupt-handler subroutin for the lef hand side
;;  		button. Will check whether we hit the ball or not.
;;		If we did hit it ball will be returned in opposite
;;		direction othervise point is given to the oponent
;;		as well as the benefit of serving next. 
;;
;;
;;
;; In: D2 to check if ball is in hitting position.
;;     D6 to check if we are in serve position or not
;; 
;; out: D5 to set new direction of ball.  
;; 
;;----------------------------------------------------------------------
;;
leftButton
	;;OBS OBS OBS OBS kan ha betydelse ordning
	tst.b $10082 			; aknowkledge interrupt received
	or.w #$0700,SR			; raise interrupt level 7
	cmp.b #%10000000,d2 		; ball in position?
	beq ballInPosition_leftButton	; if ball was in hitting pos
	jsr pointRight			; point to left player
	jsr newServeRight		; also set serve flag
	bra resetIRQLevel_leftButton
ballInPosition_leftButton
	move.b #$FF,D5			;change balls direction (to  move left)
	cmp.b #$FF,d6			;is serve indicator on
	beq serveOn_leftButton		;if serve is on then turn it off
	bra resetIRQLevel_leftButton
serveOn_leftButton:	
	jsr turnServeOff
resetIRQLevel_leftButton:
	and.w #$F8FF,SR	
	rte
;;--------------------------------------------------------------------------------
;; 
;; Description: set serve status off
;; 
;;--------------------------------------------------------------------------------
;; 
turnServeOff
	move.b #$00,D6
	rts

	;;Testing how constants work
	;; exempel TABS DC.B 'Provstrang' allokera minne storlek byte lägg boksttäverna där
	;; TABS pekar ut addressen nästa rad (DC.B $0D) ligger direct efter dessa?
	;; 		DC.B $0D
		
	;; cmp.l #buffer_start, a0 är addressen i A0 första addressen där konstanterna börjar
	;;buffer _start:
	;; dc.b 0,0,0,0,0,0,0
	;;buffer _end
;;--------------------------------------------------------------------------------
;; 
;; Testsection
;; remember to load $C300
;; individual test will set bitpattern i d1 1 succes 0 fail
setupAndRunTest
	lea $7000,A7
	jsr $20EC 		;pinit
	move.l #$00,d1
	;jsr setupInterupts_test
	;; jsr initNewGame_test
	;;jsr moveBall_test
	;;jsr isOut_test
	;;jsr score_test
	;;jsr pointRight_test	
	;;jsr pointLeft_test
	;; jsr newServe_test
	;;jsr newServeRight_test
	;;jsr newServeLeft_test
	;;jsr rightButton_test
	jsr leftButton_test
	move.b #255,d7
	trap #14
	rts

;; figure out a way to maybe make stubs for the interrupt handlers
;; excpected behaviour
;; 1) Link interuppthandlers 
;; 2) reset aknowledge kan läsas
;; 3) set irq level to 7 
;; 
setupInterupts_test
	jsr setupInterrupts
	;; cmp #rightButton,($074)
	;; fråga finns det något sätt att typ hitta addressen till
	;; en label och använda den för att skriva in en kodsnutt
	;; på den addressen
	move.w SR,D0
	and.w #$0700,D0 		;isolera
	rts
initNewGame_test	
	jsr initNewGame
	cmp.w #2000,D0
	bne fail_initNewgame_test
	or.l #$F0000000,d1
	cmp.b #%10000000,D2
	bne fail_initNewgame_test
	or.l #$0F000000,d1
	cmp.b #0,D3
	bne fail_initNewgame_test
	or.l #$00F00000,d1
	cmp.b #$00,D4
	bne fail_initNewgame_test
	or.l #$000F0000,d1
	cmp.b #$FF,D5
	bne fail_initNewgame_test
	or.l #$0000F000,d1
	cmp.b #$FF,D6
	bne fail_initNewgame_test
	or.l #$00000FFF,d1
	rts
fail_initNewgame_test:
	move.b #$00,d1
	rts
	
run_test
	jsr run
	rts

moveBall_test
	;;left
	move #$00,d5
	move.b #%00000001,d2
	jsr moveBall
	cmp.b  #%00000010,d2
	bne fail_moveBall_test
	or.l #$F0000000,d1	

	move.b #%10000000,d2
	jsr moveBall
	cmp.b  #%00000000,d2
	bne fail_moveBall_test
	or.l #$0F000000,d1	

	move.b #%00100000,d2
	jsr moveBall
	cmp.b  #%01000000,d2
	bne fail_moveBall_test
	or.l #$00F00000,d1

	;;right
	move #$FF,d5
	move.b #%00000001,d2
	jsr moveBall
	cmp.b  #%00000000,d2
	bne fail_moveBall_test
	or.l #$000F0000,d1	

	move.b #%10000000,d2
	jsr moveBall
	cmp.b  #%01000000,d2
	bne fail_moveBall_test
	or.l #$0000F000,d1	

	move.b #%00100000,d2
	jsr moveBall
	cmp.b  #%00010000,d2
	bne fail_moveBall_test
	or.l #$00000FFF,d1
	rts
fail_moveBall_test:
	jsr failTest
	rts
	
isOut_test
	move.b #%00000001,d2
	jsr isOut
	cmp.b  #$00,d1 		;simulate not outside
	bne fail_out?_test
	or.l #$F0000000,d1

	move.b #%00000000,d2
	jsr isOut
	cmp.b  #$FF,d1
	bne fail_out?_test
	or.l #$FFFFFFFF,d1
	rts
fail_out?_test:
	jsr failTest
	rts
	
score_test
	;;right player shall get point	
	move.b #$00,d4
	move.b #$00,d5
	jsr score
	cmp.b #1,d4
	bne fail_score_test
	or.l #$FFFF0000,d1
	
	;;left player shall get point	
	move.b #$00,d3
	move.b #$FF,d5
	jsr score
	cmp.b #$1,d3
	bne fail_score_test
	or.l #$FFFFFFFF,d1
	rts
fail_score_test
	jsr failTest
	rts

pointRight_test
	move.b #$00,d4
	jsr pointRight
	cmp.b #$01,d4
	bne fail_pointRight_test
	or.l #$FFFFFFFF,d1
	rts
fail_pointRight_test:
	jsr failTest
	rts
	
pointLeft_test
	move.b #$00,d3
	jsr pointLeft
	cmp.b #$01,d3
	bne fail_pointLeft_test
	or.l #$FFFFFFFF,d1
	rts
fail_pointLeft_test:
	jsr failTest
	rts

;;; todo implement
newServe_test
	jsr newServe
	rts
fail_newServe_test
	
newServeLeft_test
	move.b #%00100000,d2	
	move.b #$00,D6
	move.b #$00,D5
	jsr newServeLeft
	cmp.b #%10000000,D2
	bne fail_newServeLeft_test
	or.l #$FFFF0000,d1
	cmp.b #$FF,d6
	bne fail_newServeLeft_test
	or.l #$000FFF00,d1
	cmp.b #$FF,d5
	bne fail_newServeLeft_test
	or.l #$000000FF,d1
	rts
fail_newServeLeft_test:	
	jsr failTest
	rts
	
newServeRight_test
	move.b #%01000000,d2	
	move.b #$00,D6
	move.b #$FF,D5
	jsr newServeRight
	cmp.b #%00000001,D2
	bne fail_newServeRight_test
	or.l #$FFF00000,d1
	cmp.b #$FF,d6
	bne fail_newServeRight_test
	or.l #$000FFF00,d1
	cmp.b #$00,d5
	bne fail_newServeRight_test
	or.l #$000000FF,d1	
	rts
fail_newServeRight_test:	
	jsr failTest
	rts
	
turnServeOff_test
	move #$FF,D6
	jsr turnServeOff
	cmp.b #$00,D6
	bne fail_turnServeOff_test
	or.l #$FFFFFFFF,D1
	rts
fail_turnServeOff_test
	jsr failTest
	rts

;;----------------------------------------------------------------------
;; 
;; Test flaggs point, direction and servesstatus
;; note for now this require rte to be changed temporarily to rts
;; 
;;----------------------------------------------------------------------
;; 
leftButton_test
	jsr leftButton
	;;set testresult register to 0 
	move.l #$00,d0
	move.l #$00,d1
	;;i position
	jsr setBallInPositionLeft
	jsr leftButton
	cmp.b #$00,d4
	bne fail_left_button_test
	or.l #$F0000000,D1
	
	cmp.b #$FF,d5
	bne fail_left_button_test
	or.l #$0F000000,D1

	cmp.b #$00,d6
	bne fail_left_button_test
	or.l #$00F00000,D1
	;; samma test men står i servläge
	jsr setBallInPositionLeft
	move #$FF,D6
	jsr leftButton
	cmp.b #$00,d4	
	bne fail_left_button_test
	or.l #$000F0000,D1
	
	cmp.b #$FF,d5
	bne fail_left_button_test
	or.l #$0000F000,D1

	cmp.b #$00,d6
	bne fail_left_button_test
	or.l #$00000FFF,D1
	;;if ball is not in position
	jsr setBallNotInPositionLeft
	jsr leftButton
	jsr leftButtonNotInPosLeft_test
	;;ball is moving in oppisitons direction we take a swing
	jsr setBallNotInPositionLeft
	move.b #$FF,d5
	jsr leftButton
	jsr leftButtonTakeSwing_test
	rts
fail_left_button_test:
	jsr failTest
	rts

leftButtonNotInPosLeft_test
	cmp.b #$01,d4
	bne fail_left_button_test_test
	or.l #$F0000000,D0
	cmp.b #$00,d5
	bne fail_left_button_test_test
	or.l #$0F000000,D0
	cmp.b #$FF,d6
	bne fail_left_button_test_test
	or.l #$00F00000,D0
	rts
fail_left_button_test_test:
	move.b #$00,D0
	rts
	
leftButtonTakeSwing_test
	cmp.b #$01,d4
	bne fail_leftButtonTakeSwing_test
	or.l #$000F0000,D0
	cmp.b #$00,d5
	bne fail_leftButtonTakeSwing_test 
	or.l #$0000F000,D0
	cmp.b #$FF,d6
	bne fail_leftButtonTakeSwing_test 
	or.l #$00000FFF,D0
	rts
fail_leftButtonTakeSwing_test:	
	move.b #$00,D0
	rts

;;----------------------------------------------------------------------
rightButton_test
	;;set testresult register to 0 
	move.l #$00,d0
	move.l #$00,d1
	;;i position
	jsr setBallInPositionRight
	jsr rightButton
	cmp.b #$00,d3
	bne fail_rightButton_test
	or.l #$F0000000,D1
	
	cmp.b #$00,d5
	bne fail_rightButton_test
	or.l #$0F000000,D1

	cmp.b #$00,d6
	bne fail_rightButton_test
	or.l #$00F00000,D1
	;; samma test men står i servläge
	jsr setBallInPositionRight
	move #$FF,D6
	jsr rightButton
	cmp.b #$00,d3	
	bne fail_rightButton_test
	or.l #$000F0000,D1
	
	cmp.b #$00,d5
	bne fail_rightButton_test
	or.l #$0000F000,D1

	cmp.b #$00,d6
	bne fail_rightButton_test
	or.l #$00000FFF,D1
	;;if ball is not in position
	jsr setBallNotInPositionRight
	jsr rightButton
	jsr rightButtonNotInPosRight_test
	rts
fail_rightButton_test:
	jsr failTest
	rts

rightButtonNotInPosRight_test
	cmp.b #$01,d3
	bne fail_rightButton_test_test
	or.l #$F0000000,D0
	cmp.b #$FF,d5
	bne fail_rightButton_test_test
	or.l #$0F000000,D0
	cmp.b #$FF,d6
	bne fail_rightButton_test_test
	or.l #$00FFFFFF,D0
	rts
fail_rightButton_test_test:
	move.b #$00,D0
	rts
	
;;----------------------------------------------------------------------
;; helper functions for testing
;;----------------------------------------------------------------------
;;
setBallInPositionRight
	move.b #%00000001,d2
	move.b #$00,d3
	move.b #$FF,d5
	move.b #$00,d6
	rts
setBallNotInPositionRight
	move.b #%00100000,d2
	move.b #$00,d3
	move.b #$00,d5
	move.b #$00,d6
	rts
setBallInPositionLeft
	move.b #%10000000,d2
	move.b #$00,d4
	move.b #$00,d5
	move.b #$FF,d6
	rts

setBallNotInPositionLeft
	move.b #%00010000,d2
	move.b #$00,d4
	move.b #$00,d5
	move.b #$00,d6
	rts
failTest
	move.b #$00,d1
	rts
	

	
