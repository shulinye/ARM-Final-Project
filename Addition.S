    .equ EXPBITS, 0xFF000000 @remember to shift me over one when you use me!
    .equ SIGNBITS, 0x80000000
    .equ INTRINSIC, 0x00800000
    .data
addandsformat: .asciz "0x%x + 0x%x = \n"
sumformat: .asciz "0x%x\n"
.balign 4
    .text
    .global main

main:

    mov r5, #0
    ldr r6, =0x40ad70a4

    mov r1, r5
    mov r2, r6

    ldr r0, =addandsformat
    bl printf

    mov r0, r5
    mov r1, r6

    bl fadd

    mov r1, r0
    ldr r0, =sumformat
    bl printf

    mov r0, #0
    mov pc, lr


fadd:
    @@ numbers are in r0 and r1
    stmfd sp!, {r3-r12, lr}
    mov r9, #EXPBITS
    lsr r9, r9, #1
    and r2, r0, r9   @ E1
    and r3, r1, r9   @ E2

    sub r9, r2, r3        @ Subtract one exponent from the other
    cmp r9, #(24<<23)            @ If it's much greater, then just return
    blgt faddfinally
    mvn r10, #0x0B000000  @ #(-24<<23)
    cmp r9, r10
    movlt r0, r1
    bllt faddfinally

    ldr r10, =#0xFF800000
    bic r4, r0, r10 @ M1
    add r4, r4, #INTRINSIC  @ M1 in r4
    bic r5, r1, r10 @ M2
    add r5, r5, #INTRINSIC  @ M2 in r5

    tst r0, #SIGNBITS
    rsbne r4, r4, #0        @Taking the 2's complement
    tst r1, #SIGNBITS
    rsbne r5, r5, #0        @Taking the 2's complement

    cmp r9, #0
    asrgt r5, r5, r9
    rsblt r9, r9, #0
    asrlt r4, r4, r9
    movlt r2, r3            @ Er in r2

    adds r4, r4, r5         @ Mr in r4

    moveq r0, #0            @ If Mr is zero, return zero
    bleq faddfinally

    rsbmi r4, r4, #0        @ If negative, take 2's complement
    movmi r5, #1            @ Sr in r5
    movpl r5, #0

    mov r3, #0              @Shift amount in r3
    cmp r4, #1<<16
    movhs r4, r4, lsl #16
    addhs r3, r3, #16

    tst r4, #0xFF000000
    moveq r4, r4, lsl #8
    addeq r3, r3, #8

    tst r4, #0xF0000000
    moveq r4, r4, lsl #4
    addeq r3, r3, #4

    tst r4, #0xC0000000
    moveq r4, r4, lsl #2
    addeq r3, r3, #2

    tst r4, #0x80000000
    addeq r3, r3, #1
    moveq r4, r4, lsl #1

    bic r4, r4, #SIGNBITS
    lsr r4, r4, #8

    rsb r3, r3, #9
    add r2, r3, r2, lsr #23 @Move exponent over
    orr r0, r4, r2, lsl #23
    orr r0, r0, r5, lsl #31

faddfinally:
    ldmia sp!, {r3-r12, pc}
