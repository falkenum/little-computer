`include "defs.h"

`timescale 1 ns / 1 ps
module alu_tb;
    reg [`AluOpWidth-1:0] op = 0;
    reg [`RegWidth-1:0] reg1 = 0;
    reg [`RegWidth-1:0] reg2 = 0;
	wire [`RegWidth-1:0] regOut;

    alu alu_comp(op, reg1, reg2, regOut);

    initial begin
		reg1 = 2; #10;
        if (regOut != 2) $display("addition failed");
		reg2 = 3; #10;
        if (regOut != 5) $display("addition failed");
        op = `ALU_OP_SL;
        if (regOut != 'h40) $display("shift left failed");
        $display("%x", regOut);
       
    end
endmodule
