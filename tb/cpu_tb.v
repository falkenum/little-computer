`include "defs.svh"

`timescale 1 ns / 1 ps
module cpu_tb;
    reg CLK = 0;
    reg [`NumRegsWidth:0] reg_num;
    
    wire [`RegWidth-1:0] debug_reg_state [`NumRegs];
    wire halted;
    cpu cpu_comp(CLK, debug_reg_state, halted);

    initial begin
        while (!halted) begin
            CLK = 1; #20;
            CLK = 0; #20;

			// $display("registers in hex: ");
			// for (reg_num = 0; reg_num < `NumRegs; reg_num++)
			//     $display("reg %d: %x", reg_num, debug_reg_state[reg_num]);
        end

       
    end
endmodule
