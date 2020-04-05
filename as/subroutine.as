    j start
inc1:
    addi 1 r1 r1
    rts
start:
    addi 0 r0 r1
    jl inc1
    halt