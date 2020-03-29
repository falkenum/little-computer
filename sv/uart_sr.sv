`include "defs.vh"

`define STATE_FIRST_BYTE 0
`define STATE_WAIT 1
`define STATE_SECOND_BYTE 2
`define STATE_WORD_READY 3
`define STATE_INC 4

`define WAIT_TIME 23'h1000000

module uart_sr(
    input uart_byte_ready,
    input [7:0] uart_byte,
    input rst,
    input clk,
    output reg uart_word_ready,
    output reg [`WORD_WIDTH-1:0] uart_word,
    output reg [`WORD_WIDTH-1:0] uart_word_count,

    // TODO delete
    output [2:0] state_out,
    output clocked_first_byte_out,
    output clocked_second_byte_out
);
    assign clocked_first_byte_out = clocked_first_byte;
    assign clocked_second_byte_out = clocked_second_byte;
    assign state_out = state;

    reg clocked_first_byte = 0, clocked_second_byte = 0;
    reg [2:0] state = `STATE_FIRST_BYTE, next_state = `STATE_FIRST_BYTE;
    reg [22:0] wait_count = 1;

    always @*
    case(state)
        `STATE_FIRST_BYTE:
            if (clocked_first_byte) next_state = `STATE_WAIT;
            else next_state = state;
        // need to wait to make sure uart_byte_ready goes down
        `STATE_WAIT:
            if (wait_count >= `WAIT_TIME) next_state = `STATE_SECOND_BYTE;
            else next_state = state;
        `STATE_SECOND_BYTE:
            if (clocked_second_byte) next_state = `STATE_WORD_READY;
            else next_state = state;
        `STATE_WORD_READY:
            if (uart_word_ready) next_state = `STATE_INC;
            else next_state = state;
        `STATE_INC:
            next_state = `STATE_FIRST_BYTE;
        default: next_state = `STATE_FIRST_BYTE;
    endcase

    always @(posedge clk, negedge rst) begin
        state = next_state;
        if (~rst) begin
            uart_word_count = 0;
            state = `STATE_FIRST_BYTE;
            uart_word_ready = 0;
            clocked_first_byte = 0;
            clocked_second_byte = 0;
        end
        else
        case(state)
            `STATE_FIRST_BYTE: begin
                uart_word_ready = 0;
                wait_count = 0;

                if (uart_byte_ready) begin
                    uart_word = {8'b0, uart_byte};
                    clocked_first_byte = 1;
                end
            end
            `STATE_WAIT: begin
                if (wait_count < `WAIT_TIME) wait_count += 1;
            end
            `STATE_SECOND_BYTE: begin
                if (uart_byte_ready) begin
                    uart_word = {uart_byte, uart_word[7:0]};
                    clocked_second_byte = 1;
                end
            end
            `STATE_WORD_READY: begin
                uart_word_ready = 1;
            end
            `STATE_INC: begin
                clocked_second_byte = 0;
                clocked_first_byte = 0;
                uart_word_count += 1;
            end
        endcase
    end
endmodule