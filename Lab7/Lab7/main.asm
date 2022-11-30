
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
.def	user_ready = r13		; Reg indicate user ready (1 - ready, 0 - not)
.def	opp_ready = r14			; Reg indicated opp ready (1 - ready, 0 - not)
.def	opp_move = r15			; Store opponent move
.def	game_state = r12		; State of the current game

; Game State --------------------------------------------------
; Held on both devices and different numbers are equivelent 
; to different states

; 0x00 - Welcome message
; 0x01 - Waiting for opponent
; 0x02 - Game Start
; 0x03 - End Game
; -------------------------------------------------------------

.def	item_selection = r24	; What item we select to use

; Item Selection ----------------------------------------------
; Equivalent values for each move

; 0x01 - Rock
; 0x02 - Paper
; 0x03 - Scissors
; -------------------------------------------------------------

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

		; Interrupt 0 (PD7 send ready signal to opponent)
.org	$0002
		rcall SEND_READY
		reti

; Interrupt 1 (PD4 select move to send to opponent)
.org	$0004
		rcall CYCLE_SELCTION
		reti

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

; Stack Pointer ---------------------------------------------
	ldi mpr, LOW(RAMEND)
	out SPL, mpr
	ldi mpr, HIGH(RAMEND)
	out SPH, mpr
; -----------------------------------------------------------

; I/O Ports -------------------------------------------------

	; Enable Port B (LEDS)
	ldi		mpr, $FF		; Set Port B Data Direction Register
	out		DDRB, mpr		; for output
	ldi		mpr, $00		; Initialize Port B Data Register
	out		PORTB, mpr		; so all Port B outputs are low

	; Enable Port D (Buttons)
	ldi		mpr, $00		; Set Port D Data Direction Register
	out		DDRD, mpr		; for input
	ldi		mpr, $FF		; Initialize Port D Data Register
	out		PORTD, mpr		; so all Port D inputs are Tri-State
; -------------------------------------------------------------

; Configure Interrupts ----------------------------------------
	
	; Only enable interrupt 0 at first so interrupt 1 can't 
	; be used until users are both ready

	; Set interrupt 0 and 1 to trigger on a falling edge
	ldi mpr, 0b00001010
	sts EICRA, mpr

	; Configure the External Interrupt Mask
	ldi mpr, 0b00000001
	out EIMSK, mpr
; -------------------------------------------------------------

