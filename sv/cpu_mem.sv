`include "defs.vh"

module cpu_mem(
    input [`WORD_WIDTH-1:0] data_addr,
    input [`WORD_WIDTH-1:0] pc,
    input [`WORD_WIDTH-1:0] data_in,
    input clk,
    input write_en,
    output reg [`WORD_WIDTH-1:0] instr,
    output reg [`WORD_WIDTH-1:0] data_out


);
    reg [`WORD_WIDTH-1:0] mem [`MEM_LEN];

    always @(posedge clk) begin
        // $display("memory clocked");
        if (write_en) begin
            // $display("writing %x to addr %x", data_in, data_addr);
            mem[data_addr] <= data_in;
        end 
        data_out <= mem[data_addr];
        instr <= mem[pc];
    end
endmodule