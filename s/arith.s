    addi 1 r0 r1 ; 4041
    addi 3 r0 r2 
    ssl r1 r2 r1
    addi 1 r0 r3
    ssl r3 r2 r3
    addi 1 r3 r3
    and r1 r3 r1
    not r3 r3
    addi 1 r3 r1
    halt