    .equ EXPBITS, 0xFF000000
    .equ SIGNBITS, 0x80000000
    .equ INTRINSIC, 0x00800000

    .text
    .global fmul

fmull:
    stmfd sp!, {r1-r12, lr}
    eor r2, r1, r0      @Sign bit in r2
    and r2, r2, #SIGNBITS

                        @Get exponents
    bic r3, r0, #SIGNBITS
    lsr r3, #23

    bic r4, r1, #SIGNBITS
    lsr r4, #23

    add r3, r3, r4
    CMP r3,#127
    subGT r3, r3, #127
    MOVLE r3,#0

                        @Get mantissa
    bic r0, r0, #EXPBITS
    orr r0, r0, #INTRINSIC
    lsr r0, #11
    bic r1, r1, #EXPBITS
    orr r1, r1, #INTRINSIC
    lsr r1, #11

    mul r0, r0, r1
    tst r0, #(1<<25)    @is leading 1 in the 26th bit?
    lsrne r0, #2
    addne r3, r3, #1
    lsreq r0, #1

                        @Put number back together
    bic r0, r0, #INTRINSIC
    orr r0, r0, r3, lsl #23
    orr r0, r0, r2

    ldmfd sp!, {r1-r12, pc}
