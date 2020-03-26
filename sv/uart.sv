`include "defs.vh"

`define STATE_IDLE 0
`define STATE_STARTED 1
`define STATE_DATA 2
`define STATE_PARITY 3
`define STATE_STOP 4

module uart(
    input rx,
    input clk_800k,
    output reg [7:0] data,
    output reg data_ready,
    output clk_out
);
    reg [7:0] data_write;
    reg [6:0] count = 0;
    reg clk_9600_baud = 0;
    reg start_clocked = 0, parity_clocked = 0, stop_clocked = 0;
    reg parity;
    reg [2:0] state, next_state;
    assign clk_out = clk_9600_baud;
    always @(posedge clk_800k) begin
        count = count + 1;
        if (count >= 42) begin
            clk_9600_baud = ~clk_9600_baud;
            count = 0;
        end
    end

    always @*
    case (state)
        `STATE_IDLE: 
            if (rx === 0) next_state = `STATE_STARTED;
        `STATE_STARTED:
            if (start_clocked) next_state = `STATE_DATA;
        `STATE_DATA:
            if (!data_write) next_state = `STATE_PARITY;
        `STATE_PARITY:
            if (!parity_clocked) next_state = `STATE_STOP;
        `STATE_STOP:
            if (stop_clocked) next_state = `STATE_IDLE;
    endcase
    always @(posedge clk_9600_baud) begin
        state = next_state;
        case (state)
            `STATE_IDLE: start_clocked = 0; 
            `STATE_STARTED: begin
                start_clocked = 1;
                data_write = 1;
                data_ready = 0;
            end
            `STATE_DATA: begin
                data_write = data_write << 1;
                data = data >> 1; 
                data[7] = rx;
            end
            `STATE_PARITY: begin
                parity_clocked = 1;
                parity = rx;
                stop_clocked = 0;
            end
            `STATE_STOP: begin
                stop_clocked = 1;
                data_ready = 1;
            end
        endcase
    end


endmodule