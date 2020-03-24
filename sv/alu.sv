`include "defs.vh"

module alu(
    input [`AluOpWidth-1:0] op,
    input [`RegWidth-1:0] rs_val,
    input [`RegWidth-1:0] rt_val,
    output logic [`RegWidth-1:0] result
);

    always @*
    case (op)
        `ALU_OP_ADD: result <= rs_val + rt_val;
        `ALU_OP_LSL: result <= rs_val << rt_val;
        `ALU_OP_AND: result <= rs_val & rt_val;
        `ALU_OP_NOT: result <= ~rs_val;
        default: result <= 0;
    endcase

endmodule
