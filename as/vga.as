    j start
vga_write_addr:
    .word F80C
start:
    # store the write addr into r1
    lw vga_write_addr r0 r1

    addi 31 r0 r2
    addi -1 r0 r3

    # x write
    sw 0 r1 r2
    # y write
    sw 0 r1 r2
    # bgr write (white)
    sw 0 r1 r3

    addi 1 r2 r2
    # x write
    sw 0 r1 r2
    # y write
    sw 0 r1 r2
    addi -1 r0 r3
    # bgr write (white)
    sw 0 r1 r3
    halt