    j start
subr:
    push r4
    push r5
    push r6
    addi 4 r0 r4
    addi 5 r0 r5
    addi 6 r0 r6
    pop r6
    pop r5
    pop r4
    rts

start:
    addi 1 r0 r4
    addi 2 r0 r5
    addi 3 r0 r6
    jl subr
    halt

