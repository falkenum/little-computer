    j start:
vga_write_addr:
    .word F80C
vga_vblank_addr:
    .word F80D
screen_width:
    .word 0280 ;640 in decimal
screen_height:
    .word 01E0 ;480 in decimal
snk_width:
    .word 0008
snk_x:
    .word 0010
snk_y:
    .word 0010
snk_color:
    .word 0008
bg_color:
    .word 0888
txrdy_addr:
    .word F80A
tx_addr:
    .word F80B
msg:
    .string "hello world\n"
start:
    ; drawing the background
    lw bg_color r0 r1
    lw screen_width r0 r2
    lw screen_height r0 r3
    addi 0 r0 r4
    addi 0 r0 r5
    jl draw_rect

    addi 20 r0 r1
    sw snk_x r0 r1
    sw snk_y r0 r1
main:
    lw vga_vblank_addr r0 r1
    ; get vblank value
    lw 0 r1 r1
    ; if it's 0, loop and check again
    beq main_j r1 r0
    ; else handle the vblank
    jl vblank_handler
main_j:
    j main

vblank_handler:
    lw bg_color r0 r1
    lw snk_width r0 r2
    lw snk_width r0 r3
    lw snk_x r0 r4
    lw snk_y r0 r5

    push lr
    push r4
    jl draw_rect
    pop r4
    pop lr

    ; inc x and store back in memory
    addi 1 r4 r4
    sw snk_x r0 r4

    lw snk_color r0 r1
    lw snk_width r0 r2
    lw snk_width r0 r3
    lw snk_y r0 r5

    push lr
    push r4
    jl draw_rect
    pop r4
    pop lr

    ; wait for vblank to go low
vblank_check:
    lw vga_vblank_addr r0 r1
    ; get vblank value
    lw 0 r1 r1
    ; if it's 0, return
    beq vblank_end r1 r0
    ; else loop and check again
    j vblank_check
vblank_end:
    rts


; r1: color
; r2: width
; r3: height
; r4: x
; r5: y
draw_rect:
    ; backup the x location
    push r4
    lw vga_write_addr r0 r6

    ; store the end location - x and y
    add r4 r2 r2
    add r5 r3 r3

draw_rect_loop:
    ; x write
    sw 0 r6 r4
    ; y write
    sw 0 r6 r5
    ; bgr write
    sw 0 r6 r1

    addi 1 r4 r4

    ; if we have done 640 pixels, go to next line
    beq draw_rect_line_complete r4 r2
    j draw_rect_loop
draw_rect_line_complete:
    ; inc y
    addi 1 r5 r5
    ; reset x
    pop r4
    push r4
    beq draw_rect_end r5 r3
    j draw_rect_loop
draw_rect_end:
    pop r4
    rts


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

print_strloop:
    ; load char into r3
    lw 0 r1 r3

    ; if null char, go to the end
    beq print_end r0 r3

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
    j print_strloop

print_end:
    pop r5
    pop r4
    pop r3
    pop r2
    pop r1
    rts