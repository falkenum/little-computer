
`include "defs.vh"

`timescale 1 ns / 1 ps
module lc_tb;

    logic CLK = 0, RST = 0;

    little_computer lc_c(.MAX10_CLK1_50(CLK), .KEY({1'b1, RST}), .SW(10'b0));

    task step_cycles(integer num_cycles);
        repeat (num_cycles * (1 << `CPU_CLK_DIV_WIDTH)) begin
            CLK = 1; #10;
            CLK = 0; #10;
        end
        // $display("pc: %x", lc_c.pc);
    endtask

    task load_instr(string filename, integer length);
        $readmemh(filename, lc_c.cpu_mem_c.mem, 0, length - 1);
        RST = 1; #20;
        RST = 0; #20;

        // need to wait for cpu to reset
        step_cycles(1);
        RST = 1; #20;
    endtask

    initial begin

        load_instr("as/add.mem", 6);
        `ASSERT_EQ(lc_c.cpu_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.instr, 'h4041);
        `ASSERT_EQ(lc_c.cpu_c.halted, 0);
    end
endmodule

