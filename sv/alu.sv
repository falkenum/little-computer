`include "defs.h"

module alu(
    input [`AluOpWidth-1:0] op,
    input [`RegWidth-1:0] reg1,
    input [`RegWidth-1:0] reg2,
    output logic [`RegWidth-1:0] regOut
);

    always @*
    case (op)
        `ALU_OP_ADD: regOut <= reg1 + reg2;
        `ALU_OP_SL: regOut <= reg1 << reg2;
    endcase

endmodule
