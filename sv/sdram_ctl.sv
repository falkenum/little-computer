`include "defs.vh"

module sdram_ctl(
	output dram_clk,
	output dram_cs_n,
	output dram_ldqm,
	output dram_udqm,
	output reg [12:0] dram_addr,
	output reg [1:0] dram_ba,
	output dram_cke,
	output dram_cas_n,
	output dram_ras_n,
	output dram_we_n,
	inout [15:0] dram_dq,

    input rst,
    input clk, 
    input write_en,

    // 2**25 addresses for 16 bit words
    input [24:0] addr,
    input [15:0] data_in,
    output reg [15:0] data_out
);

	// wait for 100 us, 5000 * 20 ns period
	localparam RST_WAIT_VAL = 5000;

    localparam STATE_WIDTH = 4;

	localparam STATE_RST_NOP = 0;
	localparam STATE_RST_PRECHARGE = 1;
	localparam STATE_RST_AUTO_REFRESH = 2;
	localparam STATE_RST_MODE_WRITE = 3;
	localparam STATE_ACTIVATE = 4;
	localparam STATE_WRITE = 5;
	localparam STATE_POST_WRITE_NOP = 6;
	localparam STATE_READ = 7;
	localparam STATE_POST_READ_NOP = 8;
	localparam STATE_READ_COMPLETE = 9;

    localparam CMD_NOP = 3'b111;
    localparam CMD_PRE = 3'b010;
    localparam CMD_REF = 3'b001;
    localparam CMD_MRS = 3'b000;
    localparam CMD_ACT = 3'b011;
    localparam CMD_READ = 3'b101;
    localparam CMD_WRITE = 3'b100;

    assign dram_cke = 1;
    assign dram_clk = clk;
    assign {dram_udqm, dram_ldqm} = 2'b0;
    assign dram_cs_n = 0;
    assign {dram_ras_n, dram_cas_n, dram_we_n} = cmd;
    assign dram_dq = state == STATE_WRITE ? dq_val : 16'bZ;


	reg [31:0] wait_count = 0;
    reg [STATE_WIDTH-1:0] state = STATE_RST_NOP;
    reg [2:0] cmd = CMD_NOP;
    reg [15:0] data_in_r, dq_val = 16'bZ;
    reg [24:0] addr_r;
    reg write_en_r;


    function [STATE_WIDTH-1:0] next_state_func;
        input [STATE_WIDTH-1:0] state;
        case(state)
            STATE_RST_NOP: 
                if (wait_count == RST_WAIT_VAL)
                    next_state_func = STATE_RST_PRECHARGE;
                else next_state_func = state;
            STATE_RST_PRECHARGE: begin
                next_state_func = STATE_RST_AUTO_REFRESH;
            end
            STATE_RST_AUTO_REFRESH:
                if (wait_count == 8)
                    next_state_func = STATE_RST_MODE_WRITE;
                else next_state_func = state;
            STATE_RST_MODE_WRITE:
                next_state_func = STATE_ACTIVATE;
            STATE_ACTIVATE:
                if (write_en_r) next_state_func = STATE_WRITE;
                else next_state_func = STATE_READ;
            STATE_WRITE: begin
                next_state_func = STATE_POST_WRITE_NOP;
            end
            STATE_POST_WRITE_NOP:
                // wait for data to propagate, not sure how many cycles this actually needs to be
                // 5 seems to work
                if (wait_count == 5) next_state_func = STATE_READ;
                else next_state_func = state;
            STATE_READ: begin
                next_state_func = STATE_POST_READ_NOP;
            end
            STATE_POST_READ_NOP:
                // CAS latency is 2
                if (wait_count == 2) next_state_func = STATE_READ_COMPLETE;
                else next_state_func = state;
            STATE_READ_COMPLETE:
                next_state_func = STATE_ACTIVATE;
            default: begin
                next_state_func = STATE_RST_NOP;
            end
        endcase
        
    endfunction

    always @(posedge clk) begin
		if (~rst) begin
			wait_count = 0;
            state = STATE_RST_NOP;
            dq_val = 16'bZ;
		end
        wait_count += 1;
        state = next_state_func(state);
        case(state)
            STATE_RST_NOP: begin
                cmd = CMD_NOP;
            end
            STATE_RST_PRECHARGE: begin
                cmd = CMD_PRE;

                // precharge all banks
                dram_addr[10] = 1;
                wait_count = 0;
            end
            STATE_RST_AUTO_REFRESH: begin
                cmd = CMD_REF;
            end
            STATE_RST_MODE_WRITE: begin
                cmd = CMD_MRS;
                dram_ba = 2'b00;
                // CAS latency = 2, burst length 1
                dram_addr[12:0] = {3'b000, 1'b0, 2'b0, 3'b010, 1'b0, 3'b000};
                wait_count = 0;
            end
            STATE_ACTIVATE: begin
                write_en_r = write_en;
                addr_r = addr;
                data_in_r = data_in;

                cmd = CMD_ACT;
                {dram_ba, dram_addr} = addr_r[24:10];
            end
            STATE_WRITE: begin
                cmd = CMD_WRITE;
                dq_val = data_in_r;
                {dram_ba, dram_addr[10:0]} = {addr_r[24:23], 1'b0, addr_r[9:0]};
                wait_count = 0;
            end
            STATE_POST_WRITE_NOP: begin
                cmd = CMD_NOP;
            end
            STATE_READ: begin
                cmd = CMD_READ;
                {dram_ba, dram_addr[10:0]} = {addr_r[24:23], 1'b1, addr_r[9:0]};
                wait_count = 0;
            end
            STATE_POST_READ_NOP: begin
                cmd = CMD_NOP;
            end
            STATE_READ_COMPLETE: begin
                cmd = CMD_NOP;
                data_out = dram_dq;
            end
        endcase
    end
endmodule