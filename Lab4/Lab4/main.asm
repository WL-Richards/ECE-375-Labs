;***********************************************************
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;*	 Author: Will Richards, Caden Hawkins
;*	   Date: 10/19/2022
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine

		; Initialize Stack Pointer
		ldi mpr,low(RAMEND)
		out SPL,r16
		ldi mpr,high(RAMEND)
		out SPH,r16

		; TODO

		clr		zero			; Set the zero register to zero, maintain
										; these semantics, meaning, don't
										; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program

		; Call function to load ADD16 operands
		rcall LoadAdd16 ; Check load ADD16 operands (Set Break point here #1)

		; Call ADD16 function to display its results (calculate FCBA + FFFF)
		rcall Add16 ; Check ADD16 result (Set Break point here #2)


		; Call function to load SUB16 operands
		rcall LoadSub16 ; Check load SUB16 operands (Set Break point here #3)

		; Call SUB16 function to display its results (calculate FCB9 - E420)
		rcall Sub16 ; Check SUB16 result (Set Break point here #4)

		; Call function to load MUL24 operands
		rcall LoadMul24 ; Check load MUL24 operands (Set Break point here #5)

		; Call MUL24 function to display its results (calculate FFFFFF * FFFFFF)
		rcall MUL24; Check MUL24 result (Set Break point here #6)

		; Call the COMPOUND function
		rcall COMPOUND ; Check COMPOUND result (Set Break point here #8)

DONE:	rjmp	DONE			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************


;-----------------------------------------------------------
; Func: LoadMul24
; Desc: Load values from program memory for multiplying
;-----------------------------------------------------------
LoadMul24:							; Begin a function with a label

		; Load Operand A Address into Z
		ldi ZL, low(2*OperandE1)
		ldi ZH, high(2*OperandE1)

		; Load beginning address of first operand into X
		ldi XL, low(MulAddrA)	; Load low byte of address
		ldi	XH, high(MulAddrA)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(MulAddrB)	; Load low byte of address
		ldi		YH, high(MulAddrB)	; Load high byte of address

		; Load the 2 bytes from 
		lpm A, Z+
		ST X+, A
		lpm A, Z+
		ST X+, A
		lpm A, Z
		ST X, A
		

		ldi ZL, low(2*OperandF1)
		ldi ZH, high(2*OperandF1)

		lpm A, Z+
		ST Y+, A
		lpm A, Z+
		ST Y+, A
		lpm A, Z
		ST Y, A
		
		 
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: LoadAdd16
; Desc: Load values from program memory for adding
;-----------------------------------------------------------
LoadAdd16:							; Begin a function with a label

		; Load Operand A Address into Z
		ldi ZL, low(2*OperandA)
		ldi ZH, high(2*OperandA)

		; Load beginning address of first operand into X
		ldi XL, low(ADD16_OP1)	; Load low byte of address
		ldi	XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte of address
		ldi		YH, high(ADD16_OP2)	; Load high byte of address

		; Load the 2 bytes from 
		lpm A, Z+
		ST X+, A
		lpm A, Z
		ST X, A

		ldi ZL, low(2*OperandB)
		ldi ZH, high(2*OperandB)

		lpm A, Z+
		ST Y+, A
		lpm A, Z
		ST Y, A
		 
		ret						; End a function with RET


;-----------------------------------------------------------
; Func: LoadSub16
; Desc: Load values from program memory for subtraction
;-----------------------------------------------------------
LoadSub16:							; Begin a function with a label

		; Load Operand A Address into Z
		ldi ZL, low(2*OperandC)
		ldi ZH, high(2*OperandC)

		; Load beginning address of first operand into X
		ldi XL, low(SUB16_OP1)	; Load low byte of address
		ldi	XH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)	; Load low byte of address
		ldi		YH, high(SUB16_OP2)	; Load high byte of address

		; Load the 2 bytes from 
		lpm A, Z+
		ST X+, A
		lpm A, Z
		ST X, A

		ldi ZL, low(2*OperandD)
		ldi ZH, high(2*OperandD)

		lpm A, Z+
		ST Y+, A
		lpm A, Z
		ST Y, A
		 
		ret						; End a function with RET


;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;       where the high byte of the result contains the carry
;       out bit.
;-----------------------------------------------------------
ADD16:
		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)	; Load low byte of address
		ldi		XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte of address
		ldi		YH, high(ADD16_OP2)	; Load high byte of address

		; Load beginning address of result into Z
		ldi		ZL, low(ADD16_Result)	; Load low byte of address
		ldi		ZH, high(ADD16_Result)	; Load high byte of address

		; Execute the function
		; First Byte 
		ld r3, X+				; Load first low byte into A
		ld r4, Y+				; Load first high byte into B
		ADD r3, r4				; Add second low byte to first
		ST Z+, r3

		; Second Byte
		ld r3, X				; Load first low byte into A
		ld r4, Y				; Load first high byte into B
		ADC r3, r4				; Add second low byte to first
		ST Z+, r3
		brcc EXIT_ADD
		ldi mpr, 0x01
		ST Z, mpr

		EXIT_ADD:
			ret						; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;       result. Always subtracts from the bigger values.
;-----------------------------------------------------------
SUB16:
		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)	; Load low byte of address
		ldi		XH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)	; Load low byte of address
		ldi		YH, high(SUB16_OP2)	; Load high byte of address

		; Load beginning address of result into Z
		ldi		ZL, low(SUB16_Result)	; Load low byte of address
		ldi		ZH, high(SUB16_Result)	; Load high byte of address

		; Execute the function
		; First Byte 
		ld r3, X+				; Load first low byte into A
		ld r4, Y+				; Load first high byte into B
		SUB r3, r4				; Subtract low byte from high byte
		ST Z+, r3

		; Second Byte
		ld r3, X				; Load first low byte into A
		ld r4, Y				; Load first high byte into B
		SBC r3, r4				; Add second low byte to first
		ST Z+, r3
		brcc EXIT_SUB
		ldi mpr, 0x01
		ST Z, mpr

		EXIT_SUB:
			ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit
;       result.
;-----------------------------------------------------------
MUL24:
		;* - Simply adopting MUL16 ideas to MUL24 will not give you steady results. You should come up with different ideas.
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(MulAddrB)	; Load low byte
		ldi		YH, high(MulAddrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MulAddrRes)	; Load low byte
		ldi		ZH, high(MulAddrRes); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(MulAddrA)	; Load low byte
		ldi		XH, high(MulAddrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter

MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((G - H) + I)^2
;       by making use of SUB16, ADD16, and MUL24.
;
;       D, E, and F are declared in program memory, and must
;       be moved into data memory for use as input operands.
;
;       All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:
		
		; ---------------------------------------------------------------------------------------------------
		; Setup SUB16 with operands G and H

		; Load Operand A Address into Z
		ldi ZL, low(2*OperandG)
		ldi ZH, high(2*OperandG)

		ldi XL, low(SUB16_OP1)	; Load low byte of address
		ldi	XH, high(SUB16_OP1)	; Load high byte of address

		; Load the 2 bytes from 
		lpm A, Z+
		ST X+, A
		lpm A, Z
		ST X, A

		ldi ZL, low(2*OperandH)
		ldi ZH, high(2*OperandH)

		ldi XL, low(SUB16_OP2)	; Load low byte of address
		ldi	XH, high(SUB16_OP2)	; Load high byte of address

		lpm A, Z+
		ST X+, A
		lpm A, Z
		ST X, A

		; Perform subtraction to calculate G - H
		rcall SUB16

		; Setup the ADD16 function with SUB16 result and operand I4
		; ---------------------------------------------------------------------------------------------------

		; ---------------------------------------------------------------------------------------------------

		; Load Operand A Address into Z
		ldi ZL, low(2*OperandI)
		ldi ZH, high(2*OperandI)

		ldi XL, low(ADD16_OP1)	; Load low byte of address
		ldi	XH, high(ADD16_OP1)	; Load high byte of address

		; Load the 2 bytes from program memory
		lpm A, Z+
		ST X+, A
		lpm A, Z
		ST X, A

		; Load the subtraction result in to the second add operator
		ldi ZL, low(SUB16_Result)
		ldi ZH, high(SUB16_Result)

		ldi XL, low(ADD16_OP2)	; Load low byte of address
		ldi	XH, high(ADD16_OP2)	; Load high byte of address

		ld A, Z+
		ST X+, A
		ld A, Z
		ST X, A

		rcall ADD16

		; ---------------------------------------------------------------------------------------------------


		; Perform addition next to calculate (G - H) + I

		; Setup the MUL24 function with ADD16 result as both operands

		; Load Operand A Address into Z
		ldi ZL, low(ADD16_Result)
		ldi ZH, high(ADD16_Result)

		; Load beginning address of first operand into X
		ldi XL, low(MulAddrA)	; Load low byte of address
		ldi	XH, high(MulAddrA)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(MulAddrB)	; Load low byte of address
		ldi		YH, high(MulAddrB)	; Load high byte of address

		; Load the 2 bytes from 
		ld A, Z+
		ST X+, A
		ld A, Z+
		ST X+, A
		ld A, Z
		ST X, A
		

		ldi ZL, low(ADD16_Result)
		ldi ZH, high(ADD16_Result)

		ld A, Z+
		ST Y+, A
		ld A, Z+
		ST Y+, A
		ld A, Z
		ST Y, A

		; Perform multiplication to calculate ((G - H) + I)^2
		rcall MUL24

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;       A - Operand A is gathered from address $0101:$0100
;       B - Operand B is gathered from address $0103:$0102
;       Res - Result is stored in address
;             $0107:$0106:$0105:$0104
;       You will need to make sure that Res is cleared before
;       calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(MulAddrA)	; Load low byte
		ldi		YH, high(MulAddrA)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MulAddrRes)	; Load low byte
		ldi		ZH, high(MulAddrRes)	; Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;*	Do not  section.
;***********************************************************
; ADD16 operands
OperandA:
	.DW 0x0001
OperandB:
	.DW 0x0002

; SUB16 operands
OperandC:
	.DW 0XFCB9
OperandD:
	.DW 0XE420

; MUL24 operands
OperandE1:
	.DW	0XFFFF
OperandE2:
	.DW	0X00FF
OperandF1:
	.DW	0XFFFF
OperandF2:
	.DW	0X00FF

; Compoud operands
OperandG:
	.DW	0xFCBA				; test value for operand G
OperandH:
	.DW	0x2022				; test value for operand H
OperandI:
	.DW	0x21BB				; test value for operand I

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 3
addrB:	.byte 3
LAddrP:	.byte 4

.org	$0110
MulAddrA:	.byte 3
MulAddrB:	.byte 3
MulAddrRes:	.byte 9

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.
.org	$0120				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0130				; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

; Subtract memory blocks
.org	$0140				; data memory allocation for operands
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
SUB16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0150				; data memory allocation for results
SUB16_Result:
		.byte 2				; allocate three bytes for ADD16 result
		
;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
