    j start
led_addr:
    .word F800
start:
    lw led_addr r0 r1
    addi 1 r0 r2
    addi 0 r0 r3
loop:
    addi 1 r3 r3
    beq toggle r3 r0
    j loop
toggle:
    not r2 r2
    sw 0 r1 r2
    j loop
