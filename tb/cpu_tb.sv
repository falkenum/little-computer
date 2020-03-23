`include "defs.vh"

`timescale 1 ns / 1 ps
module cpu_tb;
    logic CLK = 0;

    wire halted;
    wire [`RegWidth-1:0] reg_state [`NumRegs];
    wire [`RegWidth-1:0] pc;
    wire [`InstrWidth-1:0] instr;

    cpu cpu_comp(CLK, halted, reg_state, pc, instr);

    initial begin
        cpu_comp.load_instr("as/halt.mem", 1); #10;
        `assert_eq(pc, 0);
        `assert_eq(halted, 1);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(pc, 0);
        `assert_eq(halted, 1);

        cpu_comp.load_instr("as/add.mem", 4); #10;
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

        cpu_comp.load_instr("as/arith.mem", 8); #10;
        $display("r1: %b", reg_state[1]);
        while (halted === 0) begin
            CLK = 1; #10;
            CLK = 0; #10;
            $display("r1: %b", reg_state[1]);
        end
        `assert_eq(reg_state[1], -16'sd9);
    end
endmodule

