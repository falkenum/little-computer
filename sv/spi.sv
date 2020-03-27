
`include "defs.vh"

`define STATE_IDLE 0
`define STATE_DELAYED 1
`define STATE_SELECT 2

module spi(
    input miso,
    input clk_800k,
    input begin_transaction,
    input rst,
    // input [`REG_WIDTH-1:0] transaction_length,
    output sck,
    // output mosi,
    output reg cs,
    output [2:0] state_out
    // output reg byte_ready
);

    reg [1:0] state = `STATE_IDLE, next_state = `STATE_IDLE;
    reg [2:0] sck_count = 0;
    integer delay_count = 0;
    reg delay_finished = 0;
    wire sck_en;

    assign state_out = state;
    assign sck_en = ~cs & delay_finished;
    assign sck = sck_en ? sck_count[2] : 0;

    always @*
    case(state)
        `STATE_IDLE: 
            if (begin_transaction) next_state = `STATE_DELAYED;
            else next_state = state;
        `STATE_DELAYED: 
            if (delay_finished) next_state = `STATE_SELECT; 
            else next_state = state;
        `STATE_SELECT: next_state = state; 
        default: next_state = `STATE_IDLE;
    endcase

    always @(posedge sck) begin
    end

    always @(posedge clk_800k, negedge rst)
    if (~rst) begin
        delay_finished = 0;
        delay_count = 0;
        state = `STATE_IDLE;
        sck_count = 0;
    end else begin
        state = next_state;
        sck_count += 1;

        if (delay_count >= 'h100)
            delay_finished = 1;

        case(state)
            `STATE_IDLE: begin
                cs = 1;
            end
            `STATE_DELAYED: begin
                cs = 0;
                if (!delay_finished)
                    delay_count += 1;
            end
            `STATE_SELECT: begin
                cs = 0;
            end
        endcase
    end

endmodule