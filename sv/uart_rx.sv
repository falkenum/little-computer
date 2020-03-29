`include "defs.vh"

`define STATE_IDLE 0
`define STATE_START 1
`define STATE_DATA 2
`define STATE_STOP 3

module uart_rx(
    input rx,
    input clk_25M,
    output reg [7:0] data,
    output reg data_ready
);
    reg [7:0] data_write;
    reg [7:0] clk_25M_count = 0;
    reg [5:0] sync_count = 0;
    reg clk = 0;
    reg receiving = 0, clock_synced = 0, stop_clocked = 0;
    reg [1:0] state = `STATE_IDLE, next_state = `STATE_IDLE;

    always @(posedge clk_25M) begin
        clk_25M_count += 1;

        // 81 is the value to turn 25MHz into 9600 baud * 16
        if (clk_25M_count >= 81) begin
            clk = ~clk;
            clk_25M_count = 0;
        end
    end

    always @*
    case (state)
        `STATE_IDLE: 
            if (receiving) next_state = `STATE_START;
            else next_state = state;
        `STATE_START:
            if (clock_synced) next_state = `STATE_DATA;
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
                if (rx === 0) begin 
                    data_ready = 0;
                    receiving = 1;
                    stop_clocked = 0;
                    clock_synced = 0;
                    data_write = 1;
                end
            end
            `STATE_START:
                if (sync_count >= 8) begin
                    clock_synced = 1;
                    sync_count = 0;
                end
            `STATE_DATA:
                if (sync_count >= 16) begin
                    data_write = data_write << 1;
                    data = data >> 1; 
                    data[7] = rx;
                    sync_count = 0;
                end
            `STATE_STOP: begin
                if (rx === 1) begin
                    stop_clocked = 1;
                    data_ready = 1;
                    receiving = 0;
                    sync_count = 0;
                end
            end
        endcase
    end


endmodule