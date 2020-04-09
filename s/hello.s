    j start
txrdy_addr:
    .word F80A
tx_addr:
    .word F80B
msg:
    .string "hello world\n"
start:
    # load msg addr into r1
    addi msg r0 r1

    # load tx_addr into r2
    lw tx_addr r0 r2

    # load txrdy_addr into r5
    lw txrdy_addr r0 r5

    # load 1 into r4, for comparison
    addi 1 r0 r4

strloop:
    # load char into r3
    lw 0 r1 r3

    # if null char, go to the end
    beq end r0 r3

    # store char at tx_addr
    sw 0 r2 r3

    # we need to wait until txrdy goes low and then high again

txrdy_wait_for_low:
    # load txrdy value into r3
    lw 0 r5 r3
    beq txrdy_is_low r3 r0
    j txrdy_wait_for_low

txrdy_is_low:
    lw 0 r5 r3
    beq txrdy_is_high r3 r4
    j txrdy_is_low

txrdy_is_high:
    # inc char ptr
    addi 1 r1 r1
    j strloop

end:
    halt
