`include "defs.vh"

`timescale 1 ns / 1 ps
module lc_tb;

    logic clk = 0, rst = 1;
	wire		    [12:0]		addr;
	wire		     [1:0]		ba;
	wire		          		ras_n;
	wire		          		cas_n;
	wire		          		we_n;
	wire		          		dram_clk;
	wire 		    [15:0]		dq;

    localparam SYS_CYCLE = 20;
    localparam CPU_CYCLE = 64*SYS_CYCLE;

    
    sdram_sim sdram_c(
        .addr(addr),
        .ba(ba),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .clk(dram_clk),
        .dq(dq)
    );
    little_computer lc_c(
        .MAX10_CLK1_50(clk), 
        .KEY({1'b1, rst}), 
        .SW(10'b0),
        .DRAM_ADDR(addr),
        .DRAM_BA(ba),
        .DRAM_RAS_N(ras_n),
        .DRAM_CAS_N(cas_n),
        .DRAM_WE_N(we_n),
        .DRAM_CLK(dram_clk),
        .DRAM_DQ(dq)
    );

    initial begin
        forever begin
            clk = 1; #10;
            clk = 0; #10;
        end
    end

    task load_instr(string filename, integer length);
        $readmemh(filename, sdram_c.mem, 0, length - 1);
        rst = 0; #SYS_CYCLE;

        rst = 1; #SYS_CYCLE;
        while (lc_c.state != lc_c.STATE_RUNNING) begin
            #SYS_CYCLE;
        end
    endtask

    initial begin
        rst = 0; #SYS_CYCLE;
        rst = 1; #SYS_CYCLE;

        load_instr("s/halt.mem", 1);
        `ASSERT_EQ(lc_c.dram_ready, 1);

        // $display("begin at time ", $time);
        #CPU_CYCLE;
        
        `ASSERT_EQ(lc_c.instr, 'he000);
        // $display("assertion at time ", $time);
        $display("%x", lc_c.instr);

        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.instr, 'he000);

        `ASSERT_EQ(lc_c.cpu_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.halted, 1);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.halted, 1);

        load_instr("s/add.mem", 6);

        $display("mem map state is %d at time %d", lc_c.mem_map_c.state, $time);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.instr, 'h4041);
        `ASSERT_EQ(lc_c.pc, 0);
        $display("mem map state is %d at time %d", lc_c.mem_map_c.state, $time);
        #SYS_CYCLE;
        #CPU_CYCLE;
        $display("mem map state is %d at time %d", lc_c.mem_map_c.state, $time);
        `ASSERT_EQ(lc_c.instr, 'h0009);
        $display("%x", lc_c.instr);
        $finish;
        `ASSERT_EQ(lc_c.pc, 1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 1);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 3);
        `ASSERT_EQ(lc_c.cpu_c.halted, 0);
        `ASSERT_EQ(lc_c.instr, 'h0049);

        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 2);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 4);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], -16'd30);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 5);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 1);
        `ASSERT_EQ(lc_c.cpu_c.halted, 1);

        load_instr("s/arith.mem", 10);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], -16'sd9);

        load_instr("s/labels.mem", 4);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[3], 3);

        load_instr("s/beq.mem", 11);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 8);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 5);

        load_instr("s/j.mem", 4);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 1);

        load_instr("s/data.mem", 4);
        while (lc_c.cpu_c.halted === 0) #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'h6001);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 'h6002);
        `ASSERT_EQ(lc_c.sdram_c.mem[31], 'h6002);

        #CPU_CYCLE;

        `ASSERT_EQ(lc_c.state, lc_c.STATE_RUNNING);
        
        load_instr("s/data2.mem", 7);

        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'h1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 'h4044);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[3], 'h4042);
        `ASSERT_EQ(lc_c.sdram_c.mem[17], 'h4042);

        load_instr("s/subroutine.mem", 6);

        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'h1);
        `ASSERT_EQ(lc_c.cpu_c.lr, 'h5);

        load_instr("s/stack.mem", 16);

        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[4], 'h1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[5], 'h2);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[6], 'h3);
        $finish;
    end
endmodule

