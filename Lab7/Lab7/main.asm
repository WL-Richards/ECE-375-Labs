
;***********************************************************
;*
;*	This is the TRANSMIT skeleton file for Lab 7 of ECE 375
;*
;*  	Rock Paper Scissors
;* 	Requirement:
;* 	1. USART1 communication
;* 	2. Timer/counter1 Normal mode to create a 1.5-sec delay
;***********************************************************
;*
;*	 Author: William Richards, Caden Hawkins
;*	   Date: 11/16/2022
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register
.def	loop_count = r17		; Timer counter loops
.def	transmit_byte = r18		; Byte that will be transmitted
.def	recv_byte = r19			; Byte that will be received by the device
.def	game_state = r23		; State of the current game

; Game State is held on both devices and different numbers are equivelent to different states
; 0x00 - Waiting for user to start
; 0x01 - Waiting for opponenet
; 0x02 - Game Start

.def	item_selection = r24	; What item we select to use

; Use this signal code between two boards for their game ready
.equ    SendReady = 0xFF

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000						; Beginning of IVs
	    rjmp    INIT            	; Reset interrupt

; Triggered whenever data is received on UART
.org	$0032
		rcall RECEIVE
		reti

; Triggered when the data register is empty
; We may not want to transmit every time
;.org	$0034
;		rcall TRANSMIT
;		reti

.org    $0056						; End of Interrupt Vectors

;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
	;Stack Pointer
	ldi mpr, LOW(RAMEND)
	out SPL, mpr
	ldi mpr, HIGH(RAMEND)
	out SPH, mpr

	;I/O Ports

	; Enable Port B (Buttons)
	ldi		mpr, $FF		; Set Port B Data Direction Register
	out		DDRB, mpr		; for output
	ldi		mpr, $00		; Initialize Port B Data Register
	out		PORTB, mpr		; so all Port B outputs are low

	; Enable Port D (LEDS)
	ldi		mpr, $00		; Set Port D Data Direction Register
	out		DDRD, mpr		; for input
	ldi		mpr, $FF		; Initialize Port D Data Register
	out		PORTD, mpr		; so all Port D inputs are Tri-State

	;USART1
		;Set baudrate at 2400bps (207 UBRR)
		ldi mpr, 0x00
		sts UBRR1H, mpr
		ldi mpr, 0xCF
		sts UBRR1L, mpr

		;Enable receiver and transmitter
		ldi mpr, (1<<RXEN1)|(1<<TXEN1)
		sts UCSR1B, mpr

		;Set frame format: 8 data bits, 2 stop bits
		ldi mpr, (1<<USBS1)|(3<<UCSZ10)
		sts UCSR1C, mpr

	;TIMER/COUNTER1

		;Set Normal mode
		ldi mpr, 0b00000000
		sts TCCR1A, mpr

		; Prescale of 1024
		ldi mpr, 0b00000101
		sts TCCR1B, mpr
		

	; Initialize LCD Display
	rcall LCDInit
	rcall LCDClr

	; Print the welcome message to the screen
	rcall LOAD_WELCOME_MSG

	; Write the welcome message to the LCD 
	rcall LCDWrite

	; Clear registers that need to have a known initial stat
	clr loop_count
	clr item_selection ; Start at zero but the numbers actually start at one so the first time we call it prints rock

	; Globally enable interrupts
	sei


;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
	cpi game_state, 0x02
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;*	Transmit the data that is currently in the transmit_byte
;***********************************************************
TRANSMIT:
	; Read all data from UDR1
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp TRANSMIT

	; Send byte
	sts UDR1, transmit_byte
	ret

;***********************************************************
;*	Read whatever data is waiting into the recv_byte
;***********************************************************
RECEIVE:
	lds recv_byte, UDR1
	ret


;***********************************************************
;*	Wait for One and a Half seconds before returning
;***********************************************************
WAIT_ONE_HALF_SECOND:
	push mpr
	in mpr, SREG
	push mpr

	; Set number of loops to 3
	ldi loop_count, 3

	WAIT_HALF_SECOND:
		; Offset from max to get the right delay
		ldi mpr, 0x85
		sts TCNT1H, mpr
		ldi mpr, 0xED
		sts TCNT1L, mpr

		; Check if we are done counting yet
		WAIT_LOOP:
			in mpr, TIFR1
			ANDI mpr, 0b00000001
			brne WAIT_LOOP
	
		; Clear Flag
		ldi mpr, 0b00000001
		out TIFR1, mpr

		dec loop_count

	; Check if we need to break out of the loop
	cpi loop_count, 0x00
	brne WAIT_HALF_SECOND

	pop mpr
	out SREG, mpr
	pop mpr
	ret


;***********************************************************
;*	Switch between each of the possible items we can use
;***********************************************************
CYLCE_SELCTION:
	; Increment item_selection by one
	inc item_selection

	cpi item_selection, 0x01
	breq ROCK

	cpi item_selection, 0x02
	breq PAPER

	cpi item_selection, 0x03
	breq SCISSORS

	ROCK:
		rcall LOAD_ROCK_MSG
		rcall LCDWrLn2
		ret

	PAPER:
		rcall LOAD_PAPER_MSG
		rcall LCDWrLn2
		ret

	SCISSORS:
		rcall LOAD_SCISSORS_MSG
		rcall LCDWrLn2
		ldi item_secltion, 0x00
		ret
;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
.include "StringManager.asm"	; Seperate file to handle all of the strings that need to be printed
