`include "defs.vh"

`timescale 1 ns / 1 ps
module lc_hello_tb;

    reg clk = 0, rst = 1;
	wire [12:0]	addr;
	wire [1:0] ba;
	wire ras_n;
	wire cas_n;
	wire we_n;
	wire dram_clk;
	wire [15:0]	dq;
    wire nada = 'bz;
    wire [25:0] gpio_upper = {27{nada}};
    wire [8:0] gpio_lower = {8{nada}};

    wire [7:0] uart_data;
    wire uart_data_ready, uart_rx;

    localparam SYS_CYCLE = 20;
    localparam CPU_CYCLE = 64*SYS_CYCLE;

    uart_rx uart_rx_c(
        .clk(clk),
        .rst(rst),
        
        .rx(uart_rx),

        .data(uart_data),
        .data_ready(uart_data_ready)
    );
    
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
        .GPIO({gpio_upper, uart_rx, gpio_lower}),
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
        rst = 0; 
        #SYS_CYCLE;
        #SYS_CYCLE;

        rst = 1; #SYS_CYCLE;

        while (lc_c.state != lc_c.STATE_RUNNING) begin
            #SYS_CYCLE;
        end
    endtask

    reg [31:0][7:0] strbuf = 0;
    reg [12:0][7:0] cmpstr = {"hello world\n", 8'b0};
    integer i = 0;

    initial begin
        load_instr("s/hello.mem", 32);

        for (i = 12; i > 0; i = i - 1) begin
            while (lc_c.cpu_c.pc !== 29) begin
                #CPU_CYCLE;
            end
            `ASSERT_EQ(uart_data_ready, 1);
            // $display("%d: %s", i, cmpstr[i]);
            `ASSERT_EQ(uart_data, cmpstr[i]);
            #CPU_CYCLE;
        end
        #CPU_CYCLE;
        #CPU_CYCLE;
        #CPU_CYCLE;
        `ASSERT_EQ(lc_c.cpu_c.pc, 31);


        $finish;
    end
endmodule

