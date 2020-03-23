`include "defs.svh"

module registers(
    input [`NumRegsWidth-1:0] rs, 
    input [`NumRegsWidth-1:0] rt, 
    input [`NumRegsWidth-1:0] rd, 
    input [`RegWidth-1:0] reg_in,
    input write_en,
    input clk,
    output [`RegWidth-1:0] rs_val,
    output [`RegWidth-1:0] rt_val,
    output [`RegWidth-1:0] debug_reg_state [`NumRegs]
);
    reg [`RegWidth-1:0] reg_file [`NumRegs];

    assign debug_reg_state = reg_file;
    assign rs_val = reg_file[rs];
    assign rt_val = reg_file[rt];

    initial begin
        integer i;
        for (i=0; i < `NumRegs; i++)
           reg_file[i] <= 0;
    end

    always @(posedge clk) begin
        if (write_en) reg_file[rd] = reg_in;
    end
endmodule