; USART1 ------------------------------------------------------
	
	;Set baudrate at 2400bps (207 UBRR)
	ldi mpr, high(416)
	sts UBRR1H, mpr
	ldi mpr, low(416)
	sts UBRR1L, mpr

	;Set frame format: 8 data bits, 2 stop bits
	ldi mpr, (1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
	sts UCSR1C, mpr

	;Enable receiver and transmitter
	ldi mpr, (1<<TXEN1 | 1<<RXEN1 | 1<<RXCIE1)
	sts UCSR1B, mpr

; -------------------------------------------------------------

; TIMER/COUNTER1 ----------------------------------------------

	;Set Normal mode
	ldi mpr, 0b00000000
	sts TCCR1A, mpr

	; Prescale of 1024
	ldi mpr, 0b00000101
	sts TCCR1B, mpr
; -------------------------------------------------------------	

; LCD ---------------------------------------------------------
	
	;Initialize LCD Display
	rcall LCDInit
	rcall LCDClr
	rcall LCDBacklightOn

	; Print the welcome message to the screen
	call LOAD_WELCOME_MSG

	; Write the welcome message to the LCD 
	rcall LCDWrite
; -------------------------------------------------------------

; Initial Register & Flag State -------------------------------
	
	; Clear registers that need to have a known initial state
	clr loop_count

	; Start at zero but the numbers actually start at one so the 
	; first time we call it prints rock
	clr item_selection

	; By clearing this, the state is set to 0x00 meaning the 
	; welcome message should print in the main
	clr game_state

	; Clearing this indicates both players aren't ready
	clr user_ready
	clr opp_ready

	; Globally enable interrupts
	sei
; -------------------------------------------------------------


;***********************************************************
;*  Main Program (Print the welcome message until PD7 pressed)
;***********************************************************
MAIN:
	ldi mpr, 0x02
	cp game_state, mpr
	breq GAME
		
	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

; Game control ---------------------------------------------


;***********************************************************
;*	Run the game
;***********************************************************
GAME:

	; Print the GAME START message with rock as default move
	call LOAD_START_MSG
	rcall LCDWrite

	; Clear both of these so the tran/recv functions won't
	; restart the game unintentionally
	clr user_ready
	clr opp_ready
	rcall CYCLE_SELCTION

	; Start the 6 second timer for the move selection process
	; This routine will proceed until interrupted by PD4 (int 1)
	; that should be enabled at this point. Once the timer is
	; complete, this will return
	rcall WAIT_SIX_SECONDS

	; Set the UDRE1 bit in the UCSR1A so transmit is allowed 
	; via our busy wait function. To send the user move
	lds mpr, UCSR1A
	sbr mpr, UDRE1
	sts UCSR1A, mpr

	; Move the user move into the transmit buffer, then transmit
	mov transmit_byte, item_selection
	rcall TRANSMIT

	rcall DISPLAY_OPP_MOVE

	rcall WAIT_SIX_SECONDS

	; Intentional lack of ret here so it moves to the END_GAME
	; after the count down is finished

;***********************************************************
;*	Run the end of game procedures
;***********************************************************
END_GAME:
	; set game state to end game
	ldi mpr, 0x03
	mov game_state, mpr

	; Result Decision and display ------------------------------
	
	cpi item_selection, 0x01
	breq USER_ROCK

	cpi item_selection, 0x02
	breq USER_PAPER

	cpi item_selection, 0x03
	breq USER_SCISSORS
	; ----------------------------------------------------------

	; Reset state of game --------------------------------------
	
	; Configure the External Interrupt Mask for int 0 only
	ldi mpr, 0b00000001
	out EIMSK, mpr

	; clear display
	rcall LCDClr

	; set game mode to welcome message
	ldi mpr, 0x00
	mov game_state, mpr

	; Print the welcome message to the screen
	call LOAD_WELCOME_MSG

	; Write the welcome message to the LCD 
	rcall LCDWrite

	; Clear registers that need to have a known initial state
	clr loop_count

	; Start at zero but the numbers actually start at one so the 
	; first time we call it prints rock
	clr item_selection

	; By clearing this, the state is set to 0x00 meaning the 
	; welcome message should print in the main
	clr game_state

	; Clearing this indicates both players aren't ready
	clr user_ready
	clr opp_ready
	; ----------------------------------------------------------

	ret

; ------------------------------------------------------------

; Handle Moves -----------------------------------------------

;***********************************************************
;*	User played rock
;***********************************************************
USER_ROCK:
	
	; opponent chose rock - tie
	ldi mpr, 0x01
	cp opp_move, mpr
	breq TIE

	; opponent chose paper - loss
	ldi mpr, 0x02
	cp opp_move, mpr
	breq LOSS

	; opponent chose scissors - win
	ldi mpr, 0x03
	cp opp_move, mpr
	breq WIN

	ret

;***********************************************************
;*	User played paper
;***********************************************************
USER_PAPER:
	
	; opponent chose rock - win
	ldi mpr, 0x01
	cp opp_move, mpr
	breq WIN

	; opponent chose paper - tie
	ldi mpr, 0x02
	cp opp_move, mpr
	breq TIE

	; opponent chose scissors - loss
	ldi mpr, 0x03
	cp opp_move, mpr
	breq LOSS

	ret

;***********************************************************
;*	User played scissors
;***********************************************************
USER_SCISSORS:
	
	; opponent chose rock - loss
	ldi mpr, 0x01
	cp opp_move, mpr
	breq LOSS
	ret

	; opponent chose paper - win
	ldi mpr, 0x02
	cp opp_move, mpr
	breq WIN
	ret

	; opponent chose scissors - tie
	ldi mpr, 0x03
	cp opp_move, mpr
	breq TIE
	ret

;***********************************************************
;*	User won the round
;***********************************************************
WIN:
	call LOAD_WIN_MSG
	rcall LCDWrLn2
	ret

;***********************************************************
;*	User lost the round
;***********************************************************
LOSS:
	call LOAD_LOSS_MSG
	rcall LCDWrLn2
	ret

;***********************************************************
;*	User tied with opponenet
;***********************************************************
TIE:
	call LOAD_DRAW_MSG
	rcall LCDWrLn2
	ret

	
;***********************************************************
;*	Run the end of game procedures
;***********************************************************
DISPLAY_OPP_MOVE:
	mov opp_move, recv_byte

	ldi mpr, 0x01
	cp opp_move, mpr
	breq OPP_ROCK

	ldi mpr, 0x02
	cp opp_move, mpr
	breq OPP_PAPER

	ldi mpr, 0x03
	cp opp_move, mpr
	breq OPP_SCISSORS

	OPP_ROCK:
		call LOAD_TOP_ROCK_MSG
		rcall LCDWrLn2
		ret
	OPP_PAPER:
		call LOAD_TOP_PAPER_MSG
		rcall LCDWrLn2
		ret
	OPP_SCISSORS:
		call LOAD_TOP_SCISSORS_MSG
		rcall LCDWrLn2
		ret
	ret

; ----------------------------------------------------------

; Communication Subroutines --------------------------------

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

	SET_USER_READY:
		ldi mpr, 0x01
		mov user_ready, mpr

		; If the opp is ready begin the game, set game state
		; and enable move select interrupt PD4, otherwise end the routine
		sbrs opp_ready, 0x01
		rjmp END_TRANSMIT
		ldi mpr, 0x02
		mov game_state, mpr

		; Now enable PD4 (int 1) for move selection 
		ldi mpr, 0b00000010
		out EIMSK, mpr
	
	END_TRANSMIT:

	ret

;***********************************************************
;*	Read whatever data is waiting into the recv_byte
;***********************************************************
RECEIVE:
	lds recv_byte, UDR1

	; If the message was the ready signal from opp handle that
	cpi recv_byte, 0xFF
	breq SET_OPPONENT_READY

	; Otherwise just end the routine (ensure game won't restart)
	jmp END_RECEIVE

	SET_OPPONENT_READY:
		; Set opp ready to indicate opponent is ready
		ldi mpr, 0x01
		mov opp_ready, mpr

		; If the user is ready begin the game, set game state
		; and enable move select interrupt PD4, otherwise end the routine
		sbrs user_ready, 0x01
		jmp END_RECEIVE
		ldi mpr, 0x02
		mov game_state, mpr

		; Now enable PD4 (int 1) for move selection 
		ldi mpr, 0b00000011
		out EIMSK, mpr
	
	END_RECEIVE:

	ret

; ---------------------------------------------------------

; Interrupt Subroutines -----------------------------------

;***********************************************************
;*	Transmit the data that is currently in the transmit_byte
;***********************************************************
SEND_READY:
	; Clear queued interrupts
	ldi mpr, 0b00000001
	out EIFR, mpr

	; Set game state to waiting for opponent and display on LCD
	ldi mpr, 0x01
	mov game_state, mpr
	call LOAD_WAITING_MSG
	rcall LCDWrite

	; Load the Ready signal into the transmit buffer, then transmit
	ldi mpr, SendReady
	mov transmit_byte, mpr
	rcall TRANSMIT

	ret

;***********************************************************
;*	Switch between each of the possible items we can use
;***********************************************************
CYCLE_SELCTION:
	; Increment item_selection by one
	inc item_selection

	cpi item_selection, 0x01
	breq ROCK

	cpi item_selection, 0x02
	breq PAPER

	cpi item_selection, 0x03
	breq SCISSORS

	ROCK:
		call LOAD_ROCK_MSG
		rcall LCDWrLn2
		; Clear queued interrupts
		ldi mpr, 0b00000001
		out EIFR, mpr
		ret

	PAPER:
		call LOAD_PAPER_MSG
		rcall LCDWrLn2
		; Clear queued interrupts
		ldi mpr, 0b00000001
		out EIFR, mpr
		ret

	SCISSORS:
		call LOAD_SCISSORS_MSG
		rcall LCDWrLn2
		ldi item_selection, 0x00
		; Clear queued interrupts
		ldi mpr, 0b00000001
		out EIFR, mpr
		ret

; ---------------------------------------------------------

; Wait subroutines ----------------------------------------

;***********************************************************
;*	Wait for One and a Half seconds before returning
;***********************************************************
WAIT_ONE_HALF_SECOND:
	push mpr
	in mpr, SREG
	push mpr
	push loop_count

	; Set number of loops to 3
	ldi loop_count, 3
	ldi mpr, 0b00001111
	out PORTB, mpr


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

	pop loop_count
	pop mpr
	out SREG, mpr
	pop mpr
	ret

;***********************************************************
;*	Wait for One and a Half seconds before returning
;***********************************************************
WAIT_SIX_SECONDS:
	push mpr
	in mpr, SREG
	push mpr
	push loop_count

	; Set counter to use 1.5 second timer 4 times (6 seconds)
	ldi loop_count, 4

	; Set the top four bits of PORTB to 1111 for the timer display
	; Each 1.5 second, cycle one bit is removed
	ldi mpr, 0xF0
	out PORTB, mpr

	ONE_CYCLE:
		rcall WAIT_ONE_HALF_SECOND

		; Take the four bits of PORTB shift right 
		; (ex: 01110000 -> 00111000) then and with 0xF0
		; to remove lower byte 1 that was shifted, put back out to PORTB
		in mpr, PORTB
		lsr mpr
		andi mpr, 0xF0
		out PORTB, mpr

		dec loop_count

		; if the timer is complete we want to move forward with the program
		cpi loop_count, 0x00
		brne ONE_CYCLE

	pop loop_count
	pop mpr
	out SREG, mpr
	pop mpr
	ret

; ----------------------------------------------------------

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
.include "StringManager.asm"	; Seperate file to handle all of the strings that need to be printed
