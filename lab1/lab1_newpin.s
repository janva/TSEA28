;;----------------------------------------------------------------------
;; Partion of addresspace
;;
;; $1000 	: start (pc at start)
;; $4000-$4003  : store correct lock-code here
;; $4020-	: error message in ascci format
;; $7000	: top of stack at start (sp, a7 is used as stackpointer)
;;----------------------------------------------------------------------
;;
;; Subrutines
;;
;; printchar		: print character to terminal(code given)
;; setuppia		: Init parallellport (code given)
;; printstring		: print string
;; deactivatealarm	: deactivate the alarm
;; activatealarm	: acitvates the alarm
;; getkey		: get character from hex-keyboard
;; addkey		: push key to input-buffer
;; clearinput		: clear input-buffer
;; checkcode		: check if code is correct
;;----------------------------------------------------------------------
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Subroutine tests
;;
;;
START:
	;; jsr SETUPSTACK
	lea $07000,A7	   ;; TODO sätt stackpekaren (A7=sp till 07000)
	jsr TESTPRINTSTRING
	move.b #255,d7 ;;avsluta programmet och dumpa alla register med
	trap #14
	rts
	;;jsr DIE

TESTDEFAULT
	move.l #255,d4
	move.l #$255,d5
	rts
TESTPRINTCHAR 			;verified
	move.b #64,d4 ;;TODO sätt d4 til7l 64
	jsr printchar ;TODO call printchar
	rts
TESTSETUPPIA 			;verifed
	jsr setuppia
	rts

TESTSETUPERRORMESSAGE 		;verified
	jsr setuperrormessage
	move.w #$4020,a4
	move.b #15,d5	
	jsr printstring
	rts
TESTPRINTSTRING 		;verified
	;; lea $C126,a4   ;;todo ändra adress och langd till felmedelandet
	move.w #$4020,a4 		;todo ändra adress och langd till felmedelandet
	;; 	move.l #16,d5
	move.l #15,d5
	jsr printstring
	rts
TESTACTIVATEALARM          ;verified
	jsr setuppia
	jsr activatealarm
	rts
TESTDEACTIVATEALARM 		;verified
	jsr setuppia
	jsr deactivatealarm
	rts
TESTGETKEY 			
	jsr setuppia
	jsr getkey
	rts
TESTADDKEY 			;verified
	jsr clearinput
	jsr addkey
	move.b #1,d4
	jsr addkey
	move.b #2,d4
	jsr addkey
	move.b #3,d4
	jsr addkey
	move.b #4,d4
	jsr addkey
	rts
TESTCLEARINPUT			;verified
	jsr clearinput
	rts
TESTCHECKCODE			;verified
	jsr setuppasscode
	move.l #31323330,$4000	;shoould set d4 to 1
	jsr checkcode
	rts
TESTDELAYACTIVATION
	jsr setuperrormessage
	jsr setuppia
	jsr delayactivation
	rts
;;auxilary subroutines
SETUPSTACK
	lea $07000,A7  ;TODO sätt stackpekaren (A7=sp till 07000)
	rts
DIE
	move.b #255,d7 ;;avsluta programmet och dumpa alla register med
	trap #14
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Inargument: ASCII-kodat tecken i register d4
;; Varning - Denna rutin gör inte att stega sig igenom med TRACE då den
;; använder serieporten på ett sätt som ar inkompatibelt med TRACE.
;; TODO testkör på tutor tutor.edu.liu.se
;;
printchar
	move.w d5,-(a7) 	; spara unda d5 på stacken samt	 räkna ner
				;stackpekaren stacken växer nerefrån och up
