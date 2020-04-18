`include "defs.vh"

`timescale 1 ns / 1 ps

module uart_tb();
    reg rst = 1, clk = 0;
    reg start_n = 1;
    reg [7:0] data_to_send;

    
    wire tx, byte_ready, word_ready, ready_to_send;
    wire [7:0] uart_byte;
    wire [`WORD_WIDTH-1:0] uart_word;

    uart_tx uart_tx_c(
        .clk(clk),
        .rst(rst),
        .start_n(start_n),
        .data(data_to_send),
        .tx(tx),
        .ready_to_send(ready_to_send)
    );
    uart_rx uart_rx_c(
        .rx(tx),
        .clk(clk),
        .rst(rst),
        .data(uart_byte),
        .data_ready(byte_ready)
    );

    uart_sr uart_sr_c(
        .uart_byte_ready(byte_ready),
        .uart_byte(uart_byte),
        .rst(rst),
        .clk(clk),
        .uart_word_ready(word_ready),
        .uart_word(uart_word)
    );

    localparam SYS_CYCLE = 20;
    localparam BAUD_CYCLE = SYS_CYCLE*56*16;

    initial begin
        forever begin
            clk = 1; #10;
            clk = 0; #10;
        end
    end

    initial begin
        rst = 0; #SYS_CYCLE;
        rst = 1; #SYS_CYCLE;
        data_to_send = 'hAB;
        // $display("%b", uart_tx_c.start_n_vals);
        start_n = 1; 
        // while (uart_tx_c.state !== uart_tx_c.STATE_IDLE) begin
        //     #BAUD_CYCLE;
        // end
        #SYS_CYCLE;
        start_n = 0;
        #SYS_CYCLE;

        // while (uart_tx_c.state !== uart_tx_c.STATE_START) begin
    
        //     #BAUD_CYCLE;
        // end
        start_n = 1;
        // while (uart_tx_c.state !== uart_tx_c.STATE_DATA) begin
        //     #BAUD_CYCLE;
        // end
        `ASSERT_EQ(uart_tx_c.state, uart_tx_c.STATE_IDLE);
        while (uart_tx_c.state !== uart_tx_c.STATE_START) begin
            #BAUD_CYCLE;
        end
        while (uart_tx_c.state !== uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end

        `ASSERT_EQ(uart_byte, 'hAB);
        `ASSERT_EQ(byte_ready, 1);
        data_to_send = 'hCD;
        start_n = 1;
        #SYS_CYCLE;
        start_n = 0;
        #SYS_CYCLE;
        
        // while (uart_rx_c.state === uart_rx_c.STATE_IDLE) begin
        start_n = 1;
        while (uart_tx_c.state !== uart_tx_c.STATE_START) begin
            #BAUD_CYCLE;
        end
        while (uart_tx_c.state !== uart_tx_c.STATE_IDLE) begin
            #BAUD_CYCLE;
        end
        `ASSERT_EQ(uart_word, 'hCDAB);
        $finish;
    end
endmodule