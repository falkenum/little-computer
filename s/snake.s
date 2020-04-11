    j print:
vga_write_addr:
    .word F80C
screen_width:
    .word 0280 #640 in decimal
screen_height:
    .word 01E0 #480 in decimal
bg_color:
    .word 0888
snk_color:
    .word 0808
snk_width:
    .word 0040
txrdy_addr:
    .word F80A
tx_addr:
    .word F80B
zero_char:
    .string "0"
msg:
    .string "hello world\n"

# r1: color
# r2: width
# r3: height
# r4: x
# r5: y
draw_rect:
    push r6
    lw vga_write_addr r0 r6
    # lw pix_per_line r0 r5
    # lw lines_per_screen r0 r3

    push r4

rectloop:
    # x write
    sw 0 r6 r4
    # y write
    sw 0 r6 r5
    # bgr write
    sw 0 r6 r1

    # inc x
    addi 1 r4 r4

    beq line_complete r2 r4
    j rectloop

line_complete:
    # jl print
    # inc y
    addi 1 r5 r5
    # reset x
    pop r4
    push r4
    # check if done
    beq rectret r5 r3
    j rectloop
rectret:
    pop r4
    pop r6
    rts

start:
    jl print
    halt
main:
    lw bg_color r0 r1
    lw screen_width r0 r2
    lw screen_height r0 r3
    # x
    addi 0 r0 r4
    # y
    addi 0 r0 r5
    # jl draw_rect

    halt



    
print:
    push r1
    push r2
    push r3
    push r4
    push r5
    # load msg addr into r1
    addi msg r0 r1

    # load tx_addr into r2
    lw tx_addr r0 r2

    # load txrdy_addr into r5
    lw txrdy_addr r0 r5

    # load 1 into r4, for comparison
    addi 1 r0 r4

strloop:
    # load char into r3
    lw 0 r1 r3

    # if null char, go to the end
    beq end r0 r3

    # store char at tx_addr
    sw 0 r2 r3

    # we need to wait until txrdy goes low and then high again

txrdy_wait_for_low:
    # load txrdy value into r3
    lw 0 r5 r3
    beq txrdy_is_low r3 r0
    j txrdy_wait_for_low

txrdy_is_low:
    lw 0 r5 r3
    beq txrdy_is_high r3 r4
    j txrdy_is_low

txrdy_is_high:
    # inc char ptr
    addi 1 r1 r1
    j strloop

end:
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    halt
