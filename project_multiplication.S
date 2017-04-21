	@#include "FilterTable.S"
	@#include "CarrierTable.S"
	@#include "Modulated.S"

	.data

	.equ    F_MASK, 0xFF800000  @ mask to isolate fractional part of float
    .equ    E_MASK, 0x10700000  @ mask to isolate exponental part of float
    .equ    LEADON, 0x00100000  @ position of the leading 1 at the 24th bit
    .equ    f1    , 0x411c0000  @ 0d9.75
    .equ    f2    , 0x40200000  @ 0d2.50

	.text
	.global main
main:


LDR r0,=f1
LDR r1,=f2


@ r0 contains first  passed in operand
@ r1 contains second passed in operand
@ r4 contains the fractional product
MOV r4,#0

LDR r3,=F_MASK      @ clear all non-fractional bits
BIC r2,r0,r3        @ r2 contains fraction of op0
BIC r3,r1,r3        @ r3 contains fraction of op1
ORR r2,r2,#LEADON   @ add the leading one back to the number
ORR r3,r3,#LEADON   @ add the leading one back to the number

@@ TODO replace with binary search
slmo1_loop:         @ 'shift to left-most one'
TST r2,#1           @ test left-most bit
LSREQ r2,r2,#1      @ shift if empty
BEQ slmo1_loop      @ repeat until bit is filled

slmo2_loop:         @ 'shift to left-most one'
TST r3,#1           @ test left-most bit
LSREQ r3,r3,#1      @ shift if empty
BEQ slmo2_loop      @ repeat until bit is filled

MUL r4,r2,r3        @ multiply numbers together

srmo_loop:          @ 'shift to right-most one' to bit 24
TST r4,#LEADON      @ test test leading bit
LSLNE r4,r4,#1      @ shift if empty
BNE srmo_loop       @ repeat until bit is filled
BIC r4,r4,#LEADON   @ clear leading 1

LDR r3,=E_MASK
BIC r2,r0,r3        @ r2 contains exponent of op0
BIC r3,r1,r3        @ r3 contains exponent of op1
ADD r2,r2,r3        @ add together exponents
SUB r2,r2,#127
ORR r4,r2,r4        @ insert exponent part to fractional part

EOR r2,r0,r1        @ compare signs of two values
BIC r2,r2,#0x7FFFFFFF   @ clear all but sign bit
ORR r4,r2,r4        @ update sign bit of answer


stop: b stop

