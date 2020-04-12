addi 1 r0 r1
lw 0 r0 r2 ;r2: 4041
add r1 r2 r3 ;r3: 4042
sw 17 r0 r3 ; mem[17]: 4042
lw 16 r1 r2 ; r2: 4042
addi 2 r2 r2 ; r2: 4044
halt