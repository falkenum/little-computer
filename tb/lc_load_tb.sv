
`include "defs.vh"

`timescale 1 ns / 1 ps
module lc_load_tb;
    logic clk = 0, rst = 1;
    reg start_n = 1;
    reg load_en = 1;
    reg debug_mode = 1;
    reg [7:0] data_to_send;
    wire tx, ready_to_send;
    wire nada = 'bz;
    wire [26:0] gpio_upper = {27{nada}};
    wire [7:0] gpio_lower = {8{nada}};
    
	wire		    [12:0]		addr;
	wire		     [1:0]		ba;
	wire		          		ras_n;
	wire		          		cas_n;
	wire		          		we_n;
	wire		          		dram_clk;
	wire 		    [15:0]		dq;

    localparam SYS_CYCLE = 20;
    localparam CPU_CYCLE = 64*SYS_CYCLE;
    localparam BAUD_CYCLE = SYS_CYCLE*56*16;

    uart_tx uart_tx_c(
        .clk(clk),
        .rst(rst),
        .start_n(start_n),
        .data(data_to_send),
        .tx(tx),
        .ready_to_send(ready_to_send)
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
        .SW({8'b0, load_en, debug_mode}),
        .GPIO({gpio_upper, tx, gpio_lower}),
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
        rst = 0; 
        #SYS_CYCLE;
        #SYS_CYCLE;
        rst = 1; #SYS_CYCLE;
        data_to_send = 'hAB;
        debug_mode = 0;
        start_n = 1; #BAUD_CYCLE;
        start_n = 0;
        while (uart_tx_c.state == uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        start_n = 1;
        while (uart_tx_c.state != uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        `ASSERT_EQ(lc_c.uart_rx_c.data_ready, 1);
        `ASSERT_EQ(uart_tx_c.ready_to_send, 1);
        `ASSERT_EQ(lc_c.uart_rx_c.data, 'hab);
        `ASSERT_EQ(lc_c.uart_rx_c.state, lc_c.uart_rx_c.STATE_IDLE);
        `ASSERT_EQ(uart_tx_c.state, uart_tx_c.STATE_IDLE);
        `ASSERT_EQ(lc_c.uart_sr_c.clocked_first_byte, 1);

        data_to_send = 'hCD;
        start_n = 1; #BAUD_CYCLE;
        start_n = 0;
        while (uart_tx_c.state == uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        start_n = 1;
        while (uart_tx_c.state != uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end

        `ASSERT_EQ(sdram_c.mem[0], 'hCDAB);
        `ASSERT_EQ(lc_c.uart_word_count, 1);
        
        data_to_send = 'h25;
        start_n = 1; #BAUD_CYCLE;
        start_n = 0;
        while (uart_tx_c.state == uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        start_n = 1;
        while (uart_tx_c.state != uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        `ASSERT_EQ(lc_c.uart_sr_c.uart_word_ready, 0);
        `ASSERT_EQ(lc_c.uart_rx_c.data_ready, 1);
        `ASSERT_EQ(uart_tx_c.ready_to_send, 1);
        `ASSERT_EQ(lc_c.uart_rx_c.data, 'h25);
        `ASSERT_EQ(lc_c.uart_rx_c.state, lc_c.uart_rx_c.STATE_IDLE);
        `ASSERT_EQ(uart_tx_c.state, uart_tx_c.STATE_IDLE);
        `ASSERT_EQ(lc_c.uart_sr_c.clocked_first_byte, 1);
        `ASSERT_EQ(lc_c.uart_sr_c.uart_word[7:0], 'h25);

        data_to_send = 'h98;
        start_n = 1; #BAUD_CYCLE;
        start_n = 0;
        while (uart_tx_c.state == uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        start_n = 1;
        while (uart_tx_c.state != uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        `ASSERT_EQ(lc_c.uart_word, 'h9825);

        `ASSERT_EQ(sdram_c.mem[1], 'h9825);
        `ASSERT_EQ(lc_c.uart_word_count, 2);

        load_en = 0;
        rst = 0; #SYS_CYCLE;
        #SYS_CYCLE;
        #SYS_CYCLE;
        `ASSERT_EQ(lc_c.sysrst, 0);
        `ASSERT_EQ(lc_c.cpu_c.rst, 0);
        rst = 1; #SYS_CYCLE;


        $finish;
    end
endmodule

