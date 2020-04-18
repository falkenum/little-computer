
`include "defs.vh"


// 57600 baud
module uart_tx #(parameter clks_per_bit = 56*16) (
    input clk,
    input rst,
    input start_n,
    input [7:0] data,
    output reg tx,
    output reg ready_to_send
);
    reg [7:0] data_write;
    reg [7:0] data_sr;
    integer clk_count;
    reg clk_baud;
    reg start_next_clk_baud;
    reg [1:0] state;
    reg [1:0] start_n_vals;
    reg [1:0] clk_baud_vals;
    localparam STATE_IDLE = 0;
    localparam STATE_START = 1;
    localparam STATE_DATA = 2;
    localparam STATE_STOP = 3;

    function [1:0] next_state_func;
        input [1:0] state;
        case (state)
            STATE_IDLE: 
                if (start_next_clk_baud) next_state_func = STATE_START;
                else next_state_func = state;
            STATE_START:
                next_state_func = STATE_DATA;
            STATE_DATA:
                if (!data_write) next_state_func = STATE_STOP;
                else next_state_func = state;
            STATE_STOP:
                next_state_func = STATE_IDLE;
        endcase
    endfunction

    always @(posedge clk) begin
        clk_count += 1;
        if (clk_count >= clks_per_bit >> 1) begin
            clk_baud = ~clk_baud;
            clk_count = 0;
        end
        clk_baud_vals = {clk_baud_vals[0], clk_baud};
        start_n_vals = {start_n_vals[0], start_n};
        if (~rst) begin
            clk_baud = 0;
            data_sr = 0;
            tx = 1;
            ready_to_send = 0;
            state = STATE_IDLE;
            start_n_vals = 2'b00;
            clk_count = 0;
            start_next_clk_baud = 0;
        end
        if (start_n_vals[1] == 1 && start_n_vals[0] == 0) begin
            start_next_clk_baud = 1;
        end
        if (clk_baud_vals[1] == 0 && clk_baud_vals[0] == 1) begin
            state = next_state_func(state);
            case (state)
                STATE_IDLE: begin
                    tx = 1;
                    ready_to_send = 1;
                end
                STATE_START: begin
                    data_sr = data;
                    start_next_clk_baud = 0;
                    ready_to_send = 0;
                    tx = 0;
                    data_write = 1;
                end
                STATE_DATA: begin
                    tx = data_sr[0];
                    data_sr = data_sr >> 1;
                    data_write = data_write << 1;
                end
                STATE_STOP: begin
                    tx = 1;
                end
            endcase
        end

    end
endmodule