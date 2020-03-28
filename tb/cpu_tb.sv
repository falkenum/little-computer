`include "defs.vh"

`timescale 1 ns / 1 ps
module cpu_tb;

    logic CLK = 0, RST = 0;

    cpu cpu_comp(.MAX10_CLK1_50(CLK), .KEY({1'b1, RST}), .SW(10'b0));

    task step_cycles(integer num_cycles);
        repeat (num_cycles << `CPU_CLK_DIV_WIDTH) begin
            #10 CLK = 1;
            #10 CLK = 0;
        end
        // $display("pc: %x", cpu_comp.pc);
    endtask

    task load_instr(string filename, integer length);
        $readmemh(filename, cpu_comp.memory_comp.mem, 0, length - 1);
        cpu_comp.pc = 0;
        // $display("loaded %s", filename);
        // $display("pc: %x", cpu_comp.pc);
    endtask

    initial begin

        RST = 1; #10;
        RST = 0; #10;
        RST = 1; #10;
        load_instr("as/halt.mem", 1); #10;
        `ASSERT_EQ(cpu_comp.pc, 0);
        `ASSERT_EQ(cpu_comp.halted, 1);
        step_cycles(1);
        `ASSERT_EQ(cpu_comp.pc, 0);
        `ASSERT_EQ(cpu_comp.halted, 1);

        load_instr("as/add.mem", 6); #10;
        `ASSERT_EQ(cpu_comp.pc, 0);
        `ASSERT_EQ(cpu_comp.halted, 0);
        step_cycles(1);
        `ASSERT_EQ(cpu_comp.halted, 0);
        `ASSERT_EQ(cpu_comp.pc, 1);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 1);
        step_cycles(1);
        `ASSERT_EQ(cpu_comp.halted, 0);
        `ASSERT_EQ(cpu_comp.pc, 2);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 1);
        step_cycles(1);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 2);
        step_cycles(1);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], -16'd30);
        step_cycles(1);
        `ASSERT_EQ(cpu_comp.halted, 1);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 1);

        load_instr("as/arith.mem", 10); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], -16'sd9);
        // $display("reg1: %x", cpu_comp.registers_comp.reg_file[1]);

        load_instr("as/labels.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[2], 1);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[3], 3);

        load_instr("as/beq.mem", 11); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[0], 0);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 8);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[2], 5);

        load_instr("as/j.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
        end
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[0], 0);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 1);

        load_instr("as/data.mem", 4); #10;
        while (cpu_comp.halted === 0) begin
            step_cycles(1);
            // $display("stepped 1 cycle, pc: %x; reg1: %x; reg2: %x, mem[31]: %x; is_sw: %b", 
            //     cpu_comp.pc,
            //     cpu_comp.registers_comp.reg_file[1],
            //     cpu_comp.registers_comp.reg_file[2],
            //     cpu_comp.memory_comp.mem[31],
            //     cpu_comp.is_sw
            // );
        end
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[0], 0);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[1], 'h6001);
        `ASSERT_EQ(cpu_comp.registers_comp.reg_file[2], 'h6002);
        `ASSERT_EQ(cpu_comp.memory_comp.mem[31], 'h6002);
    end
endmodule

