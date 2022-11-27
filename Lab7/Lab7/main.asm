
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

; Use this signal code between two boards for their game ready
.equ    SendReady = 0b11111111

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
.org	$0034
		rcall TRANSMIT
		reti

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

	; Print the welcome message to the screen
	rcall LOAD_WELCOME_MSG

	;Other
	clr loop_count

	; Globally enable interrupts
	sei


;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

TRANSMIT:
	; Read all data from UDR1
	lds mpr, UCSR1A
	sbrs mpr, UDRE1
	rjmp TRANSMIT

	; Send byte
	sts UDR1, transmit_byte
	ret

RECEIVE:
	lds recv_byte, UDR1
	ret

; This should load the Welcome Message from Program memory into the LCD display area
LOAD_WELCOME_MSG:

	; Clear LCD to start
	rcall LCDClr

	ldi XL, 0x00
	ldi XH, 0x01

	ldi ZL, low(STRING_WELCOME_START<<1)
	ldi ZH, high(STRING_WELCOME_START<<1)

	; Loop to load in all the data
	WELCOME_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_WELCOME_END<<1)
		brne WELCOME_MSG_LOOP

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
	cpi loop_count, 0
	brne WAIT_HALF_SECOND

	pop mpr
	out SREG, mpr
	pop mpr
	ret

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------

; Welcome Message
STRING_WELCOME_START:
    .DB		"Welcome!        Please press PD7"		
STRING_WELCOME_END:

; Rock
STRING_ROCK_START:
    .DB		"Rock            "
STRING_ROCK_END:

; Paper
STRING_PAPER_START:
    .DB		"Paper           "
STRING_PAPER_END:

; Scissors
STRING_SCISSORS_START:
    .DB		"Scissors        "		
STRING_SCISSORS_END:

; Waiting For Opponent 
STRING_OPPONENT_START:
    .DB		"READY, Waiting  for the opponent"		
STRING_OPPONENT_END:

; Game Start
STRING_GAME_START:
    .DB		"GAME START      "
STRING_GAME_END:

; You Won!
STRING_WON_START:
    .DB		"You Won!        "
STRING_WON_END:

; You Lost!
STRING_LOST_START:
    .DB		"You Lost.       "
STRING_LOST_END:

; Draw
STRING_DRAW_START:
    .DB		"Draw            "
STRING_DRAW_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
