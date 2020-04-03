`include "defs.vh"

`timescale 1 ns / 1 ps

module uart_tb();
    reg uart_byte_ready = 0, rst = 1, clk = 0;
    reg [7:0] uart_byte = 0;
    wire uart_word_ready;
    wire [`WORD_WIDTH-1:0] uart_word;

    uart_sr uart_sr_c(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_byte),
        .rst(rst),
        .clk(clk),
        .uart_word_ready(uart_word_ready),
        .uart_word(uart_word)
    );

    initial begin
        repeat(100000) begin
            clk = 1; #20;
            clk = 0; #20;
        end
    end

    initial begin
    end
endmodule