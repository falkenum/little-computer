`include "defs.svh"


module cpu(
    input CLK,
    output [`RegWidth-1:0] debug_reg_state [`NumRegs],
    output halted
);
	reg [`RegWidth-1:0] pc = 0;
    wire [`InstrWidth-1:0] instr;
    wire reg_write_en;
    wire [`AluOpWidth-1:0] alu_op;

    wire [`NumRegsWidth-1:0] rs; 
    wire [`NumRegsWidth-1:0] rt; 
    wire [`NumRegsWidth-1:0] rd; 
    wire [`RegWidth-1:0] reg_in;
    wire [`RegWidth-1:0] rs_val;
    wire [`RegWidth-1:0] rt_val;

    assign rs = instr[3*`NumRegsWidth-1:2*`NumRegsWidth];
    assign rt = instr[2*`NumRegsWidth-1:`NumRegsWidth];
    assign rd = instr[`NumRegsWidth-1:0];
   
    instr_mem instr_mem_comp(pc, instr);
    control control_comp(instr, halted, reg_write_en, alu_op);
    registers registers_comp(rs, rt, rd, reg_in, reg_write_en, CLK, rs_val, rt_val, debug_reg_state);
   
    alu alu_comp(alu_op, rs_val, rt_val, reg_in);
    
    always @(posedge CLK) begin
        pc = halted ? pc : pc + 1;
    end
   
endmodule
