`include "defs.vh"

module uart_sr(
    input uart_byte_ready,
    input [7:0] uart_byte,
    input rst,
    input clk,
    output reg [`WORD_WIDTH-1:0] uart_word,
    output reg uart_word_ready
);

    reg clocked_first_byte = 0, uart_word_loaded = 0;
    reg [3:0] byte_ready_vals = 0;


    always @(posedge clk) begin
        if (~rst) begin
            clocked_first_byte = 0;
            uart_word_ready = 0;
            uart_word_loaded = 0;
            byte_ready_vals = 4'hf;
        end else begin
            if (byte_ready_vals[3] == 0 & byte_ready_vals [2:0] == 3'b111) begin
                if (~clocked_first_byte) begin
                    uart_word = {uart_word[15:8], uart_byte};
                    clocked_first_byte = 1;
                    uart_word_ready = 0;
                end else begin
                    uart_word = {uart_byte, uart_word[7:0]};
                    uart_word_loaded = 1;
                end
            end else if (uart_word_loaded) begin
                uart_word_ready = 1;
                uart_word_loaded = 0;
                clocked_first_byte = 0;
            end

            byte_ready_vals = {byte_ready_vals[2:0], uart_byte_ready};
        end

    end
endmodule