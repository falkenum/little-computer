
    j start
vga_write_addr:
    .word F80C
pix_per_line:
    .word 0280 ;640 in decimal
lines_per_screen:
    .word 01E0 ;480 in decimal
bgr:
    .word 0800
txrdy_addr:
    .word F80A
tx_addr:
    .word F80B
zero_char:
    .string "0"
msg:
    .string "hello world\n"
start:
    ; store the write addr into r1
    lw vga_write_addr r0 r1
    lw pix_per_line r0 r2
    lw lines_per_screen r0 r3
    lw bgr r0 r4

    ; r4 is x reg
    addi 0 r0 r5

    ; r5 is y reg
    addi 0 r0 r6

loop:
    ; x write
    sw 0 r1 r5
    ; y write
    sw 0 r1 r6
    ; bgr write
    sw 0 r1 r4

    addi 1 r5 r5

    ; if we have done 640 pixels, go to next line
    beq line_complete r2 r5
    j loop
line_complete:
    jl print
    ; inc y
    addi 1 r6 r6
    ; reset x
    addi 0 r0 r5
    beq main r6 r3
    j loop

main:
    j main
    
print:
    push r1
    push r2
    push r3
    push r4
    push r5
    ; load msg addr into r1
    addi msg r0 r1

    ; load tx_addr into r2
    lw tx_addr r0 r2

    ; load txrdy_addr into r5
    lw txrdy_addr r0 r5

    ; load 1 into r4, for comparison
    addi 1 r0 r4

strloop:
    ; load char into r3
    lw 0 r1 r3

    ; if null char, go to the end
    beq end r0 r3

    ; store char at tx_addr
    sw 0 r2 r3

    ; we need to wait until txrdy goes low and then high again

txrdy_wait_for_low:
    ; load txrdy value into r3
    lw 0 r5 r3
    beq txrdy_is_low r3 r0
    j txrdy_wait_for_low

txrdy_is_low:
    lw 0 r5 r3
    beq txrdy_is_high r3 r4
    j txrdy_is_low

txrdy_is_high:
    ; inc char ptr
    addi 1 r1 r1
    j strloop

end:
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    rts
