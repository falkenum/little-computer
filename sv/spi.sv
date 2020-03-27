
`include "defs.vh"

`define STATE_IDLE 0
`define STATE_SELECT 1

module spi(
    input miso,
    input clk_800k,
    input begin_transaction,
    input [`REG_WIDTH-1:0] transaction_length,
    output sck,
    output mosi,
    output reg cs,
    output state_out
    // output reg byte_ready
);

    reg state = `STATE_IDLE, next_state = `STATE_IDLE;
    reg [2:0] sck_count = 3'b0;
    reg [7:0] delay_count = 0;
    reg delay_finished;
    wire sck_en;

    assign state_out = state;
    assign sck_en = ~cs & delay_finished;
    assign sck = sck_en ? sck_count[2] : 1'b0;

    always @*
    case(state)
        `STATE_IDLE: 
            if (begin_transaction) next_state = `STATE_SELECT;
            else next_state = state;
        `STATE_SELECT: next_state = state; 
        default: next_state = `STATE_IDLE;
    endcase

    always @(posedge sck) begin
    end

    always @(posedge clk_800k) begin
        state = next_state;
        sck_count += 1;
        case(state)
            `STATE_IDLE: begin
                cs = 1;
                delay_finished = 0;
                delay_count = 0;
            end
            `STATE_SELECT: begin
                delay_count += 1;
                if (delay_count == 0)
                    start_delay_finished = 1;
                cs = 0;
            end
        endcase
    end

endmodule