`include "defs.vh"

module control(
    input [`InstrWidth-1:0] instr,
    output halted,
    output reg_write_en,
    output itype,
    output [`AluOpWidth-1:0] alu_op
);
    wire [`OpWidth-1:0] op;
    assign op = instr[`InstrWidth-1:`InstrWidth-`OpWidth];
    
    assign halted = op == `OP_HALT;
    assign itype = op[`OpWidth-1:`OpWidth-2] == 2'b01;
    assign reg_write_en = op[`OpWidth-1] == 'b0;
    assign alu_op = op[`OpWidth-3:`OpWidth-4];

    // always@(op) $display("op: %x; halted: %b", op, halted);
endmodule
