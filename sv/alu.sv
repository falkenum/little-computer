`include "defs.vh"

module alu(
    input [`AluOpWidth-1:0] op,
    input [`RegWidth-1:0] rs,
    input [`RegWidth-1:0] rt,
    output logic [`RegWidth-1:0] rd
);

    always @*
    case (op)
        `ALU_OP_ADD: rd <= rs + rt;
        `ALU_OP_LSL: rd <= rs << rt;
        `ALU_OP_AND: rd <= rs & rt;
        `ALU_OP_NOT: rd <= ~rs;
        default: rd <= 0;
    endcase

endmodule
