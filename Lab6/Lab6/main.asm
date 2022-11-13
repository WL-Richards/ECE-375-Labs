;***********************************************************
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;*	 Author: William Richards, Caden Hawkins
;*	   Date: 11/9/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16							; Multipurpose register
.def	pwm_speed = r17						; Controls the pulse length
.def	speed_level = r18					; Current speed
.def	change_speed = r19					; Register for adjusting the speed
.def	speed_display = r20					; This is what displays on the lower 4 LEDs
.def	zero = r21							; Register for loading high byte of OCR1n registers

.equ	EngEnR = 5							; right Engine Enable Bit
.equ	EngEnL = 6							; left Engine Enable Bit
.equ	EngDirR = 4							; right Engine Direction Bit
.equ	EngDirL = 7							; left Engine Direction Bit
.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; move forward command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

; Interrupt 0 (+ Speed)
.org	$0002
	rcall SPEED_UP
	reti


; Interrupt 1 (- Speed)
.org	$0004
	rcall SPEED_DOWN
	reti

; Interrupt 3 (MAX)
.org	$0008
	rcall SPEED_MAX
	reti

.org	$0056					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	; Initialize the Stack Pointer
	ldi mpr, LOW(RAMEND)
	out SPL, mpr
	ldi mpr, HIGH(RAMEND)
	out SPH, mpr

	; Configure I/O ports
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

; Configure Interrupts ---------------------------------------------------

	; Set interrupt 0, 1 and 3 to trigger on a falling edge
	ldi mpr, 0b10001010
	sts EICRA, mpr

	; Configure the External Interrupt Mask
	ldi mpr, 0b00001011
	out EIMSK, mpr
; ------------------------------------------------------------------------

	; Configure 16-bit Timer/Counter 1A and 1B

	; Enables Fast PWM, and sets compare to inverted logic high
	ldi mpr, 0b11110001
	sts TCCR1A, mpr

	; Enables Fast PWM phase correct 8-bit and Sets the prescalar to 1
	ldi mpr, 0b00001001
	sts TCCR1B, mpr

	; Set TekBot to Move Forward on Port B
	ldi mpr, MovFwd
	out PORTB, mpr

	; Set initial speed, to stopped
	ldi change_speed, 0b00010001
	ldi speed_level, 0b00000000

	; Display the speed_level on lower nibble of PortB while
	; Preserving the upper nibble
	in mpr, PORTB
	or mpr, speed_level
	out PORTB, mpr

	; Set speed and zero registers to zero initially
	clr pwm_speed
	clr zero

	; Enable global interrupts (if any are used)
	sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	; Set TekBot to Move Forward on Port B
	ldi mpr, MovFwd
	or mpr, speed_level
	out PORTB, mpr
	rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	SPEED_UP
; Desc:	Incerase the speed by 1 level
;-----------------------------------------------------------
SPEED_UP:

	; Save program state at interrupt trigger
	push mpr
	in mpr, SREG
	push mpr
	push change_speed

	; Check if we are at the max speed level, if so we don't want to increase it more
	cpi speed_level, 0b00001111
	breq SKIP_ADD

	; Add 17 to the pwm speed to increase overall speed/reduce duty cycle
	; Inc the speed level before changing OCR1n registers to avoid skipping
	add pwm_speed, change_speed
	inc speed_level
	rcall SET_COMPARE

	; Inc the last nibble of PortB to display speed level
	in mpr, PORTB
	andi mpr, 0b11110000
	or mpr, speed_level
	out PORTB, mpr

SKIP_ADD:

	; Clear queued interrupts
	ldi mpr, 0b00000001
	out EIFR, mpr

	; Restore program state
	pop change_speed
	pop mpr
	out SREG, mpr
	pop mpr
	ret						; End a function with RET

;-----------------------------------------------------------
; Func:	SPEED_DOWN
; Desc:	Decrease the speed by 1 level
;-----------------------------------------------------------
SPEED_DOWN:

	; Save program state at interrupt trigger
	push mpr
	in mpr, SREG
	push mpr
	push change_speed

	; Check if we are already at the lowest speed 
	cpi speed_level, 0b00000000
	breq SKIP_SUB

	; Subtract 17 to the speed to increase the pwm speed
	; Dec speed_level before setting OCR1n registers to avoid skipping
	sub pwm_speed, change_speed
	dec speed_level
	rcall SET_COMPARE
	
	; Decrement the last nibble of PortB (Speed_level)
	in mpr, PORTB
	andi mpr, 0b11110000
	eor mpr, speed_level
	out PORTB, mpr

SKIP_SUB:

	; Clear the queued interrupts
	ldi mpr, 0b00000001
	out EIFR, mpr

	; Restore program state 
	pop change_speed
	pop mpr
	out SREG, mpr
	pop mpr
	ret						; End a function with RET

;-----------------------------------------------------------
; Func:	SPEED_MAX
; Desc:	Decrease the speed by 1 level
;-----------------------------------------------------------
SPEED_MAX:

	; Save program state at interrupt trigger
	push mpr
	in mpr, SREG
	push mpr
	push change_speed

	; Set speed_level to maximum(15) and speed to max(2^8)
	ldi speed_level, 0b00001111
	ldi pwm_speed, 0b11111111
	rcall SET_COMPARE
	
	; Set the last nibble of PortB while preserving the upper nibble
	in mpr, PORTB
	andi mpr, 0b11110000
	or mpr, speed_level
	out PORTB, mpr

	; Clear the queued interrupts
	ldi mpr, 0b00000001
	out EIFR, mpr

	; Restore program state 
	pop change_speed
	pop mpr
	out SREG, mpr
	pop mpr
	ret						; End a function with RET

;-----------------------------------------------------------
; Func:	SET_COMPARE
; Desc:	Set the compare value for the OCR1A and OCR1B
;-----------------------------------------------------------
SET_COMPARE:
	; Set the compare value to switch to high for A
	sts OCR1AH, zero
	sts OCR1AL, pwm_speed

	; Set the compare value to switch to high for B
	sts OCR1BH, zero
	sts OCR1BL, pwm_speed
	ret

;***********************************************************
;*	Stored Program Data
;***********************************************************
	; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
	; There are no additional file includes for this program
