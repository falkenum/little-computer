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
    initial begin
        repeat(100000) begin
            clk = 1; #SYS_CYCLE;
            clk = 0; #SYS_CYCLE;
        end
    end

    initial begin
        rst = 0; #SYS_CYCLE;
        rst = 1; #SYS_CYCLE;
        data_to_send = 'hAB;
        start_n = 1; #(SYS_CYCLE*325*16)
        start_n = 0; 
        while (uart_tx_c.state == uart_tx_c.STATE_IDLE) #SYS_CYCLE;
        `ASSERT_EQ(uart_tx_c.data_sr, 'hab);
        `ASSERT_EQ(uart_tx_c.state, uart_tx_c.STATE_START);
        $display(uart_tx_c.state);
        $display("%x", uart_tx_c.data);
        start_n = 1;

        while (!byte_ready) #SYS_CYCLE;
        `ASSERT_EQ(uart_byte, 'hAB);
        $display("%x", uart_byte);
    end
endmodule