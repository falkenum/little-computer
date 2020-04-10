    j start
vga_write_addr:
    .word F80C
pix_per_line:
    .word 0280 #640 in decimal
lines_per_screen:
    .word 01E0 #480 in decimal
bgr:
    .word 0800
start:
    # store the write addr into r1
    lw vga_write_addr r0 r1
    lw pix_per_line r0 r2
    lw lines_per_screen r0 r3
    lw bgr r0 r4

    # r4 is x reg
    addi 0 r0 r5

    # r5 is y reg
    addi 0 r0 r6

loop:
    # x write
    sw 0 r1 r5
    # y write
    sw 0 r1 r6
    # bgr write
    sw 0 r1 r4

    addi 1 r5 r5

    # if we have done 640 pixels, go to next line
    beq line_complete r2 r5
    j loop
line_complete:
    # inc y
    addi 1 r6 r6
    # reset x
    addi 0 r0 r5
    beq main r6 r3
    j loop

main:
    j main
