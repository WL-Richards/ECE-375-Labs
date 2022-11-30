;***********************************************************
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;*	 Author: William Richards, Caden Hawkins
;*	   Date: 11/02/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	left_count = r5
.def	right_count = r6

.def	waitcnt = r19			; Wait Loop Counter
.def	ilcnt = r17				; Inner Loop Counter
.def	olcnt = r18				; Outer Loop Counter

.equ	WTime = 100				; Time to reverse for

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00						; Move Backward Command
.equ	TurnR = (1<<EngDirL)				; Turn Right Command
.equ	TurnL = (1<<EngDirR)				; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

; Interrupt 0 (Right Whisker)
.org	$0002
		rcall HandleRightHit
		reti


; Interrupt 1 (Left Whisker)
.org	$0004
		rcall HandleLeftHit
		reti

; Interrupt 3 (Clear)
.org	$0008
		rcall HandleClear
		reti

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi mpr,low(RAMEND)
		out SPL,mpr
		ldi mpr,high(RAMEND)
		out SPH,mpr

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State


		; Initialize The LCD
		rcall LCDInit

		; Clear the screen and reset the registers
		rcall HandleClear

		; Initialize external interrupts

		; Set the Interrupt Sense Control to falling edge

		; Set interrupt 0, 1 and 3 to trigger on a falling edge
		ldi mpr, 0b10001010
		sts EICRA, mpr

		; Configure the External Interrupt Mask
		ldi mpr, 0b00001011
		out EIMSK, mpr

		; Turn on interrupts
		SEI

		; NOTE: This must be the last thing to do in the INIT function

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; HandleLeftWhisker: Called by the left whisker interrupt
; Desc: Acts as the left whisker's ISR
;-----------------------------------------------------------
HandleRightHit:							; Begin a function with a label

		push	mpr					; Save mpr register
		push	waitcnt				; Save wait register
		in		mpr, SREG			; Save program state
		push	mpr	

		; Move Backwards for a second
		ldi		mpr, MovBck			; Load Move Backward command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 2 seconds
		rcall	Wait				; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL			; Load Turn Left Command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 1 second
		rcall	Wait				; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd			; Load Move Forward command
		out		PORTB, mpr			; Send command to port

		inc right_count				; Increment the count by one

		rcall WriteValues			; Write the new count

		; Clear queued interrupts 
		ldi mpr, 0b00000001
		out EIFR, mpr

		pop		mpr					; Restore program state
		out		SREG, mpr
		pop		waitcnt				; Restore wait register
		pop		mpr					; Restore mpr

		ret							; End a function with RET

;-----------------------------------------------------------
; HandleRightWhisker: Called by the right whisker interrupt
; Desc: Acts as the right whisker's ISR
;-----------------------------------------------------------
HandleLeftHit:							; Begin a function with a label
		push	mpr					; Save mpr register
		push	waitcnt				; Save wait register
		in		mpr, SREG			; Save program state
		push	mpr	

		; Move Backwards for a second
		ldi		mpr, MovBck			; Load Move Backward command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 2 seconds
		rcall	Wait				; Call wait function

		; Turn left for a second
		ldi		mpr, TurnR			; Load Turn Left Command
		out		PORTB, mpr			; Send command to port
		ldi		waitcnt, WTime		; Wait for 1 second
		rcall	Wait				; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd			; Load Move Forward command
		out		PORTB, mpr			; Send command to port

		inc left_count				; Increment the count by one
		rcall WriteValues

		; Clear queued interrupts 
		ldi mpr, 0b00000001
		out EIFR, mpr

		pop		mpr					; Restore program state
		out		SREG, mpr
		pop		waitcnt				; Restore wait register
		pop		mpr					; Restore mpr

		ret							; End a function with RET

;-----------------------------------------------------------
; HandleClear: Clears the LCD display when triggered
; Desc: Acts as ISR the clear button
;-----------------------------------------------------------
HandleClear:						; Begin a function with a label

		; Restore variable by popping them from the stack in reverse order
		clr left_count
		clr right_count

		rcall WriteValues			; Rewrite the values to the screen

		ret							; End a function with RET

WriteValues:
		; Line 1 pointer
		ldi XL, low($0100)
		ldi XH, high($0100)
		
		; Fill entire LCD screen with spaces
		ldi mpr, ' '
		FILL_SPACE:
			ST X+, mpr
			cpi XL, 0x20
			brne FILL_SPACE

		; Write an L to line 1
		ldi XL, low($0100)
		ldi XH, high($0100)
		ldi mpr, 'L'
		ST X+, mpr

		; Write and R to line 2
		ldi XL, low($0110)
		ldi XH, high($0110)
		ldi mpr, 'R'
		ST X+, mpr

		; Write the count of L and R to the display
		ldi XL, low($0102)
		ldi XH, high($0102)
		mov mpr, left_count
		rcall Bin2ASCII

		; Write and R to line 2
		ldi XL, low($0112)
		ldi XH, high($0112)
		mov mpr, right_count
		rcall Bin2ASCII

		; Display the initial values
		rcall LCDWrite

		ret						; End a function with RET
	

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"
