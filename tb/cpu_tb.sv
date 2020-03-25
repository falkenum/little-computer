`include "defs.vh"

`timescale 1 ns / 1 ps
module cpu_tb;

    logic CLK = 0;

    cpu cpu_comp(CLK);

    initial begin
        // $display("instr: %X, r0: %b; r1: %b; r2: %b", 
        //     cpu_comp.instr,
        //     cpu_comp.reg_state[0], 
        //     cpu_comp.reg_state[1], 
        //     cpu_comp.reg_state[2]);
        cpu_comp.load_instr("as/halt.mem", 1); #10;
        `assert_eq(cpu_comp.pc, 0);
        `assert_eq(cpu_comp.halted, 1);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(cpu_comp.pc, 0);
        `assert_eq(cpu_comp.halted, 1);

        cpu_comp.load_instr("as/add.mem", 6); #10;
        `assert_eq(cpu_comp.pc, 0);
        `assert_eq(cpu_comp.halted, 0);
        `assert_eq(cpu_comp.reg_state[1],0);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(cpu_comp.halted, 0);
        `assert_eq(cpu_comp.pc, 1);
        `assert_eq(cpu_comp.reg_state[1], 1);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(cpu_comp.halted, 0);
        `assert_eq(cpu_comp.pc, 2);
        `assert_eq(cpu_comp.reg_state[1], 1);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(cpu_comp.reg_state[1], 2);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(cpu_comp.reg_state[1], -16'd30);
        CLK = 1; #10;
        CLK = 0; #10;
        `assert_eq(cpu_comp.halted, 1);
        `assert_eq(cpu_comp.reg_state[1], 1);

        cpu_comp.load_instr("as/arith.mem", 10); #10;
        while (cpu_comp.halted === 0) begin
            CLK = 1; #10;
            CLK = 0; #10;
        end
        `assert_eq(cpu_comp.reg_state[1], -16'sd9);

        cpu_comp.load_instr("as/labels.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            CLK = 1; #10;
            CLK = 0; #10;
        end
        `assert_eq(cpu_comp.reg_state[2], 1);
        `assert_eq(cpu_comp.reg_state[3], 3);

        cpu_comp.load_instr("as/beq.mem", 11); #10;
        while (cpu_comp.halted === 0) begin
            CLK = 1; #10;
            CLK = 0; #10;
        end
        `assert_eq(cpu_comp.reg_state[0], 0);
        `assert_eq(cpu_comp.reg_state[1], 8);
        `assert_eq(cpu_comp.reg_state[2], 5);

        cpu_comp.load_instr("as/j.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            CLK = 1; #10;
            CLK = 0; #10;
        end
        `assert_eq(cpu_comp.reg_state[0], 0);
        `assert_eq(cpu_comp.reg_state[1], 1);
    end
endmodule

