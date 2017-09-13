***************************************************************************
* Not very elegant bubblesort using m6800 assembler
* table starts at $E0
* D0 sorted
* A1 pointer to table
* d6 tmp1 
* d7 tmp2	
***********************************************************************
*
start
	lea $07000,A7
	move.b #1,d0 
	move.l #$0E0,a1
iter
	move.w (a1),d6 		;FLYTTA IN DE TVA TALEN
	add.l #2,a1
	move.w (a1),d7
	sub.l #2,a1		;ratta till adressen igen
	
	cmp.w d6,d7		
	bgt bytinteplats 	; om d6 större än d7
	move.w d7,(a1)		; byt plats på elementen
	add.l #2,a1
	move.w d6,(a1)
	sub.l  #2,a1
	move.l #0,d0
bytinteplats
	add #2,a1
	cmp.l #$0E8,a1
	bne iter
	cmp.b #1,d0
	bne start
	move #255,d7
	trap #14





























































































































































































