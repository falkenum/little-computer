`include "defs.svh"

`timescale 1 ns / 1 ps
module registers_tb;
    reg [`NumRegsWidth-1:0] rs = 0; 
    reg [`NumRegsWidth-1:0] rt = 0; 
    reg [`NumRegsWidth-1:0] rd = 0; 
    reg [`RegWidth-1:0] reg_in = 0;
    reg reg_write_en = 0;
    reg CLK = 0;
    wire [`RegWidth-1:0] rs_val;
    wire [`RegWidth-1:0] rt_val;
    wire [`RegWidth-1:0] debug_reg_state [`NumRegs];

    registers registers_comp(rs, rt, rd, reg_in, reg_write_en, CLK, rs_val, rt_val, debug_reg_state);

    initial begin
		static integer i = 0; 
		for(i=0; i < `NumRegs; i++) begin
			rs = i;
			rt = i;
			`assert(rs_val == 0);
			`assert(rt_val == 0);
		end

		reg_in = 1;
		CLK = 1; #20;
		CLK = 0; #20;

		rs = 0;
		`assert(rs_val == 0);

		reg_write_en = 1;
	   
		CLK = 1; #20;
		CLK = 0; #20;

		`assert(rs_val == 1);

		rt = 1;
		`assert(rt_val == 0);
    end
endmodule
