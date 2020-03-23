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
    output reg [`RegWidth-1:0] reg_file [`NumRegs]
);
    assign rs_val = reg_file[rs];
    assign rt_val = reg_file[rt];

    initial begin
        integer i;
        for (i=0; i < `NumRegs; i++)
           reg_file[i] <= 0;
    end

    always @(posedge clk) begin
        if (write_en) reg_file[rd] = reg_in;
		// $display("write_en: %b", write_en);
		// $display(reg_in);
		// $display(rd);
	   
    end
endmodule
