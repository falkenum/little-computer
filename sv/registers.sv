`include "defs.vh"

module registers(
    input [`NumRegsWidth-1:0] rs, 
    input [`NumRegsWidth-1:0] rt, 
    input [`NumRegsWidth-1:0] rd, 
    input [`RegWidth-1:0] reg_in,
    input write_en,
    input clk,
    input rst,
    output [`RegWidth-1:0] rs_val,
    output [`RegWidth-1:0] rt_val,
    output [`RegWidth-1:0] rd_val,
    output reg [`RegWidth-1:0] reg_file [`NumRegs]
);
    assign rs_val = reg_file[rs];
    assign rt_val = reg_file[rt];
    assign rd_val = reg_file[rd];

    always @(posedge clk) begin
        if (rst & write_en) reg_file[rd] = reg_in;
    end
    always @* begin
        if (~rst) begin
            reg_file[0] = 0;
        end
    end
endmodule
