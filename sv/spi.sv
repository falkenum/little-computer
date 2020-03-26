
`include "defs.vh"

`define STATE_IDLE 0
`define STATE_SELECTED 1

module spi(
    input clk,
    input mosi,
    input miso,
    input cs,
    output reg [7:0] data
);

    reg state = `STATE_IDLE, next_state = `STATE_IDLE;
    always @*
    case(state)
        `STATE_IDLE: 
            if (~cs) next_state = `STATE_SELECTED;
            else next_state = state;
        `STATE_SELECTED:
            if (cs) next_state = `STATE_IDLE;
            else next_state = state;
    endcase

    always @(posedge clk) begin
        state = next_state;
        case(state)
            // `STATE_IDLE: begin
            //     data_write = 1;
            // end
            `STATE_SELECTED: begin
                data = data << 1;
                data[0] = mosi;
            end
        endcase
    end
endmodule