`include "defs.vh"

`timescale 1 ns / 1 ps
module cpu_tb;

    logic CLK = 0, RST = 0;

    cpu cpu_comp(.CLK_50(CLK), .KEY0(RST));

    task step_cycles(integer num_cycles);
        repeat (num_cycles << 6) begin
            #10 CLK = 1;
            #10 CLK = 0;
        end
    endtask

    initial begin

        RST = 1; #10;
        RST = 0; #10;
        RST = 1; #10;
        cpu_comp.load_instr("as/halt.mem", 1); #10;
        `assert_eq(cpu_comp.pc, 0);
        `assert_eq(cpu_comp.halted, 1);
        step_cycles(1);
        `assert_eq(cpu_comp.pc, 0);
        `assert_eq(cpu_comp.halted, 1);

        cpu_comp.load_instr("as/add.mem", 6); #10;
        `assert_eq(cpu_comp.pc, 0);
        `assert_eq(cpu_comp.halted, 0);
        step_cycles(1);
        `assert_eq(cpu_comp.halted, 0);
        `assert_eq(cpu_comp.pc, 1);
        `assert_eq(cpu_comp.reg_file[1], 1);
        step_cycles(1);
        `assert_eq(cpu_comp.halted, 0);
        `assert_eq(cpu_comp.pc, 2);
        // $display("pc: %x; reg1: %x", 
        //     cpu_comp.pc,
        //     cpu_comp.reg_file[1]);
        `assert_eq(cpu_comp.reg_file[1], 1);
        step_cycles(1);
        `assert_eq(cpu_comp.reg_file[1], 2);
        step_cycles(1);
        `assert_eq(cpu_comp.reg_file[1], -16'd30);
        step_cycles(1);
        `assert_eq(cpu_comp.halted, 1);
        `assert_eq(cpu_comp.reg_file[1], 1);

        cpu_comp.load_instr("as/arith.mem", 10); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `assert_eq(cpu_comp.reg_file[1], -16'sd9);

        cpu_comp.load_instr("as/labels.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `assert_eq(cpu_comp.reg_file[2], 1);
        `assert_eq(cpu_comp.reg_file[3], 3);

        cpu_comp.load_instr("as/beq.mem", 11); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `assert_eq(cpu_comp.reg_file[0], 0);
        `assert_eq(cpu_comp.reg_file[1], 8);
        `assert_eq(cpu_comp.reg_file[2], 5);

        cpu_comp.load_instr("as/j.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `assert_eq(cpu_comp.reg_file[0], 0);
        `assert_eq(cpu_comp.reg_file[1], 1);

        cpu_comp.load_instr("as/data.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `assert_eq(cpu_comp.reg_file[0], 0);
        `assert_eq(cpu_comp.reg_file[1], 'h6001);
        `assert_eq(cpu_comp.mem[31], 'h6002);
    end
endmodule

