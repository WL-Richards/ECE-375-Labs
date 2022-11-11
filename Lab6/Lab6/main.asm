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
.def	mpr = r16				; Multipurpose register
.def	pwm_speed = r17			; Controls the pulse length
.def	speed_level = r18		; Current speed

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit

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

		; Enables Fast PWM and Sets the prescalar to 1
		ldi mpr, 0b00001001
		sts TCCR1B, mpr

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B
		ldi mpr, (1<<EngDirR|1<<EngDirL)
		out PORTB, mpr

		; Set initial speed, to stopped
		clr speed_level


		; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B
		ldi mpr, (1<<EngDirR|1<<EngDirL)
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

		; Check if we are at the max speed level, if so we don't want to increase it more
		cpi speed_level, 0x0F
		breq SKIP_ADD
		ldi pwm_speed, 0xFF

		; Add 17 to the speed to increase the pwm speed
		ldi mpr, 0x11
		add pwm_speed, mpr
		rcall SET_COMPARE
		SKIP_ADD:

		ldi mpr, 0b00000001
		out EIFR, mpr

		; Restore program state 
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

		; Check if we are already at the lowest speed 
		cpi speed_level, 0x00
		breq SKIP_SUB
		ldi pwm_speed, 0x00

		; Subtract 17 to the speed to increase the pwm speed
		ldi mpr, 0x11
		sub pwm_speed, mpr

		rcall SET_COMPARE
		SKIP_SUB:

		ldi mpr, 0b00000001
		out EIFR, mpr

		; Restore program state 
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

		; Set max speed
		ldi speed_level, 0x0F
		ldi pwm_speed, 0xFF
		rcall SET_COMPARE

		ldi mpr, 0b00000001
		out EIFR, mpr

		; Restore program state 
		pop mpr
		out SREG, mpr
		pop mpr
		ret						; End a function with RET

SET_COMPARE:
		; Set the compare value to switch to high for A
		sts OCR1AL, pwm_speed

		; Set the compare value to switch to high for B
		sts OCR1BL, pwm_speed

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program