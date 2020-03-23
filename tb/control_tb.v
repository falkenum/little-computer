`include "defs.svh"
`timescale 1 ns / 1 ps

module control_tb;
	reg [`InstrWidth-1:0] instr;
    wire halted;
    wire reg_write_en;
	wire itype;
	wire [`AluOpWidth-1:0] alu_op;
   
    control control_comp(instr, halted, reg_write_en, itype, alu_op);

    initial begin
		instr = {`OP_HALT, 12'b0}; #10;
		`assert_eq(halted, 1);
		`assert_eq(reg_write_en, 0);
		`assert_eq(itype, 0);
		instr = {`OP_ADD, 12'b0}; #10;
		`assert_eq(halted, 0);
		`assert_eq(reg_write_en, 1);
		`assert_eq(alu_op, 0);
		`assert_eq(itype, 0);
		instr = {`OP_LSL, 12'b0}; #10;
		`assert_eq(halted, 0);
		`assert_eq(reg_write_en, 1);
		`assert_eq(alu_op, 1);
		`assert_eq(itype, 0);
		instr = {`OP_ADDI, 12'b0}; #10;
		`assert_eq(halted, 0);
		`assert_eq(reg_write_en, 1);
		`assert_eq(alu_op, 0);
		`assert_eq(itype, 1);
    end
endmodule
