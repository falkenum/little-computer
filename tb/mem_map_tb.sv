`include "defs.vh"

`timescale 1 ns / 1 ps 

module mem_map_tb;
    reg clk = 0;
    reg rst = 1;


    // tb inputs
    reg write_en = 0;
    reg [15:0] pc = 0;
    reg [15:0] data_addr = 0;
    reg [15:0] data_in = 0;

    // tb outputs
    wire [15:0] instr;
    wire [15:0] data_out;

    // sdram ctl wires
    wire [15:0] dram_ctl_data_in;
    wire dram_ctl_write_en;
    wire [24:0] dram_ctl_addr;
    wire [15:0] dram_ctl_data_out;
    wire dram_data_ready;
    wire dram_refresh_data;

	wire		    [12:0]		dram_addr;
	wire		     [1:0]		dram_ba;
	wire		          		dram_ras_n;
	wire		          		dram_cas_n;
	wire		          		dram_we_n;
	wire		          		dram_clk;
	wire 		    [15:0]		dram_dq;

    
    sdram_sim sdram_c(
        .addr(dram_addr),
        .ba(dram_ba),
        .ras_n(dram_ras_n),
        .cas_n(dram_cas_n),
        .we_n(dram_we_n),
        .clk(dram_clk),
        .dq(dram_dq)
    );
    sdram_ctl sdram_ctl_c(
        .clk(clk),
        .rst(rst), 
        // inputs
        .write_en(dram_ctl_write_en),
        .addr(dram_ctl_addr),
        .data_in(dram_ctl_data_in),
        .refresh_data(dram_refresh_data),
        // output
        .data_out(dram_ctl_data_out),
        .data_ready(dram_data_ready),

        .dram_addr(dram_addr),
        .dram_ba(dram_ba),
        .dram_ras_n(dram_ras_n),
        .dram_cas_n(dram_cas_n),
        .dram_we_n(dram_we_n),
        .dram_clk(dram_clk),
        .dram_dq(dram_dq)
    );

    mem_map mem_map_c(
        .clk(clk),
        .rst(rst),

        .dram_read_data(dram_ctl_data_out),
        .dram_data_ready(dram_data_ready),
        .dram_addr(dram_ctl_addr),
        .dram_write_en(dram_ctl_write_en),
        .dram_refresh_data(dram_refresh_data),
        .dram_data_in(dram_ctl_data_in),

        //inputs
        .data_in(data_in),
        .pc(pc),
        .data_addr(data_addr),
        .write_en(write_en),

        // outputs
        .read_data(data_out),
        .instr(instr)
    );

    initial begin
        repeat(10000) begin
            clk = 1; #10;
            clk = 0; #10;
        end
    end

    localparam SYS_CYCLE = 20;
    localparam CPU_CYCLE = 64*SYS_CYCLE;
    initial begin
        rst = 0; #SYS_CYCLE;
        rst = 1;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_IDLE);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #101000;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_IDLE);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);

        pc = 1;
        write_en = 0;
        data_addr = 2;
        data_in = 3;
        `ASSERT_EQ(mem_map_c.pc, 1);
        `ASSERT_EQ(mem_map_c.write_en, 0);
        `ASSERT_EQ(mem_map_c.data_addr, 2);
        $readmemh("as/add.mem", sdram_c.mem, 0, 5);

        `ASSERT_EQ(mem_map_c.dram_refresh_data, 0);
        `ASSERT_EQ(sdram_ctl_c.refresh_data, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.refresh_data, 1);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_FETCH_INSTR);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);

        `ASSERT_EQ(mem_map_c.dram_write_en, 0);
        `ASSERT_EQ(mem_map_c.dram_addr, 1);

        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.refresh_data, 1);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        // $display(sdram_ctl_c.state);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);

        `ASSERT_EQ(mem_map_c.got_instr, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.dram_data_ready, 1);
        `ASSERT_EQ(mem_map_c.got_instr, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.got_instr, 1);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_INSTR_OUT_FETCH_DATA);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        while (mem_map_c.state != mem_map_c.STATE_IDLE) #SYS_CYCLE;

        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        `ASSERT_EQ(mem_map_c.instr, 'h0009);
        `ASSERT_EQ(mem_map_c.dram_read_data, 'h0049);

        pc = 3;
        write_en = 0;
        data_addr = 4;
        #CPU_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_IDLE);
        `ASSERT_EQ(instr, 'h4809);
        `ASSERT_EQ(data_out, 'h47C9);
        `ASSERT_EQ(dram_ctl_data_out, 'h47C9);
        #CPU_CYCLE;
        `ASSERT_EQ(instr, 'h4809);
        `ASSERT_EQ(data_out, 'h47C9);

        pc = 5;
        write_en = 1;
        data_in = 'hABAB;
        data_addr = 0;
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_FETCH_INSTR);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);

        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ_NOP);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ_COMPLETE);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_INSTR_OUT_FETCH_DATA);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        `ASSERT_EQ(mem_map_c.dram_data_in, 'habab);
        `ASSERT_EQ(mem_map_c.data_in, 'habab);
        `ASSERT_EQ(sdram_ctl_c.data_in, 'habab);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_WRITE);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_WRITE_NOP);
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ_NOP);
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ_COMPLETE);
        #SYS_CYCLE;
        `ASSERT_EQ(instr, 'hE000);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_DATA_OUT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        `ASSERT_EQ(sdram_c.mem[0], 'habab);
        `ASSERT_EQ(mem_map_c.dram_read_data, 'habab);
        `ASSERT_EQ(data_out, 'habab);

        #CPU_CYCLE;
        `ASSERT_EQ(instr, 'hE000);
        `ASSERT_EQ(data_out, 'hABAB);
        pc = 0;
        write_en = 0;
        data_in = 'hABAB;
        data_addr = 5;
        #CPU_CYCLE;
        `ASSERT_EQ(data_out, 'hE000);
        `ASSERT_EQ(instr, 'hABAB);
        pc = 3;
        write_en = 1;
        data_addr = 7;
        data_in = 'hcdcd;
        #CPU_CYCLE;
        `ASSERT_EQ(data_out, 'hcdcd);
        `ASSERT_EQ(instr, 'h4809);

    end
endmodule