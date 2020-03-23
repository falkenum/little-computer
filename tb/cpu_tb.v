`include "defs.svh"

`timescale 1 ns / 1 ps
module cpu_tb;
	logic CLK = 0;

	wire halted;
	wire [`RegWidth-1:0] reg_state [`NumRegs];
	wire [`RegWidth-1:0] pc;
	logic [`NumRegsWidth:0] reg_num;


	cpu cpu_comp(CLK, halted, reg_state, pc);

    initial begin
		cpu_comp.load_instr("mem/halt.mem", 1); #10;
		`assert_eq(pc, 0);
		`assert_eq(halted, 1);
		CLK = 1; #10;
		CLK = 0; #10;
		`assert_eq(pc, 0);
		`assert_eq(halted, 1);

		cpu_comp.load_instr("mem/add.mem", 4); #10;
		`assert_eq(pc, 0);
		`assert_eq(halted, 0);
		`assert_eq(reg_state[0],0);
		CLK = 1; #10;
		CLK = 0; #10;
		`assert_eq(halted, 0);
		`assert_eq(pc, 1);
		`assert_eq(reg_state[0], 1);
		CLK = 1; #10;
		CLK = 0; #10;
		`assert_eq(halted, 0);
		`assert_eq(pc, 2);
		`assert_eq(reg_state[0], 1);
		CLK = 1; #10;
		CLK = 0; #10;
		`assert_eq(halted, 1);
		`assert_eq(pc, 3);
		`assert_eq(reg_state[0], 2);
	   
	   	   
        while (!halted) begin
            CLK = 1; #10;
            CLK = 0; #10;
			// $display("pc: %x", pc);
			// for (reg_num = 0; reg_num < `NumRegs; reg_num++)
			// 	$display("reg %d: %x", reg_num, reg_state[reg_num]);
        end
    end
endmodule