waittx
	move.b $10040,d5	;serieportens statusregister sidan 14
				;tutorhäftet dock ofullständig
	and.b  #2,d5		;isolera bit 1 (00000010)(Ready to transmit)
				;sätter z till 1 om resultat är noll
				;(ready indikerasx med 1)
	beq waittx		;Vänta tills serieporten klar at sända
				;branch på zero-flaggan=1
	move.b d4,$10042	;skicka ut ()
	move.w (a7)+,d5		;återställ från stack räkna upp sp d5
	rts			;return from subroutine
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; sätter upp parralleporten pinne 0 på PIAA blir utgång resten är
;; ingångar
;;
setuppia
	move.b #0,$10084 	;Välj datariktningsregister DDRA
	move.b #1,$10080	;Pinne 0 PIAA som utgång
	move.b #4,$10084	;Välj in/utgångsregister
	move.b #1,$10086	;Välj datariktningsregister DDRB
	move.b #1,$10082	;Sätt all pinnar som ingångar
	move.b #4,$10086	;Välj in/utgångsregister
	rts

;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Stores the correct deactivation-code at $4010
;;
;;
setuppasscode
	move.l #31323334,$4010
	rts

;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; in: none
;; out: $4020-... will contain the error message in ascii.
;:	could use move.l instead
;;
setuperrormessage
	move.l #$46656C61,$4020  ;fela
	move.l #$6B746967,$4024  ;ktig
	move.l #$206B6F64,$4028  ;kod!
	move.l #$00210A0D,$402C  ;\LF\CR
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Inargument: Pekare till strängen i a4
;; 	       Längd på strängen i d5
;;
printstring
	move.w d5,-(a7) 	;store on stack
	;;WARNING could subtraction cause problems?
	move.w d4,-(a7) 	;store on stack
next
	;; dbge d5,end
	sub.b #1,d5
	beq last	;if counter becomes zero goto last
	move.b (a4)+,d4 ;; move char pointed to by a4 to d4 call printchar
	jsr printchar 	 ;print out this character
	jmp next
last
	move.b (a4)+,d4 ;; move char pointed to by a4 to d4 call printchar
	jsr printchar	;print last charactar
	move.w (a7)+,d4	;restore register from stack
	move.w (a7)+,d5
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Print out error message located at $4020
;;
;; Inargument: Pekare till strängen i a4
;; 	       Längd på strängen i d5
;;
;;
printerrormessage
	move.w a4,-(a7) 	;store on stack
	move.w d5,-(a7) 	;store on stack
	move.w #$4020,a4	;error message begins at #4020
	move.b #15,d5		;length of message
	jsr printstring
	move.w (a7)+,d5
	move.w (a7)+,a4
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In: inga
;; Ut : inga
;;
;;Funktion: Släcker lysdioden kopplad till PIAA
;;
deactivatealarm
	;; $10084 cra-2 controlls pia-a
	;; or.b #4,$10084	 ;Välj PIAA as peripheral register (at $10080)
 	or.b #0,$10080		;Pinne 0 high (could use move as well)
;;	move.b #0,$10080
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In: inga
;; Ut : inga
;;
;;Funktion: Tänder lysdioden kopplad till PIAA
;;
activatealarm
	or.b #1,$10080	;Pinne 0 high (could use move as well)
;; 	move.b #1,$10080
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In: inga
;; Ut : Tryckt knapp returneras i d4
;;
getkey
;;	move.b d5,-(a7) 	;store on stack	converted to move.w?
;;      move.b #4,$10086
	;; parrallel porten $10082
	;; kanske kan vänta på strobe i huvud programmet
waitforkey: 			;om  strobe satt läs av piab 0-3
	move.b $10082,d5
	and.b #0F,d5 		;är pinne4 hög dvs strobe?
	beq waitforkey
	;; move.b $10082,d4 	;read piab
	move.b d5,d4 	;read piab
	and.l #$0f,d4 	;clean up msb:s just in case
