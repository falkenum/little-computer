`include "defs.vh"

`timescale 1 ns / 1 ps 

module mem_map_tb;
    reg clk = 0;
    reg rst = 1;


    // tb inputs
    reg write_en = 0;
    reg [15:0] pc = 0;
    reg [15:0] data_addr = 0

    // tb outputs
    wire [15:0] instr = 0;
    wire [15:0] data_out = 0;

    // sdram ctl wires
    wire dram_ctl_write_en;
    wire [24:0] dram_ctl_addr;
    wire [15:0] dram_ctl_data_in;
    wire [15:0] dram_ctl_data_out;

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
        // output
        .data_out(dram_ctl_data_out),

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
        .dram_addr(dram_ctl_addr),
        .dram_write_en(dram_ctl_write_en),

        //inputs
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
    initial begin
        rst = 0; #10;
        rst = 1; #10;
        #101000;
    end
endmodule