    j start
i2c_addr:
    .word 001D
scl_addr:
    .word F0
sda_addr:
    .word F1
sda_clear_addr:
    .word F2
start:
    lw scl_addr r0 r1
    addi 1 r0 r2
    sw 0 r1 r2
    nop
    nop
    nop
    nop
    sw 0 r1 r0
    nop
    nop
    nop
    nop
    j start
