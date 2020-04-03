`include "defs.vh"

module registers(
    input [`NUM_REGS_WIDTH-1:0] rs, 
    input [`NUM_REGS_WIDTH-1:0] rt, 
    input [`NUM_REGS_WIDTH-1:0] rd, 
    input [`WORD_WIDTH-1:0] reg_in,
    input write_en,
    input clk,
    input rst,
    output reg [`WORD_WIDTH-1:0] rs_val,
    output reg [`WORD_WIDTH-1:0] rt_val,
    output reg [`WORD_WIDTH-1:0] rd_val
);
    reg [`WORD_WIDTH-1:0] reg_file [`NUM_REGS];
    assign rs_val = reg_file[rs];
    assign rt_val = reg_file[rt];
    assign rd_val = reg_file[rd];

    always @(posedge clk) begin
        if (~rst) reg_file[0] = 0;
        if (write_en) begin
            // $display("writing value %x to register %x", reg_in, rd);
            reg_file[rd] = reg_in;
        end
    end
endmodule
