`include "defs.vh"

module registers(
    input [`NUM_REGS_WIDTH-1:0] rs, 
    input [`NUM_REGS_WIDTH-1:0] rt, 
    input [`NUM_REGS_WIDTH-1:0] rd, 
    input [`REG_WIDTH-1:0] reg_in,
    input write_en,
    input clk,
    input rst,
    output [`REG_WIDTH-1:0] rs_val,
    output [`REG_WIDTH-1:0] rt_val,
    output [`REG_WIDTH-1:0] rd_val
);
    reg [`REG_WIDTH-1:0] reg_file [`NUM_REGS];
    assign rs_val = reg_file[rs];
    assign rt_val = reg_file[rt];
    assign rd_val = reg_file[rd];

    always @(posedge clk, negedge rst) begin
        if (~rst) reg_file[0] = 0;
        else if (write_en) begin
            // $display("writing value %x to register %x", reg_in, rd);
            reg_file[rd] = reg_in;
        end
    end
endmodule
