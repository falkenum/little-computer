`include "defs.vh"

`define STATE_IDLE 0
`define STATE_FIRST_BYTE 1
`define STATE_SECOND_BYTE 2
`define STATE_WAIT 3

module uart_sr(
    input uart_byte_ready,
    input [7:0] uart_byte,
    input rst,
    input clk,
    output reg uart_word_ready,
    output reg [`WORD_WIDTH-1:0] uart_word,
    output reg [`WORD_WIDTH-1:0] uart_word_count
);
    reg clocked_first_byte = 0, clocked_second_byte = 0;
    reg [1:0] state = `STATE_IDLE, next_state = `STATE_IDLE;

    always @*
    case(state)
        `STATE_IDLE: 
            if (uart_byte_ready) next_state = `STATE_FIRST_BYTE;
            else next_state = state;
        `STATE_FIRST_BYTE:
            if (clocked_first_byte) next_state = `STATE_SECOND_BYTE;
            else next_state = state;
        `STATE_SECOND_BYTE:
            if (clocked_second_byte) next_state = `STATE_WAIT;
            else next_state = state;
        `STATE_WAIT:
            next_state = `STATE_IDLE;
    endcase

    always @(posedge clk, negedge rst) begin
        state = next_state;
        if (~rst) begin
            uart_word_count = 0;
            uart_word_ready = 0;
            clocked_first_byte = 0;
            clocked_second_byte = 0;
        end
        else
        case(state)
            `STATE_IDLE: begin
                uart_word_ready = 0;
                clocked_first_byte = 0;
                clocked_second_byte = 0;
            end
            `STATE_FIRST_BYTE: begin
                uart_word = {8'b0, uart_byte};
                clocked_first_byte = 1;
            end
            `STATE_SECOND_BYTE: begin
                uart_word = {uart_byte, uart_word[7:0]};
                uart_word_count += 1;
                clocked_second_byte = 1;
            end
            `STATE_WAIT: 
                uart_word_ready = 1;
        endcase
    end
endmodule