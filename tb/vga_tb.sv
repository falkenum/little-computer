`include "defs.vh"

`timescale 1 ns/ 1 ps
module vga_tb;
    reg clk = 0, rst = 1;
    reg [31:0][11:0] mem_bgr_buf = 0;
	wire		    [12:0]		addr;
	wire		     [1:0]		ba;
	wire		          		ras_n;
	wire		          		cas_n;
	wire		          		we_n;
	wire		          		dram_clk;
	wire 		    [15:0]		dq;

    localparam SYS_CYCLE = 20;
    localparam CPU_CYCLE = 64*SYS_CYCLE;


    task load_instr(string filename, integer length);
        $readmemh(filename, sdram_c.mem, 0, length - 1);
        rst = 0; #SYS_CYCLE;

        rst = 1; #SYS_CYCLE;
        while (lc_c.state != lc_c.STATE_RUNNING) begin
            #SYS_CYCLE;
        end
    endtask

    
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
            #10 clk = 1;
            #10 clk = 0;
        end
    end

    initial begin
        rst = 0; #SYS_CYCLE;
        rst = 1; #SYS_CYCLE;

        load_instr("as/vga.mem", 14);
        while (lc_c.cpu_c.halted === 0) #CPU_CYCLE;

        // $display("beginning test");
        // `ASSERT_EQ(0,1);

        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd31, 10'd31}], 'hFFFF);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd32, 10'd32}], 'hFFFF);

        while (lc_c.vga_c.v_count != 31) #SYS_CYCLE;
        `ASSERT_EQ(lc_c.vga_c.mem_fetch_en, 0);
        while (lc_c.vga_c.h_count != 128) #SYS_CYCLE;
        `ASSERT_EQ(lc_c.vga_c.mem_fetch_en, 1);
        `ASSERT_EQ(lc_c.vga_c.mem_fetch_x_group, 0);
        `ASSERT_EQ(lc_c.vga_c.mem_fetch_y_val, 31);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf[31], 'hFFF);
        `ASSERT_EQ(lc_c.vga_bgr_buf[31], 'hFFF);
        `ASSERT_EQ(lc_c.mem_map_c.vga_bgr_buf[31], 'hFFF);
        // $display("%x", lc_c.vga_c.mem_bgr_buf[31]);

        $finish;
    end
endmodule
