`include "defs.vh"

`define STATE_IDLE 0
`define STATE_STARTED 1
`define STATE_DATA 2
`define STATE_STOP 3

module uart_rx(
    input rx,
    input clk_50M,
    output reg [7:0] data,
    output reg data_ready,
    output clk_out,
    output [1:0] state_out
);
    reg [7:0] data_write;
    reg [7:0] clk_50M_count = 0;
    reg [5:0] sync_count = 0;
    reg clk = 0;
    reg receiving = 0, clock_synced = 0, start_clocked = 0, stop_clocked = 0;
    reg [1:0] state = `STATE_IDLE, next_state = `STATE_IDLE;

    assign state_out = state;
    assign clk_out = clk;
    always @(posedge clk_50M) begin
        clk_50M_count += 1;
        if (clk_50M_count >= 162) begin
            clk = ~clk;
            clk_50M_count = 0;
        end
    end

    always @*
    case (state)
        `STATE_IDLE: 
            if (clock_synced) next_state = `STATE_STARTED;
            else next_state = state;
        `STATE_STARTED:
            if (start_clocked) next_state = `STATE_DATA;
            else next_state = state;
        `STATE_DATA:
            if (!data_write) next_state = `STATE_STOP;
            else next_state = state;
        `STATE_STOP:
            if (stop_clocked) next_state = `STATE_IDLE;
            else next_state = state;
    endcase

    always @(posedge clk) begin
        state = next_state;
        if (receiving) sync_count += 1;
        case (state)
            `STATE_IDLE: begin
                if (rx === 0) receiving = 1;
                if (sync_count >= 7) begin
                    clock_synced = 1;
                    start_clocked = 0; 
                    sync_count = 0;
                end
            end
            `STATE_STARTED:
                if (sync_count >= 15) begin
                    start_clocked = 1;
                    data_write = 1;
                    data_ready = 0;
                    sync_count = 0;
                end
            `STATE_DATA:
                if (sync_count >= 15) begin
                    data_write = data_write << 1;
                    data = data >> 1; 
                    data[7] = rx;
                    stop_clocked = 0;
                    sync_count = 0;
                end
            `STATE_STOP: begin
                if (rx === 1) begin
                    stop_clocked = 1;
                    data_ready = 1;
                    clock_synced = 0;
                    receiving = 0;
                    sync_count = 0;
                end
            end
        endcase
    end


endmodule