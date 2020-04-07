`include "defs.vh"

`timescale 1 ns / 1 ps 

module mem_map_tb;
    reg clk = 0;
    reg rst = 1;

    // temp vars
    reg [9:0] temp_x;
    reg [8:0] temp_y;
    reg [3:0] temp_color_comp;
    integer cycle_count = 0;

    // tb inputs
    reg write_en = 0;
    reg [15:0] pc = 0;
    reg [15:0] data_addr = 0;
    reg [15:0] data_in = 0;
    reg vga_en = 0;
    reg [4:0] vga_x_group = 0;
    reg [8:0] vga_y_val = 0;

    // tb outputs
    wire [15:0] instr;
    wire [15:0] data_out;
    wire [31:0][11:0] vga_bgr_buf;

    // sdram ctl wires
    wire [15:0] dram_ctl_data_in;
    wire dram_ctl_write_en;
    wire [24:0] dram_ctl_addr;
    wire [15:0] dram_ctl_data_out;
    wire dram_data_ready;
    wire dram_refresh_data;
    wire dram_ctl_ready;
    wire dram_ctl_burst_en;
    wire [31:0][15:0] dram_ctl_burst_buf;

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
        .burst_en(dram_ctl_burst_en),
        .refresh_data(dram_refresh_data),
        // output
        .data_out(dram_ctl_data_out),
        .data_ready(dram_data_ready),
        .mem_ready(dram_ctl_ready),
        .burst_buf(dram_ctl_burst_buf),

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
        .dram_burst_en(dram_ctl_burst_en),
        .dram_data_in(dram_ctl_data_in),
        .dram_burst_buf(dram_ctl_burst_buf),
        .cpu_ready(1'b1),
        .uart_tx_ready(1'b0),

        //inputs
        .data_in(data_in),
        .pc(pc),
        .data_addr(data_addr),
        .write_en(write_en),
        .vga_en(vga_en),
        .vga_x_group(vga_x_group),
        .vga_y_val(vga_y_val),

        // outputs
        .read_data(data_out),
        .instr(instr),
        .vga_bgr_buf(vga_bgr_buf)
    );

    initial begin
        forever begin
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
        while(!sdram_ctl_c.mem_ready) #SYS_CYCLE;
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
        `ASSERT_EQ(mem_map_c.pc, 1);
        `ASSERT_EQ(sdram_ctl_c.refresh_data, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.refresh_data, 1);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_FETCH_INSTR);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);

        `ASSERT_EQ(mem_map_c.dram_write_en, 0);
        `ASSERT_EQ(mem_map_c.dram_addr, 1);

        `ASSERT_EQ(sdram_ctl_c.refresh_data, 1);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_ACTIVATE);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);

        `ASSERT_EQ(mem_map_c.got_instr, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_READ);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ);
        `ASSERT_EQ(sdram_ctl_c.post_read_count, 1);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ);
        `ASSERT_EQ(sdram_ctl_c.post_read_count, 2);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_BURST_STOP);
        `ASSERT_EQ(mem_map_c.got_instr, 0);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_INSTR_OUT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        `ASSERT_EQ(sdram_ctl_c.data_ready, 1);
        `ASSERT_EQ(mem_map_c.dram_data_ready, 1);
        `ASSERT_EQ(mem_map_c.got_instr, 1);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_RW_DATA);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        #SYS_CYCLE;
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
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_POST_READ);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_INSTR_OUT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_RW_DATA);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.dram_data_in, 'habab);
        `ASSERT_EQ(mem_map_c.data_in, 'habab);
        `ASSERT_EQ(sdram_ctl_c.data_in, 'habab);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_WAIT);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_WRITE);
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_DATA_OUT);
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_IDLE);
        `ASSERT_EQ(sdram_ctl_c.state, sdram_ctl_c.STATE_IDLE);
        #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(instr, 'hE000);
        `ASSERT_EQ(mem_map_c.state, mem_map_c.STATE_IDLE);
        `ASSERT_EQ(sdram_c.mem[0], 'habab);

        #CPU_CYCLE;
        `ASSERT_EQ(instr, 'hE000);
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
        `ASSERT_EQ(instr, 'h4809);

        // vga write addr
        data_addr = 'hF80C;

        temp_x = 32;
        temp_y = 7;
        temp_color_comp = 0;

        // filling some values into video memory
        while (temp_x < 64) begin
            // x
            pc = 0;
            data_in = temp_x;
            #CPU_CYCLE;

            // y
            pc = 1;
            data_in = temp_y;
            #CPU_CYCLE;

            // bgr
            pc = 2;
            data_in = {4'b0, {3{temp_color_comp}}};
            #CPU_CYCLE;
            temp_x += 1;
            temp_color_comp += 1;
        end

        `ASSERT_EQ(sdram_c.mem[{6'h1, 9'd7, 10'd32}], 12'h000);
        `ASSERT_EQ(sdram_c.mem[{6'h1, 9'd7, 10'd33}], 12'h111);

        pc = 0;
        vga_en = 1;
        write_en = 0;
        vga_x_group = 1;
        vga_y_val = 7;
        #SYS_CYCLE;
        
        while (mem_map_c.state !== mem_map_c.STATE_IDLE) begin
            cycle_count += 1;
            #SYS_CYCLE;
        end

        temp_x = 0;
        temp_color_comp = 0;
        while (temp_x < 32) begin
            `ASSERT_EQ(vga_bgr_buf[temp_x], {3{temp_color_comp}});
            temp_x += 1;
            temp_color_comp += 1;
        end

        $finish;
    end
endmodule