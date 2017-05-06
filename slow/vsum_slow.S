    .equ EXPBITS, 0xFF000000 @remember to shift me over one when you use me!
    .equ SIGNBITS, 0x80000000
    .equ INTRINSIC, 0x00800000
@    .data
@
@vec1:
@    .word 0x43c04000
@    .word 0x41400000
@    .word 0xc416e000
@    .word 0x41300000
@
@vec2:
@    .word 0x3f800000
@    .word 0x40000000
@    .word 0x40400000
@    .word 0x40800000
@
@.balign 4
@    .text
@    .global main
@
@main:
@    ldr r1, =vec1 @end of vec1
@    sub r1, r1, #4
@    add r0, r1, #16 @start of vec1
@    ldr r2, =vec2   @start of vec2
@
vsum:
    stmfd sp!, {r1-r12,lr}
    ldr r4, [r0], #-4
    ldr r6, [r2], #4
    eor r5, r4, r6      @sign bit - r5
                        @get exponents in excess-127
    bic r3, r4, #SIGNBITS
    lsr r3, #23

    bic r7, r6, #SIGNBITS
    lsr r7, #23

    add r3, r3, r7
    CMP r3,#127
    subGT r3, r3, #127    @Er in excess-127
    MOVLE r3,#0

                        @get mantissa
    bic r4, r4, #EXPBITS
    orr r4, r4, #INTRINSIC
    mov r4, r4, lsr #11
    bic r6, r6, #EXPBITS
    orr r6, r6, #INTRINSIC
    mov r6, r6, lsr #11

                        @do the actual multiplication
    mul r4, r4, r6
    tst r4, #(1<<25)    @is leading 1 in the 26th bit?
    lsrne r4, #2            @if so, lsr 2
    addne r3, r3, #1        @e++
    lsreq r4, #1            @else, lsr 1

    @r4 is now mantissa in U(23),
    @r3 is still the exponent
    tst r5, #SIGNBITS
    rsbne r4, r4, #0        @Take 2's complement

vsumloop:
    ldr r5, [r0], #-4
    ldr r6, [r2], #4

    eor r7, r5, r6            @Sign bit in r7

                              @get exponents in excess-127
    bic r8, r5, #SIGNBITS
    lsr r8, #23

    bic r9, r6, #SIGNBITS
    lsr r9, #23

    add r8, r8, r9
    CMP r8,#127
    subGT r8, r8, #127          @Er in excess-127 in r8
    MOVLE r8,#0

                              @get mantissa
    bic r5, r5, #EXPBITS
    orr r5, r5, #INTRINSIC
    mov r5, r5, lsr #11
    bic r6, r6, #EXPBITS
    orr r6, r6, #INTRINSIC
    mov r6, r6, lsr #11

                              @multiply mantissa
    mul r5, r5, r6
    tst r5, #(1<<25)          @is the leading 1 in the 26th bit?
    lsrne r5, #2              @if so, lsr 2
    addne r8, r8, #1          @e++
    lsreq r5, #1              @else lsr 1

                              @Get S(1,23) in r5
    tst r7, #SIGNBITS
    rsbne r5, r5, #0          @take 2's complement if needed

    sub r7, r3, r8            @subtract one exponent from the other
    cmp r7, #0
    asrgt r5, r5, r7
    rsblt r7, r7, #0
    asrlt r4, r4, r7
    movlt r3, r8              @Er in r3

    adds r4, r4, r5           @Mr in r4
    moveq r3, #0
    bleq vsumbail

    rsbmi r4, r4, #0          @Sign in r5
    movmi r5, #1
    movpl r5, #0

    mov r6, #0
    cmp r4, #1<<16
    movlo r4, r4, lsl #16
    addlo r6, r6, #16

    tst r4, #0xFF000000
    moveq r4, r4, lsl #8
    addeq r6, r6, #8

    tst r4, #0xF0000000
    moveq r4, r4, lsl #4
    addeq r6, r6, #4

    tst r4, #0xC0000000
    moveq r4, r4, lsl #2
    addeq r6, r6, #2

    tst r4, #0x80000000
    moveq r4, r4, lsl #1
    addeq r6, r6, #1

    rsb r6, r6, #8
    add r3, r3, r6

    lsr r4, r4, #8
    tst r5, #1                @if sign indicates negative
    rsbne r4, r4, #0          @take 2's complement

vsumbail:
    cmp r0, r1
    bhi vsumloop

@    cmp r4, #0
@    movle r0, #0
@    movgt r0, #1

    rsblt r4, r4, #0

    bic r0, r4, #INTRINSIC
    orrlt r0, r0, #(1<<31)        @set sign bit
    orr r0, r0, r3, lsl #23       @ orr in exponent

    ldmfd sp!, {r1-r12, pc}
