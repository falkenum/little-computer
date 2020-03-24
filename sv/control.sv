`include "defs.vh"

module control(
    input [`InstrWidth-1:0] instr,
    output halted,
    output reg_write_en,
    output alu_use_imm,
    output is_beq,
    output [`AluOpWidth-1:0] alu_op
);
    wire [`OpWidth-1:0] op;
    wire itype;
    assign op = instr[`InstrWidth-1:`InstrWidth-`OpWidth];
    
    assign is_beq = op == `OP_BEQ;
    assign halted = op == `OP_HALT;
    assign itype = op[`OpWidth-1:`OpWidth-2] == 'b01;
    assign alu_use_imm = itype & op != `OP_BEQ;
    assign reg_write_en = op[`OpWidth-1:`OpWidth-2] == 'b00 | op == `OP_ADDI | op == `OP_LW;
    assign alu_op = op[`OpWidth-3:`OpWidth-4];

    // always@(op) $display("op: %x; halted: %b", op, halted);
endmodule
