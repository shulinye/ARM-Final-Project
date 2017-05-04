    .equ EXPBITS, 0xFF000000 @remember to shift me over one when you use me!
    .equ SIGNBITS, 0x80000000
    .equ INTRINSIC, 0x00800000
    .data

vec1:
    .word 0x3fc00000
    .word 0x41400000
    .word 0xc416e000
    .word 0x41300000

vec2:
    .word 0x3f800000
    .word 0x40000000
    .word 0x40400000
    .word 0x40800000

.balign 4
    .text
    .global main

main:
    stmfd sp!, {r0-r12,lr}
    ldr r0, =vec1 @start of vec1
    add r1, r0, #16 @end of vec1
    ldr r2, =vec2

    ldr r4, [r0], #4
    ldr r6, [r2], #4
    eor r5, r4, r6      @sign bit
                        @get exponents in excess-127
    bic r3, r4, #SIGNBITS
    lsr r3, #23

    bic r7, r6, #SIGNBITS
    lsr r7, #23

    add r3, r3, r7
    sub r3, r3, #127    @Er in excess-127

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

    @r4 is now mantissa in U(23)
    tst r5, #SIGNBITS
    rsbne r5, r5, #0        @Take 2's complement


loop:
    ldmfd sp!, {r0-r12, pc}
