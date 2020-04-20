# Introduction
This project is an implementation of a 16-bit single cycle CPU along with drivers for SDRAM, UART, and VGA. It is synthesised to a DE10-Lite development board which features an Altera MAX10 FPGA. The primary goal of this project is to be able to play Snake on a computer system designed from the ground up in Verilog. The code for Snake is located at s/snake.s. 

# Demo

<a href="http://www.youtube.com/watch?feature=player_embedded&v=7886ck-wabw
" target="_blank"><img src="http://img.youtube.com/vi/7886ck-wabw/0.jpg" 
alt="IMAGE ALT TEXT HERE" width="240" height="180" border="10" /></a>

# The ISA
Instruction | 4-bit opcode | Info
--- | --- | ---
add | 0x0 | add 
ssl | 0x1 | shift left
and | 0x2 | and
not | 0x3 | not
addi | 0x4 | add immediate
beq | 0x5 | branch on equals
lw | 0x6 | load word (16 bits)
sw | 0x7 | store word
j | 0x8 | jump
jl | 0x9 | jump and link pc+1
rts | 0xA | return from subroutine
push | 0xB | push to stack (Top is 0x47FF, grows downwards)
pop | 0xC | pop from stack
blt | 0xD | branch on less than
halt | 0xE | stops program execution
nop | 0xF | no operation

# The Setup
