    addi 7 r0 r1
    addi 3 r0 r2
    addi 5 r0 r3
    beq x r0 r0
y:
    addi 1 r1 r1
x:
    addi 1 r2 r2
    beq end r2 r3
    beq y r0 r0
    addi 1 r2 r2
    addi 1 r3 r3
end:
    halt