`include "defs.svh"
`timescale 1 ns / 1 ps

module control_tb;
	reg [`InstrWidth-1:0] instr;
    output halted;
    output reg_write_en;
	output [`AluOpWidth-1:0] alu_op;
   
    control control_comp(instr, halted, reg_write_en, alu_op);

    initial begin
		instr = {`OP_HALT, 12'b0};
		`assert_eq(halted, 1);
		`assert_eq(reg_write_en, 0);
		instr = {`OP_ADD, 12'b0};
		`assert_eq(halted, 0);
		`assert_eq(reg_write_en, 1);
    end
endmodule
