    j start
msg:
    .word 0074
tx_addr:
    .word F80B
start:
    # load msg into r1
    lw msg r0 r1
    # load tx_addr into r2
    lw tx_addr r0 r2
    # store msg at tx_addr
    sw 0 r2 r1
    halt
