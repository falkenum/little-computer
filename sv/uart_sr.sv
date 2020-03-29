`include "defs.vh"

`define STATE_IDLE 0
`define STATE_FIRST_BYTE 1
`define STATE_WAIT 2
`define STATE_SECOND_BYTE 3
`define STATE_WORD_READY 4
`define STATE_INC 5

module uart_sr(
    input uart_byte_ready,
    input [7:0] uart_byte,
    input rst,
    input clk,
    output reg [`WORD_WIDTH-1:0] uart_word,
    output reg uart_word_ready
);

    // reg [2:0] state = `STATE_IDLE;
    reg clocked_first_byte = 0, uart_word_loaded = 0;
    reg [3:0] byte_ready_vals = 0;

    // function [2:0] next_state_func(state);
    //     case(state)
    //         `STATE_IDLE: next_state_func = `STATE_FIRST_BYTE;
    //         `STATE_FIRST_BYTE: 
    //             if (clocked_first_byte) next_state_func = `STATE_WAIT;
    //             else next_state_func = state;
    //         `STATE_WAIT:
    //             // if (ready_for_second_byte) next_state_func = `STATE_SECOND_BYTE;
    //             next_state_func = state;
    //         // `STATE_SECOND_BYTE:
    //         //     if (clocked_second_byte) next_state_func = `STATE_WORD_READY;
    //         //     else next_state_func = state;
    //         // `STATE_WORD_READY:
    //         //     if (uart_word_ready) next_state_func = `STATE_INC;
    //         //     else next_state_func = state;
    //         // `STATE_INC:
    //         //     next_state_func = `STATE_IDLE;
    //         default: next_state_func = `STATE_IDLE;
    //     endcase
    // endfunction

    always @(posedge clk) begin
        if (~rst) begin
            // state = `STATE_IDLE;
            clocked_first_byte = 0;
            uart_word_ready = 0;
            uart_word_loaded = 0;
            byte_ready_vals = 4'hf;
        end
        // else state = next_state_func(state);

        else
        begin
            if (byte_ready_vals[3] == 0 & byte_ready_vals [2:0] == 3'b111) begin
                if (~clocked_first_byte) begin
                    uart_word = {uart_word[15:8], uart_byte};
                    clocked_first_byte = 1;
                end else begin
                    uart_word = {uart_byte, uart_word[7:0]};
                    uart_word_loaded = 1;
                end
            end else if (uart_word_loaded) begin
                uart_word_ready = 1;
                uart_word_loaded = 0;
                clocked_first_byte = 0;
            end else if (uart_word_ready) begin
                uart_word_ready = 0;
            end

            byte_ready_vals = {byte_ready_vals[2:0], uart_byte_ready};
        end

        // case(state)
        //     `STATE_IDLE: begin
        //         clocked_first_byte = 0;
        //         clocked_second_byte = 0;
        //         uart_word_ready = 0;
        //         ready_for_second_byte = 0;
        //         byte_ready_vals = 0;
        //     end
        //     `STATE_FIRST_BYTE: begin
        //         if (byte_ready_vals[3] == 0 & byte_ready_vals [2:0] == 3'b111) begin
        //             uart_word = {uart_word[15:8], uart_byte};
        //             clocked_first_byte = 1;
        //         end
        //         byte_ready_vals = {byte_ready_vals[2:0], uart_byte_ready};
        //     end
        //     `STATE_WAIT: begin
        //         if (byte_ready_vals[3] == 1 & byte_ready_vals [2:0] == 3'b0) begin
        //             ready_for_second_byte = 1;
        //         end
        //         byte_ready_vals = {byte_ready_vals[2:0], uart_byte_ready};
        //     end
            // `STATE_SECOND_BYTE: begin
            //     if (byte_ready_vals[3] == 0 & byte_ready_vals [2:0] == 3'b111) begin
            //         uart_word = {uart_byte, uart_word[7:0]};
            //         clocked_second_byte = 1;
            //     end
            //     byte_ready_vals = {byte_ready_vals[2:0], uart_byte_ready};
            // end
            // `STATE_WORD_READY: begin
            //     uart_word_ready = 1;
            // end
            // `STATE_INC: begin
            //     uart_word_count += 1;
            // end
        // endcase
    end
endmodule