`include "defs.vh"

`timescale 1 ns / 1 ps
module lc_tb;

    logic CLK = 0, RST = 1;
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
        .MAX10_CLK1_50(CLK), 
        .KEY({1'b1, RST}), 
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
            #10 CLK = 1;
            #10 CLK = 0;
        end
    end

    task load_instr(string filename, integer length);
        $readmemh(filename, sdram_c.mem, 0, length - 1);
        RST = 0; #SYS_CYCLE;

        RST = 1; #SYS_CYCLE;
        while (lc_c.state != lc_c.STATE_RUNNING) begin
            #SYS_CYCLE;
        end
    endtask

    initial begin
        RST = 0; #SYS_CYCLE;
        RST = 1; #SYS_CYCLE;
        `ASSERT_EQ(lc_c.dram_ready, 0);
        `ASSERT_EQ(lc_c.sdram_ctl_c.mem_ready, 0);

        load_instr("as/halt.mem", 1);
        `ASSERT_EQ(lc_c.dram_ready, 1);
        `ASSERT_EQ(lc_c.pc, 0);

        #SYS_CYCLE;
        `ASSERT_EQ(lc_c.mem_map_c.state, lc_c.mem_map_c.STATE_FETCH_INSTR);
        while (lc_c.mem_map_c.state != lc_c.mem_map_c.STATE_IDLE) begin
            #SYS_CYCLE;
        end
        `ASSERT_EQ(lc_c.instr, 'he000);

        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.instr, 'he000);

        `ASSERT_EQ(lc_c.cpu_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.halted, 1);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.pc, 0);
        `ASSERT_EQ(lc_c.cpu_c.halted, 1);

        load_instr("as/add.mem", 6);
        `ASSERT_EQ(lc_c.pc, 0);
        `ASSERT_EQ(lc_c.mem_map_c.state, lc_c.mem_map_c.STATE_IDLE);
        `ASSERT_EQ(lc_c.sdram_ctl_c.state, lc_c.sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        `ASSERT_EQ(lc_c.mem_map_c.state, lc_c.mem_map_c.STATE_FETCH_INSTR);
        #SYS_CYCLE;
        `ASSERT_EQ(lc_c.mem_map_c.state, lc_c.mem_map_c.STATE_WAIT);
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(lc_c.mem_map_c.state, lc_c.mem_map_c.STATE_INSTR_OUT);
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(lc_c.mem_map_c.state, lc_c.mem_map_c.STATE_DATA_OUT);
        #SYS_CYCLE;

        `ASSERT_EQ(lc_c.instr, 'h4041);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 1);
        `ASSERT_EQ(sdram_c.mem[1], 'h0009);
        // $display("%x", lc_c.instr);
        `ASSERT_EQ(lc_c.instr, 'h0009);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 1);
        `ASSERT_EQ(lc_c.cpu_c.halted, 0);
        `ASSERT_EQ(lc_c.cpu_c.pc, 2);
        `ASSERT_EQ(lc_c.instr, 'h0049);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.halted, 0);
        `ASSERT_EQ(lc_c.cpu_c.pc, 3);

        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 2);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], -16'd30);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 1);
        `ASSERT_EQ(lc_c.cpu_c.halted, 1);

        load_instr("as/arith.mem", 10);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], -16'sd9);

        load_instr("as/labels.mem", 4);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[3], 3);

        load_instr("as/beq.mem", 11);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 8);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 5);

        load_instr("as/j.mem", 4);
        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 1);

        load_instr("as/data.mem", 4);
        while (lc_c.cpu_c.halted === 0) #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'h6001);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 'h6002);
        `ASSERT_EQ(lc_c.sdram_c.mem[31], 'h6002);

        #CPU_CYCLE;

        `ASSERT_EQ(lc_c.state, lc_c.STATE_RUNNING);
        
        load_instr("as/data2.mem", 7);

        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'h1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 'h4044);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[3], 'h4042);
        `ASSERT_EQ(lc_c.sdram_c.mem[17], 'h4042);

        load_instr("as/subroutine.mem", 6);

        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[0], 0);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'h1);
        `ASSERT_EQ(lc_c.cpu_c.lr, 'h5);

        load_instr("as/stack.mem", 16);

        while (lc_c.cpu_c.halted === 0) begin
            #CPU_CYCLE;
        end
        `ASSERT_EQ(lc_c.cpu_c.reg_file[4], 'h1);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[5], 'h2);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[6], 'h3);
        $finish;
    end
endmodule

