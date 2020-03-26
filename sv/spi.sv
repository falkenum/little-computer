
`include "defs.vh"

`define STATE_IDLE 0
`define STATE_SELECTED 1

module spi(
    input miso,
    output clk,
    output mosi,
    output cs,
    output reg [7:0] data_received
    // output reg byte_ready
);

    reg state = `STATE_IDLE, next_state = `STATE_IDLE;
    reg [7:0] data_write = 0, data = 0;

    always @*
    case(state)
        `STATE_IDLE: 
            if (~cs) next_state = `STATE_SELECTED;
            else next_state = state;
        `STATE_SELECTED:
            if (cs) next_state = `STATE_IDLE;
            else next_state = state;
        default: next_state = `STATE_IDLE;
    endcase

    // always @(negedge data_write[7]) begin
    //     byte_ready = 1;
    // end

    always @(posedge clk) begin
        state = next_state;
        case(state)
            `STATE_IDLE: begin
            end
            `STATE_SELECTED: begin
                if (!data_write) begin
                    data_write = 1;
                    // byte_ready = 0;
                end
                data = data << 1;
                data[0] = mosi;

                data_write = data_write << 1;
                if (!data_write) begin 
                    data_received = data;
                    // byte_ready = 1;
                end
            end
        endcase
    end
endmodule