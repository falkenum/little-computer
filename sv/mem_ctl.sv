`include "defs.vh"

module mem_ctl(
	output [12:0] dram_addr,
	output [1:0] dram_ba,
	output dram_cas_n,
	output dram_cke,
	output dram_clk,
	output dram_cs_n,
	inout [15:0] dram_dq,
	output dram_ldqm,
	output dram_ras_n,
	output dram_udqm,
	output dram_we_n,

    input rst,
    input clk, 
    input write_en,

    // 2**25 addresses for 16 bit words
    input [24:0] addr,
    input [`WORD_WIDTH-1:0] data_in,
    input [`WORD_WIDTH-1:0] data_out

);

    always @(posedge clk) begin
		if (~rst) begin
			// wait for 100 us
		end
    end
endmodule