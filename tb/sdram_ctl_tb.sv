`include "defs.vh"

`timescale 1 ns / 1 ps 

module sdram_ctl_tb;
    reg clk = 0;
    reg rst = 1;
    reg write_en = 0;
    reg [24:0] addr;
    reg [15:0] data_in;

    wire [15:0] data_out;

	wire		    [12:0]		dram_addr;
	wire		     [1:0]		ba;
	wire		          		ras_n;
	wire		          		cas_n;
	wire		          		we_n;
	wire		          		dram_clk;
	wire 		    [15:0]		dq;

    
    sdram_sim sdram_c(
        .addr(dram_addr),
        .ba(ba),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .clk(dram_clk),
        .dq(dq)
    );
    sdram_ctl sdram_ctl_c(
        .clk(clk),
        .rst(rst), 
        .write_en(write_en),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out),

        .dram_addr(dram_addr),
        .dram_ba(ba),
        .dram_ras_n(ras_n),
        .dram_cas_n(cas_n),
        .dram_we_n(we_n),
        .dram_clk(dram_clk),
        .dram_dq(dq)
    );

    initial begin
        repeat(10000) begin
            clk = 1; #10;
            clk = 0; #10;
        end
    end
    initial begin
        rst = 0; #10;
        rst = 1; #10;

        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_RST_NOP);
        `ASSERT_EQ(sdram_ctl_c.wait_count, 1);
        #100000;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_RST_PRECHARGE);
        // $display(sdram_ctl_c.state);
        #20;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_RST_AUTO_REFRESH);
        #160;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_RST_MODE_WRITE);
        #20;
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_IDLE);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        #20;
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_ACTIVATED);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ);
        `ASSERT_EQ(sdram_c.precharged, 0);
        #20;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ_NOP);
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_CMD_READ);
        `ASSERT_EQ(sdram_c.precharged, 1);
        `ASSERT_EQ(sdram_c.drive_val, 1);
        #20;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ_NOP);
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_IDLE);
        #20;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ_COMPLETE);
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_IDLE);
        addr = 0;
        data_in = 'hff;
        write_en = 1;
        #20;
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_IDLE);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        #20;
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_ACTIVATED);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_WRITE);
        `ASSERT_EQ(sdram_ctl_c.data_in_r, 'hff);
        #20;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_WRITE_NOP);
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_CMD_WRITE);
        #120;
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_CMD_READ);
        #20;
        `ASSERT_EQ(sdram_c.state, sdram_c.STATE_IDLE);
        #20;
        addr = 1;
        data_in = 'hfe;
        write_en = 1;
        #20;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        `ASSERT_EQ(sdram_c.drive_val, 1);
        `ASSERT_EQ(sdram_ctl_c.drive_val, 0);
        `ASSERT_EQ(data_out, 'hff);
        `ASSERT_EQ(sdram_c.mem[0], 'hff);

        #(10*20);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ_COMPLETE);
        `ASSERT_EQ(data_out, 'hfe);
        addr = 0;
        data_in = 'hfe;
        write_en = 0;
        #(11*20);
        `ASSERT_EQ(data_out, 'hff);
        addr = 1;
        data_in = 'hfe;
        write_en = 0;
        #(11*20);
        `ASSERT_EQ(data_out, 'hfe);

        // $display("%03b", sdram_ctl_c.cmd);
        // $display("%b%b%b", ras_n, cas_n, we_n);
        // $display(data_out);
        // $display(sdram_c.mem[0]);
    end
endmodule