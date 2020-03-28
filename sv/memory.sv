`include "defs.vh"

module memory(
    input [`WORD_WIDTH-1:0] data_addr,
    input [`WORD_WIDTH-1:0] pc,
    input [`WORD_WIDTH-1:0] data_in,
    input clk,
    input write_en,
    output [`WORD_WIDTH-1:0] instr,
    output [`WORD_WIDTH-1:0] data_out
);
    reg [`WORD_WIDTH-1:0] mem [`MEM_LEN];

    assign instr = mem[pc];
    assign data_out = mem[data_addr];
    always @(posedge clk) begin
        if (write_en) begin
            // $display("writing %x to addr %x", data_in, data_addr);
            mem[data_addr] <= data_in;
        end 
    end
endmodule