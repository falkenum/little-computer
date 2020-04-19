`include "defs.vh"

module alu(
    input [`ALU_OP_WIDTH-1:0] op,
    input [`WORD_WIDTH-1:0] rs_val,
    input [`WORD_WIDTH-1:0] rt_val,
    output logic [`WORD_WIDTH-1:0] result
);

    always @* begin
    case (op)
        `ALU_OP_ADD: result <= rs_val + rt_val;
        // signed shift left: if negative shift amt, shift right
        `ALU_OP_SSL: result <= (rt_val[15] == 1'b0) ? rs_val << rt_val : rs_val >> (~rt_val + 16'b1);
        `ALU_OP_AND: result <= rs_val & rt_val;
        `ALU_OP_NOT: result <= ~rs_val;
        default: result <= 0;
    endcase
    end

endmodule
