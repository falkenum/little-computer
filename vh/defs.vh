`ifndef DEFS_VH
`define DEFS_VH

`define AluOpWidth 2
`define RegWidth 16
`define NumRegsWidth 3
`define NumRegs (1 << `NumRegsWidth)
`define InstrWidth 16
`define ImmWidth 6
`define JImmWidth 12
`define InstrMemLen (1 << `RegWidth)
`define OpWidth 4

`define OP_ADD 4'h0
`define OP_LSL 4'h1
`define OP_AND 4'h2
`define OP_NOT 4'h3

`define OP_ADDI 4'h4
`define OP_BEQ 4'h5
`define OP_LW 4'h6
`define OP_SW 4'h7
`define OP_J 4'h8

`define OP_HALT 4'hE
`define OP_NOP 4'hF

`define ALU_OP_ADD 'h0
`define ALU_OP_LSL 'h1
`define ALU_OP_AND 'h2
`define ALU_OP_NOT 'h3

`define assert_eq(first, second) if (first !== second) $display("ASSERTION FAILED: line %d", `__LINE__)
`define MAX_PATH_LEN (1<<8)

`endif