/*
 * StringManager.asm
 *
 *  Created: 11/27/2022 3:56:27 PM
 *   Author: Will Richards
 */ 

 .include "m32U4def.inc"         ; Include definition file

 ; everything in this driver file needs to go into the code segment
.cseg

; This should load the Welcome Message from Program memory into the LCD display area
LOAD_WELCOME_MSG:

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


; This should load the start message 
LOAD_START_MSG:

	ldi XL, 0x00
	ldi XH, 0x01

	ldi ZL, low(STRING_GAME_START<<1)
	ldi ZH, high(STRING_GAME_START<<1)

	; Loop to load in all the data
	START_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_GAME_END<<1)
		brne WELCOME_MSG_LOOP

	ret

; This should load the waiting message 
LOAD_WAITING_MSG:

	ldi XL, 0x00
	ldi XH, 0x01

	ldi ZL, low(STRING_OPPONENT_START<<1)
	ldi ZH, high(STRING_OPPONENT_START<<1)

	; Loop to load in all the data
	WAITING_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_OPPONENT_END<<1)
		brne WAITING_MSG_LOOP

	ret

; This should load the won message 
LOAD_WIN_MSG:

	ldi XL, 0x00
	ldi XH, 0x01

	ldi ZL, low(STRING_WON_START<<1)
	ldi ZH, high(STRING_WON_START<<1)

	; Loop to load in all the data
	WIN_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_WON_END<<1)
		brne WIN_MSG_LOOP

	ret

; This should load the lost message 
LOAD_LOSS_MSG:

	ldi XL, 0x00
	ldi XH, 0x01

	ldi ZL, low(STRING_LOST_START<<1)
	ldi ZH, high(STRING_LOST_START<<1)

	; Loop to load in all the data
	LOSS_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_LOST_END<<1)
		brne LOSS_MSG_LOOP

	ret

; This should load the lost message 
LOAD_DRAW_MSG:

	ldi XL, 0x00
	ldi XH, 0x01

	ldi ZL, low(STRING_DRAW_START<<1)
	ldi ZH, high(STRING_DRAW_START<<1)

	; Loop to load in all the data
	DRAW_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_DRAW_END<<1)
		brne DRAW_MSG_LOOP

	ret

; This should load the rock message 
LOAD_ROCK_MSG:

	ldi XL, 0x10
	ldi XH, 0x01

	ldi ZL, low(STRING_ROCK_START<<1)
	ldi ZH, high(STRING_ROCK_START<<1)

	; Loop to load in all the data
	ROCK_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_ROCK_END<<1)
		brne ROCK_MSG_LOOP

	ret

; This should load the paper message
LOAD_PAPER_MSG:

	ldi XL, 0x10
	ldi XH, 0x01

	ldi ZL, low(STRING_PAPER_START<<1)
	ldi ZH, high(STRING_PAPER_START<<1)

	; Loop to load in all the data
	PAPER_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_PAPER_END<<1)
		brne PAPER_MSG_LOOP

	ret

; This should load the paper message
LOAD_SCISSORS_MSG:

	ldi XL, 0x10
	ldi XH, 0x01

	ldi ZL, low(STRING_SCISSORS_START<<1)
	ldi ZH, high(STRING_SCISSORS_START<<1)

	; Loop to load in all the data
	SCISSORS_MSG_LOOP:
		lpm mpr, Z+
		st X+, mpr

		cpi ZL, low(STRING_SCISSORS_END<<1)
		brne SCISSORS_MSG_LOOP

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
