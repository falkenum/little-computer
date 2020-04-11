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

    input burst_en,
    input [24:0] addr,
    input [15:0] data_in,
    input refresh_data,
    output reg [15:0] data_out,
    output reg data_ready,
    output reg mem_ready,
    output reg [31:0][15:0] burst_buf
);

	// wait for 100 us, 5000 * 20 ns period
	localparam RST_WAIT_VAL = 5000;

    localparam STATE_WIDTH = 4;

	localparam STATE_RST_NOP = 0;
	localparam STATE_RST_PRECHARGE = 1;
	localparam STATE_RST_AUTO_REFRESH = 2;
	localparam STATE_RST_MODE_WRITE = 3;
	localparam STATE_IDLE = 4;
	localparam STATE_ACTIVATE = 5;
	localparam STATE_WRITE = 6;
	localparam STATE_READ = 7;
	localparam STATE_POST_READ = 8;
	localparam STATE_BURST_STOP = 9;
	localparam STATE_PRECHARGE = 10;

    localparam CMD_NOP = 3'b111;
    localparam CMD_PRE = 3'b010;
    localparam CMD_REF = 3'b001;
    localparam CMD_MRS = 3'b000;
    localparam CMD_ACT = 3'b011;
    localparam CMD_READ = 3'b101;
    localparam CMD_WRITE = 3'b100;
    localparam CMD_BST = 3'b110;

	reg [31:0] wait_count;
    reg [STATE_WIDTH-1:0] state;
    reg [2:0] cmd;
    reg [15:0] dq_val;
    reg drive_val;

    assign dram_cke = 1;
    assign dram_clk = clk;
    assign {dram_udqm, dram_ldqm} = 2'b0;
    assign dram_cs_n = 0;
    assign {dram_ras_n, dram_cas_n, dram_we_n} = cmd;
    assign dram_dq = drive_val ? dq_val : 16'bZ;

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
                next_state_func = STATE_IDLE;
            STATE_IDLE:
                if (refresh_data) begin
                    next_state_func = STATE_ACTIVATE;
                end
                else next_state_func = state;
            STATE_ACTIVATE:
                if (write_en) next_state_func = STATE_WRITE;
                else next_state_func = STATE_READ;
            STATE_WRITE: begin
                next_state_func = STATE_PRECHARGE;
            end
            STATE_READ: begin
                next_state_func = STATE_POST_READ;
            end
            STATE_POST_READ: begin
                // CAS latency is 2
                if ((~burst_en && wait_count == 2) ||
                 (burst_en && wait_count == 33)) next_state_func = STATE_BURST_STOP;
                else next_state_func = state;
            end
            STATE_BURST_STOP: begin
                next_state_func = STATE_PRECHARGE;
            end
            STATE_PRECHARGE: begin
                next_state_func = STATE_IDLE;
            end
            default: next_state_func = STATE_RST_NOP;

        endcase
        
    endfunction

    always @(posedge clk) begin
		if (~rst) begin
			wait_count <= 0;
            state <= STATE_RST_NOP;
            dq_val <= 16'bZ;
            data_out <= 0;
            data_ready <= 0;
            mem_ready <= 0;
            drive_val <= 0;
		end
        else begin
            state <= next_state_func(state);
            case(state)
                STATE_RST_NOP: begin
                    wait_count <= wait_count + 1;
                    cmd <= CMD_NOP;
                end
                STATE_RST_PRECHARGE: begin
                    cmd <= CMD_PRE;

                    // precharge all banks
                    dram_addr[10] <= 1;
                    wait_count <= 0;
                end
                STATE_RST_AUTO_REFRESH: begin
                    wait_count <= wait_count + 1;
                    cmd <= CMD_REF;
                end
                STATE_RST_MODE_WRITE: begin
                    cmd <= CMD_MRS;
                    dram_ba <= 2'b00;
                    // CAS latency = 2, burst length is page length, single write
                    dram_addr[12:0] <= {3'b000, 1'b1, 2'b0, 3'b010, 1'b0, 3'b111};
                    wait_count <= 0;
                end
                STATE_IDLE: begin
                    cmd <= CMD_NOP;
                    mem_ready <= 1;
                    data_ready <= 0;
                end
                STATE_ACTIVATE: begin
                    // $display("ctl activated at time %d for addr %x", $time, addr);
                    drive_val <= 0;

                    cmd <= CMD_ACT;
                    {dram_ba, dram_addr} <= addr[24:10];
                end
                STATE_WRITE: begin
                    // $display("ctl writing at time %d for addr %x", $time, addr);
                    cmd <= CMD_WRITE;
                    dq_val <= data_in;
                    {dram_ba, dram_addr[10:0]} <= {addr[24:23], 1'b0, addr[9:0]};
                    drive_val <= 1;
                end
                STATE_READ: begin
                    // $display("ctl reading at time %d for addr %x", $time, addr);
                    cmd <= CMD_READ;
                    {dram_ba, dram_addr[10:0]} <= {addr[24:23], 1'b0, addr[9:0]};
                    wait_count <= 0;
                end
                STATE_POST_READ: begin
                    cmd <= CMD_NOP;
                    wait_count <= wait_count + 1;
                    if (wait_count >= 2) begin

                        if (~burst_en) data_out <= dram_dq;
                        else begin
                            burst_buf[wait_count - 2] <= dram_dq;
                        end
                    end

                end
                STATE_BURST_STOP: begin
                    cmd <= CMD_BST;
                end
                STATE_PRECHARGE: begin
                    data_ready <= 1;
                    cmd <= CMD_PRE;
                end

            endcase
        end


    end
endmodule