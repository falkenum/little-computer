`include "defs.vh"

`timescale 1 ns / 1 ps
module alu_tb;
    reg [`AluOpWidth-1:0] op = `ALU_OP_ADD;
    reg [`RegWidth-1:0] rs_val = 0;
    reg [`RegWidth-1:0] rt_val = 0;
    wire [`RegWidth-1:0] result;

    alu alu_comp(op, rs_val, rt_val, result);

    initial begin
        rs_val = 2; #10;
        `assert_eq(result, 2);
        rt_val = 3; #10;
        `assert_eq(result, 5);
        op = `ALU_OP_LSL; #10;
        `assert_eq(result, 'h10);
        rt_val = 0; #10;
        `assert_eq(result, 'h2);

        op = `ALU_OP_AND; #10;
        `assert_eq(result, 0);
        op = `ALU_OP_NOT; #10;
        `assert_eq(result, ~(16'd2));
        $finish;
    end
endmodule
