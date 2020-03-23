`include "defs.svh"

module control(
    input [`InstrWidth-1:0] instr,
    output halted,
    output reg_write_en,
    output [`AluOpWidth-1:0] alu_op
);
    wire [`OpWidth-1:0] op;
    assign op = instr[`InstrWidth-1:`InstrWidth-`OpWidth];
    
    assign halted = op == `OP_HALT;
    assign reg_write_en = instr[`OpWidth-1:`OpWidth-2] == 2'b0;
    assign alu_op = instr[`OpWidth-3:`OpWidth-4];
   
   
endmodule
