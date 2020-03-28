`include "defs.vh"

module uart_sr(
    input uart_byte_ready,
    input [7:0] uart_byte,
    input rst,
    output reg uart_word_ready,
    output reg [`WORD_WIDTH-1:0] uart_word,
    output reg [`WORD_WIDTH-1:0] uart_word_count
);
    reg clocked_first_byte = 0;

    always @(posedge uart_byte_ready, negedge rst) begin
        if (~rst) begin
            uart_word_count = 0;
            uart_word_ready = 0;
            clocked_first_byte = 0;
        end
        else begin
            if (clocked_first_byte) begin
                uart_word = {uart_byte, uart_word[7:0]};
                clocked_first_byte = 0;
                uart_word_ready = 1;
            end
            else begin
                uart_word = {8'b0, uart_byte};
                clocked_first_byte = 1;
                uart_word_ready = 0;
                uart_word_count += 1;
            end
        end
    end
endmodule