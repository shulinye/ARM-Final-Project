	#include "FilterTable.S"
	#include "CarrierTable.S"
	#include "Modulated.S"
	#include "fmul.S"
	#include "vsum.S"


@---------------EE3181 Final Project-------------------------@
@ Takes in three files:										 @
@ a Modulated.S signal holding the data to be interpreted	 @
@ a CarrierTable.S that contains the carrier frequency		 @
@ and a FilterTable.S that is the relevant LPF				 @
@ All input files should be in IEEE floating point format	 @
@ This program will interperet the data held in Modulated.S	 @
@ to find the corresponding ascii message that it represents @
@------------------------------------------------------------@
@ code by: Shulin Ye, Andrea Salt, and Eric Schott ----------@

	.data

	.equ sizeof_mod,    (1201 << 2)
	.equ sizeof_car,    (1201 << 2)
	.equ sizeof_fil,    ( 301 << 2)
	.equ lenof_mod,     1201
	.equ lenof_fil,     301
	.equ sizeof_dig,    75
	.equ data_size,     1

@ storage space for convoluted data points
answer:
    .asciz "??"
@ char type used in printf to print message
char_type:
    .asciz "%s\n"
    .balign 4
@ scratch space for product of multiplication
scratch:
    .word 0
    .skip 1200 << 2

@----------start of main------------@
	.text
	.global main
main:

	STMFD sp!, {r1-r12,lr}
@----setup ptrs----@
    LDR r6,=modulated       @ addr of signal
    LDR r7,=carrier         @ to be mult
    LDR r8,=scratch         @ stores new info
    LDR r9,=sizeof_mod      @ track size of signal
    ADD r9,r9,r6            @ end location
@----setup ptrs----@

@---------MUL mod and car-----------@
@ multiplies values in modulated    @
@ and carrier to store in scratch   @
mul_loop:
    LDR r0,[r6],#4          @ load sig val and inc
    LDR r1,[r7],#4          @ load car val and inc
    BL fmull                 @ multiply vals together
    STR r0,[r8],#4          @ str prod val and inc
    CMP r6,r9               @ cmp sig ptr to end addr
    BLT mul_loop			@ repeat for all modulated
@---------MUL mod and car-----------@

@-----Convolve scratch and Filter-----@
@ scratch * filter convolves the two  @
@ and places the result in answer     @
    LDR r6,=scratch         @ x*
    LDR r7,=filter          @ h*
    LDR r8,=answer          @ y*
    LDR r9,=#lenof_mod		@ for comparing end
    LDR r10,=#lenof_fil		@
    MOV r11,#0              @ bin tracker
    MOV r12,#0              @ bin counter
    MOV r3,#-37             @ n counter
    MOV r4,#0               @ m counter
init_loop:
    ADD r3,r3,#sizeof_dig   @ increment n by digit size
    MOV r4,#0               @ set m to 0
    CMP r3,r9               @ check if end
    BGE conv_end
conv_loop:
    ADD r0,r6,r3,lsl #2     @ x* + n          start of x
    CMP r3,r10              @ if( n > 301 )
    SUBGT r5,r3,r10         @   p -= 301
    MOVLE r5,#0             @ else p = 0
    ADD r1,r6,r5,lsl #2     @ x* + n - 301 if needed; end of x
    MOV r2,r7               @ h[0]          start of h
    BL  vsum                @ find sum of conv
                            @ returned as 1 or 0 depending on sign
    CMP r11,#8
    ADDLT r12,r0,r12,lsl #1 @ add new bit
    ADDLT r11,r11,#1        @ increment tracker
    MOVGE r11,#0            @ reset tracker
    STRGEB r12,[r8],#1      @ store complete word
    MOVGE r12,#0
    B init_loop             @ branch back
conv_end:
    STRGEB r12,[r8],#1      @ store complete word

@-----Convolve scratch and Filter-----@

@-----print out secret message------@
    LDR r1,=answer
    LDR r0,=char_type
    BL printf
@-----print out secret message------@


stop: MOV r0,#0
	LDMFD sp!, {r1-r12,pc}


