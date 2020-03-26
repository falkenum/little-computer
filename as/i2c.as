    j start
i2c_addr:
    .word 001D
scl_addr:
    .word 0FF0
sda_addr:
    .word 0FF1
sda_clear_addr:
    .word 0FF2
start:
    lw scl_addr r0 r1
    addi 1 r0 r1
    nop
    nop
    addi 0 r0 r1
    halt
