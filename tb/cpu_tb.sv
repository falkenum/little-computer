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

        cpu_comp.load_instr("as/add.mem", 6); #10;
        `assert_eq(pc, 0);
        `assert_eq(halted, 0);
        `assert_eq(reg_state[1],0);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(halted, 0);
        `assert_eq(pc, 1);
        `assert_eq(reg_state[1], 1);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(halted, 0);
        `assert_eq(pc, 2);
        `assert_eq(reg_state[1], 1);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(reg_state[1], 2);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(reg_state[1], -16'd30);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(halted, 1);
        `assert_eq(reg_state[1], 1);
        // $display(reg_state[1]);

        cpu_comp.load_instr("as/arith.mem", 10); #10;
        // $display("pc: %x; instr: %x; r1: %b; r2: %b; r3: %b", 
        //     pc, instr, reg_state[1], reg_state[2], reg_state[3]);
        while (halted === 0) begin
            CLK = 1; #10;
            CLK = 0; #10;
        end
        `assert_eq(reg_state[1], -16'sd9);
    end
endmodule

