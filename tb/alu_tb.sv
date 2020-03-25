`include "defs.vh"

`timescale 1 ns / 1 ps
module alu_tb;
    reg [`ALU_OP_WIDTH-1:0] op = `ALU_OP_ADD;
    reg [`REG_WIDTH-1:0] rs_val = 0;
    reg [`REG_WIDTH-1:0] rt_val = 0;
    wire [`REG_WIDTH-1:0] result;

    alu alu_comp(op, rs_val, rt_val, result);

    initial begin
        rs_val = 2; #10;
        `ASSERT_EQ(result, 2);
        rt_val = 3; #10;
        `ASSERT_EQ(result, 5);
        op = `ALU_OP_LSL; #10;
        `ASSERT_EQ(result, 'h10);
        rt_val = 0; #10;
        `ASSERT_EQ(result, 'h2);

        op = `ALU_OP_AND; #10;
        `ASSERT_EQ(result, 0);
        op = `ALU_OP_NOT; #10;
        `ASSERT_EQ(result, ~(16'd2));
    end
endmodule
