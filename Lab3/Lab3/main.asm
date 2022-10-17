;***********************************************************
;*	Lab 3 ECE 375
;*
;*	 Author: Will Richards, Caden Hawkins
;*	   Date: 10/12/2022
;*
;***********************************************************	

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver

.def	waitcnt = r23			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi	mpr, LOW(RAMEND)			; load low byte of RAMEND into r16
		out	SPL, mpr					; store r16 in stack pointer low
		ldi	mpr, HIGH(RAMEND)			; load high byte of RAMEND into r16
		out	SPH, mpr					; store r16 in stack pointer high

		; Initialize LCD Display
		rcall LCDInit;

		; Initialize Port D buttons
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; NOTE that there is no RET or RJMP from INIT,
		; this is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; Read the value of PIND into the MPR
		in mpr, PIND

		; Check if the pin pressed was 4, active LOW, or 0b11101111
		cpi mpr, 0b11101111
		breq ClearDisplay

		; Check if the pin pressed was 5, active LOW, or 0b11011111
		cpi mpr, 0b11011111
		breq PrintNamesOrder1

		; Check if the pin pressed was 6, active LOW, or 0b10111111
		cpi mpr, 0b10111111
		breq PrintNamesOrder2

        ; Check if the pin pressed was 7, active LOW, or 0b01111111
        cpi mpr, 0b01111111
        breq ScrollNames

		rjmp	MAIN			; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Clears the LCD display and turns the Backlight OFF
;-----------------------------------------------------------
ClearDisplay:
		rcall LCDBacklightOff
		rcall LCDClr
		ret

;-----------------------------------------------------------
; Prints the names in the first order
;-----------------------------------------------------------
PrintNamesOrder1:
	; Display the strings on the LCD Display
	rcall LCDBacklightOn
	ldi r17, 0x00			; This will cause the lines to be switched when set to 0xFF
	rcall FirstName
	rcall SecondName
	rcall LCDWrite
	ret

;-----------------------------------------------------------
; Prints the names in the second order
;-----------------------------------------------------------
PrintNamesOrder2:
	; Display the strings on the LCD Display
	rcall LCDBacklightOn
	ldi r17, 0xFF			; This will cause the lines to be switched when set to 0xFF
	rcall FirstName
	rcall SecondName
	rcall LCDWrite
	ret

;-----------------------------------------------------------
; Scroll Names horizontally across LCD display, flipping the lines when they circle around. Do this until the button is released
;-----------------------------------------------------------
ScrollNames:
        ldi ZL, 0x10					; Store the end of the First Line in register Z, one past the limit cause we pre decrement
		ldi ZH, 0x01

        ld r13, -Z						; Load the last char of Z in r13, then decrement

        ldi YL, 0x20					; Store the end of the Second Line in register Y
        ldi YH, 0x01

        ld r24, -Y                      ; Load the last char of Y in r24, then decrement

        ShiftChars:
            ld r15, -Z                  ; Load char Z points to into r15, then decrement
            ld r25, -Y					; Load char Y points to into r25

            adiw ZH:ZL, 1					; Add 1 to Z to move the char one to the right, if the first loop we are not at the last character
            adiw YH:YL, 1					; Add 1 to Y to move the char one to the right

            st Z, r15                   ; Store the char from r15 back into Z. Its now shifted one right
            st Y, r25                   ; Store the char from r25 back into Y. Its now shifted one right

            sbiw ZH:ZL, 1					; Get back to the next character
            sbiw YH:YL, 1					; Get back to the next character

            cpi ZL,  0x00				; If the position of Z has returned to the beginning of the first line (end the loop)
            brne ShiftChars             ; repeat the loop if Z doesn't point to the beginning yet
        
        st Z, r24                       ; Store the saved char from the end of Z (line 1) into the front of Y (line 2)
        st Y, r13                       ; Store the saved char from the end of Y (line 2) into the front of Z (line 1)

        ldi waitcnt, 50                ; Load the wait time of 1 second into the wait count
        rCall Wait                      ; Call wait function to wait for a second
        rCall LCDWrite                  ; Write the adjusted line to the LCD display

	ret                             ; Return to the main

;-----------------------------------------------------------
; Prints the first name out of the program memory when R17 is set to 0xFF it will flip the lines in which the names are wrriten on
;-----------------------------------------------------------
FirstName:	
	; Move strings from Program Memory to Data Memory
	ldi	ZL,LOW(2*FIRST_NAME)			; load 2*MY_NAME
	ldi	ZH,HIGH(2*FIRST_NAME)			; into Z pointer

	cpi r17, 0xFF						; Check if r17 is set to 0xFF if so we want to swap the names
	breq first_name_line2

	; Load the setup for line 1 and then skip to the loop
	ldi	YL, 0x00						; Initialize the low byte of Y to 00
	ldi	YH, 0x01						; Initialize the high byte of Y to 01
	jmp first_loop						; Go to the first loop cycle

	; Move the pointer so we will write to line 2
	first_name_line2:
		ldi	YL, 0x10					; Initialize the low byte of Y to 10
		ldi	YH, 0x01					; Initialize the high byte of Y to 01
		jmp first_loop
	

	first_loop:
		lpm mpr, Z+						; Load program memory into the Z register
		ST Y+, mpr						; Load the mpr into the Y register

		cpi ZL, LOW(2*FIRST_NAME_END)
		brne first_loop
	ret

;-----------------------------------------------------------
; Prints the second name out of the program memory when R17 is set to 0xFF it will flip the lines in which the names are wrriten on
;-----------------------------------------------------------
SecondName:
	; Move strings from Program Memory to Data Memory
	ldi	ZL,LOW(2*SECOND_NAME)			; load 2*MY_NAME
	ldi	ZH,HIGH(2*SECOND_NAME)			; into Z pointer

	cpi r17, 0xFF						; Check if the multi-purpose register is set to 0xFF if so we want to swap the names
	breq second_name_line1

	; Load the setup for line 2 and then skip to the loop
	ldi	YL, 0x10					; Initialize the low byte of Y to 10
	ldi	YH, 0x01					; Initialize the high byte of Y to 01
	jmp second_loop					; Go to the first loop cycle

	; Move the Y pointer so we write to line 1
	second_name_line1:
		ldi	YL, 0x00					; Initialize the low byte of Y to 00
		ldi	YH, 0x01					; Initialize the high byte of Y to 01
		jmp second_loop

	; Loop to go through the program memory until it reaches the end at which point we want to write the data to the LCD display memory
	second_loop:
		lpm mpr, Z+							; Load program memory into the Z register
		ST Y+, mpr							; Load the mpr into the Y register

		cpi ZL, LOW(2*SECOND_NAME_END)		; Check if the lower byte of the Z address is equal to the lower byte of the end of the name
		brne second_loop					; If not keep copying the characters to the LCD memory
	ret

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

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
; Name Variables
FIRST_NAME: .DB		"Will Richards   "
FIRST_NAME_END:
SECOND_NAME: .DB	"Caden Hawkins   "	
SECOND_NAME_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
