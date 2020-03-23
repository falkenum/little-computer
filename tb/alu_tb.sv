`include "defs.vh"

`timescale 1 ns / 1 ps
module alu_tb;
    reg [`AluOpWidth-1:0] op = `ALU_OP_ADD;
    reg [`RegWidth-1:0] rs = 0;
    reg [`RegWidth-1:0] rt = 0;
    wire [`RegWidth-1:0] rd;

    alu alu_comp(op, rs, rt, rd);

    initial begin
        rs = 2; #10;
        `assert_eq(rd, 2);
        rt = 3; #10;
        `assert_eq(rd, 5);
        op = `ALU_OP_LSL; #10;
        `assert_eq(rd, 'h10);
        rt = 0; #10;
        `assert_eq(rd, 'h2);
    end
endmodule
