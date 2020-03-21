`include "defs.h"

module cpu(
    input CLK
);
  reg [`RegWidth-1:0] pc = 0;
  reg [`RegWidth-1:0] instr_mem [`InstrMemLen-1:0];

endmodule

module alu(
    input [`AluOpWidth-1:0] op,
    input [`RegWidth-1:0] reg1,
    input [`RegWidth-1:0] reg2,
    output reg [`RegWidth-1:0] regOut
);
    localparam OP_ADD = 0;
    localparam OP_SL = 1;

    always @*
    case (op)
      OP_ADD: regOut <= reg1 + reg2;
      OP_SL: regOut <= reg1 << reg2;
    endcase

endmodule

