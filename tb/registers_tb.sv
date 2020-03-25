`include "defs.vh"

`timescale 1 ns / 1 ps
module registers_tb;
    reg [`NumRegsWidth-1:0] rs = 0, rt = 0, rd = 0; 
    reg [`RegWidth-1:0] reg_in = 0;
    reg reg_write_en = 0;
    reg CLK = 0;
    reg RST = 0;
    wire [`RegWidth-1:0] rs_val, rt_val, rd_val;
    wire [`RegWidth-1:0] reg_state [`NumRegs];

    registers registers_comp(rs, rt, rd, reg_in, reg_write_en, CLK, RST, rs_val, rt_val, rd_val, reg_state);

    initial begin

        static integer i = 0; #10;
        RST = 1; #10;
        RST = 0; #10;
        RST = 1; #10;
       
        reg_in = 1; #10;
        CLK = 1; #20;
        CLK = 0; #20;

        rs = 0;
        `assert_eq(rs_val, 0);

        reg_write_en = 1;
       
        CLK = 1; #20;
        CLK = 0; #20;

        `assert_eq(rs_val, 1);

    end
endmodule
