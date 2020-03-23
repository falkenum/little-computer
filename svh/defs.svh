`define AluOpWidth 2
`define RegWidth 16
`define NumRegsWidth 4
`define NumRegs 1 << `NumRegsWidth
`define InstrWidth 16
`define OpWidth 4
`define ALU_OP_ADD 0
`define ALU_OP_SL 1
`define OP_ADD 4'h0
`define OP_LSL 4'h1
`define OP_HALT 4'hE
`define OP_NOP 4'hF
`define INSTR_MEM "mem/add.mem"
`define assert(cond) if (!(cond)) $display("ASSERTION FAILED: line %d", `__LINE__)

