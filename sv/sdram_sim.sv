`include "defs.vh"

module sdram_sim(
	input		    [12:0]		addr,
	input		     [1:0]		ba,
	input		          		ras_n,
	input		          		cas_n,
	input		          		we_n,
	input		          		clk,
	inout 		    [15:0]		dq
);
    localparam CMD_NOP = 3'b111;
    localparam CMD_PRE = 3'b010;
    localparam CMD_REF = 3'b001;
    localparam CMD_MRS = 3'b000;
    localparam CMD_ACT = 3'b011;
    localparam CMD_READ = 3'b101;
    localparam CMD_WRITE = 3'b100;
    localparam CMD_BST = 3'b110;

    localparam STATE_IDLE = 0;
    localparam STATE_ACTIVATED = 1;
    localparam STATE_CMD_WRITE = 2;
    localparam STATE_CMD_READ = 3;

    wire [2:0] cmd = {ras_n, cas_n, we_n};
    reg [1:0] state = STATE_IDLE;
    reg [15:0] mem [1 << 19];
    reg precharged = 0, drive_val = 0;
    reg [15:0] dq_val;
    reg [6:0] state_read_count = 0;
    assign dq = drive_val ? dq_val : 16'bZ;

    function [1:0] next_state_func;
        input [1:0] state;

        case(state)
            STATE_IDLE:
                if (cmd == CMD_ACT) next_state_func = STATE_ACTIVATED;
                else next_state_func = state;
            STATE_ACTIVATED:
                if (cmd == CMD_WRITE) next_state_func = STATE_CMD_WRITE;
                else if (cmd == CMD_READ) next_state_func = STATE_CMD_READ;
                else next_state_func = state;
            STATE_CMD_WRITE:
                next_state_func = STATE_IDLE;
            STATE_CMD_READ:
                if ((state_read_count >= 2 && cmd == CMD_BST) || state_read_count == 66) next_state_func = STATE_IDLE;
                else next_state_func = state;
            default: next_state_func = STATE_IDLE;
        endcase
    endfunction

    always @(posedge clk) begin
        state = next_state_func(state);
        case(state)
            STATE_IDLE: begin
                state_read_count = 0;
            end
            STATE_ACTIVATED: begin
            end
            STATE_CMD_WRITE: begin
                $display("writing %x to addr %x", dq, addr);
                mem[addr[18:0]] = dq;
                $display("reading %x from addr %x", mem[addr[18:0]], addr);
            end
            STATE_CMD_READ: begin
                state_read_count += 1;

                if (state_read_count >= 2)
                    dq_val = mem[addr[18:0] + state_read_count - 2];
                drive_val = 1;
            end
        endcase
    end
endmodule