keyreleased?
	move.b $10082,d5	;nödvändig ?
	and.b #0F,d5		;is strobe high
	bne keyreleased?
	;; move.b (a7)+,d5		
	rts			
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In: inga
;; Ut : Tryckt knapp returneras i d4
;;
;waitforkey: 			;om  strobe satt läs av piab 0-3
;	move.b $10082,d5
;	and.b #8,d5 		;är pinne4 hög dvs strobe?
;	beq waitforkey
;	rts
	
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In: choosen buttom shall be in d4
;; out: 
;;
;; Funktion: Flyttar innehållet på $40001-$40003 bakåt en byte till
;;	     $4000-$40002. Lagrar sedan innehållet i d4 på 40003 requirement use lsl
addkey
	move.l d5,-(a7) 	;store on stack	
	move.l $4000,d5
	lsl.l #8,d5
	move.b d4,d5 		;concatinate new key to d5
	move.l d5,$4000
	move.l (a7)+,d5
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; In: inga
;; Ut: inga
;;
;; Funktioon: Sätter innehållet på $4000-$4003 till $FF
clearinput
	move.l #$FFFFFFFF,$4000
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;In: Inga
;;Ut: returnera 1 i d4 om koden är korrekt, annars 0 i d4
;;
;;Funktion är kod i $4000 korrekt, krav får bara läsa i
;; $4000–$4003 respektive $4010–$4013 i denna subrutin
;;
checkcode
	;;move.l #100,$4000
	;;move.l #100,$4010
	move.l d5,-(a7) 	;store on stack
	move.l $4010,d5
	cmp.l  $4000,d5
	beq correct
	move.b #0,d4
	bra resetregister
correct
	move.b #1,d4
resetregister:	
	move.l (a7)+,d5
	rts
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Change code 
;;  TÄNK OM HELA DENNA SUBRITIN BLIR FÖR kRÅNGLIGT
;; 
;;
;;
changecode
changecode_reset:
	move.l #FFFFFFFF,d6
	move.l #FFFFFFFF,d5
changecode_readkey:
	jsr getkey
	cmp #$0A,d4
	beq changecode_return
	cmp #$0C,d4
	beq changecode_sametwice?
	lsl.l #4,f6
	or.b d4,d6
	bra changecode_readkey
changecode_sametwice?:
	move.w d6,d5
	swap.l d6
	cmp.w d6,d5
	bne changecode_reset 	;skall vi i så fall låsa? inte som jag ser det
	or.b #15, d5 
	move.b d5, $4000
	lsl.l #8,$4000
	lsr.b #4,d6
	move.b d6,d5
	
changecode_return:
	jsr activatealarm 	;larm aktiveras alltid när vi går ur?
	rts
	
;; 
;;;;;;;;;;;;;;;;;;;;;;
;;
;; Intended to be used to delay reactivation of alarm
;; probes keypad and resets delay as long as A is not pressed
;; 
;;
;delayactivation
;	move.w d5,-(a7)		;
;	move.w d4,-(a7)		;
;resetcounter:	
;	move.l #$000003,d5
;waity:
;	jsr getkey ; hmmm destroys content in d4 do need to consider this (stor on stack?)
;
;	cmp.b #$41,d4 		;did we push 'A'
;	beq stop
;	sub.l #1,d5 		;decrement counter
;	beq stop
;	bra waity
;stop:
;	move.w (a7)+,d4
;	move.w (a7)+,d5
;	rts 
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This is the main loop of codelock
;;
MAIN
	jsr setuppia
	jsr setuppasscode
	jsr setuperrormessage
reset:
	jsr clearinput
getannotherkey:
	;; jsr waitforkey		;wait for user to push key
	jsr getkey		;get that key 
	cmp.b #$46,d4		;is read key 'F'
	beq main_correct?
	cmp #$41,d4		;is read key 'A'
	beq activate
	jsr addkey		;addkey to buffer
	jmp getannotherkey 	;jmp less optimal then bra?
main_correct?:
	jsr checkcode	     	;sets d4 to 1 if correct
	cmp.b #1,d4		;was the given code correct?
	beq deactivate
	jsr printerrormessage
	jmp reset
deactivate:
	jsr deactivatealarm
	;;TODO implement delay
	jsr delayactivation
	;; modified for delay reactivation of alarm
	 jmp reset
activate:
	jsr activatealarm
	jmp reset
