`include "defs.vh"

`timescale 1 ns/ 1 ps
module vga_tb;
    reg clk = 0, rst = 1, i = 0;
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

        load_instr("s/vga.mem", 25);
        while (lc_c.cpu_c.pc != 5) #CPU_CYCLE;
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[1], 'hF80C);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[2], 'h0280);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[3], 'h01E0);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[4], 'h0800);
        while(lc_c.pc != 17) #(CPU_CYCLE);
        `ASSERT_EQ(lc_c.cpu_c.reg_file[5], 'd640);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[6], 'd1);
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.reg_file[5], 'd0);
        #CPU_CYCLE;
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.pc, 11);
        //  do second row
        while(lc_c.pc != 17) #(CPU_CYCLE);
        
        // while(lc_c.pc != 17) #(CPU_CYCLE);
        // #CPU_CYCLE;
        // `ASSERT_EQ(lc_c.cpu_c.reg_file[6], 'd2);
        // #CPU_CYCLE;
        // `ASSERT_EQ(lc_c.cpu_c.reg_file[5], 'd0);
        // #CPU_CYCLE;
        // #CPU_CYCLE;
        // `ASSERT_EQ(lc_c.pc, 11);
        // lc_c.cpu_c.reg_file[6] = 479;
        // while(lc_c.pc != 17) #(CPU_CYCLE);
        // #CPU_CYCLE;
        // #CPU_CYCLE;
        // #CPU_CYCLE;
        // `ASSERT_EQ(lc_c.cpu_c.reg_file[5], 'd0);
        // `ASSERT_EQ(lc_c.cpu_c.reg_file[6], 'd480);
        // `ASSERT_EQ(lc_c.pc, 21);
        // while(lc_c.pc < 20) begin
        //     #(CPU_CYCLE*100000);
        //     $display("time is ", $time);
        // end
        // `ASSERT_EQ(0,1);

        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd0, 10'd0}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd0, 10'd1}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd0, 10'd200}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd0, 10'd639}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd1, 10'd0}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd1, 10'd1}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd1, 10'd200}], 'h0800);
        `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd1, 10'd639}], 'h0800);
        // `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd479, 10'd0}], 'h0800);
        // `ASSERT_EQ(sdram_c.mem[{6'b1, 9'd479, 10'd639}], 'h0800);

        while (lc_c.vga_c.v_count != 0) #SYS_CYCLE;
        `ASSERT_EQ(lc_c.vga_c.mem_fetch_en, 0);
        while (lc_c.vga_c.h_count != 128) #SYS_CYCLE;
        `ASSERT_EQ(lc_c.mem_map_c.vga_en, 1);
        `ASSERT_EQ(lc_c.mem_map_c.vga_x_group, 0);
        `ASSERT_EQ(lc_c.mem_map_c.vga_y_val, 0);

        while (lc_c.mem_map_c.state !== lc_c.mem_map_c.STATE_FETCH_VGA) begin
            #SYS_CYCLE;
        end

        `ASSERT_EQ(lc_c.mem_map_c.dram_addr, {6'b1, 9'd0, 10'd0});
        `ASSERT_EQ(lc_c.sdram_ctl_c.state, lc_c.sdram_ctl_c.STATE_IDLE);

        #SYS_CYCLE;
        while (lc_c.sdram_ctl_c.data_ready != 1) begin
            #SYS_CYCLE;
        end

        // #CPU_CYCLE;
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf[31], 'h800);
        `ASSERT_EQ(lc_c.vga_bgr_buf[31], 'h800);
        `ASSERT_EQ(lc_c.mem_map_c.vga_bgr_buf[31], 'h800);
        `ASSERT_EQ(lc_c.sdram_ctl_c.burst_buf[31], 'h800);
        // $display("%x", lc_c.vga_c.mem_bgr_buf[31]);
        while (lc_c.vga_c.h_count != 160) #SYS_CYCLE;

        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf_r[0], 'h800);
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf_r[10], 'h800);
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf_r[15], 'h800);
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf_r[20], 'h800);
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf_r[21], 'h800);
        `ASSERT_EQ(lc_c.vga_c.mem_bgr_buf_r[31], 'h800);

        while (lc_c.vga_c.h_count != 192) begin
            `ASSERT_EQ(lc_c.vga_c.rval, 'h0);
            `ASSERT_EQ(lc_c.vga_c.gval, 'h0);
            `ASSERT_EQ(lc_c.vga_c.bval, 'h8);
            #SYS_CYCLE;
        end


        while (lc_c.vga_c.v_count != 1) #SYS_CYCLE;
        while (lc_c.vga_c.h_count != 160) #SYS_CYCLE;
        while (lc_c.vga_c.h_count != 192) begin
            `ASSERT_EQ(lc_c.vga_c.rval, 'h0);
            `ASSERT_EQ(lc_c.vga_c.gval, 'h0);
            `ASSERT_EQ(lc_c.vga_c.bval, 'h8);
            #SYS_CYCLE;
        end

        $finish;
    end
endmodule
