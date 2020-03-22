`include "defs.h"

module cpu(
    input CLK,
    output [`RegWidth-1:0] debug_reg_state [`NumRegsWidth-1:0]
);
	reg [`RegWidth-1:0] pc = 0;
    wire [`InstrWidth-1:0] instr;
    wire is_halt, reg_write_en;
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
    control control_comp(instr, is_halt, reg_write_en, alu_op);
    registers registers_comp(rs, rt, rd, reg_in, reg_write_en, CLK, rs_val, rt_val, debug_reg_state);
   
    alu alu_comp(alu_op, rs_val, rt_val, reg_in);
    
    always @(posedge CLK) begin
        pc = is_halt ? pc : pc + 1;
    end
   
endmodule

module control(
    input [`InstrWidth-1:0] instr,
    output is_halt,
    output reg_write_en,
    output [`AluOpWidth-1:0] alu_op
);
    wire [`OpWidth-1:0] op;
    assign op = instr[`InstrWidth-1:`InstrWidth-`OpWidth];
    
  
    assign is_halt = op == `OP_HALT;
    assign reg_write_en = instr[`OpWidth-1:`OpWidth-2] == 2'b0;
    assign alu_op = instr[`OpWidth-3:`OpWidth-4];
   
   
endmodule

module instr_mem(
    input [`RegWidth-1:0] addr,
    output [`InstrWidth-1:0] instr
);
    reg [`InstrWidth-1:0] mem [(1 << `RegWidth)-1:0];
    assign instr = mem[addr];

    initial begin
        $readmemh("mem/add.mem", mem, 0, 3);
    end
endmodule
   
module registers(
    input [`NumRegsWidth-1:0] rs, 
    input [`NumRegsWidth-1:0] rt, 
    input [`NumRegsWidth-1:0] rd, 
    input [`RegWidth-1:0] reg_in,
    input write_en,
    input clk,
    output [`RegWidth-1:0] rs_val,
    output [`RegWidth-1:0] rt_val,
    output [`RegWidth-1:0] debug_reg_state [`NumRegsWidth-1:0]
);
    reg [`RegWidth-1:0] reg_file [`NumRegsWidth-1:0];

    assign debug_reg_state = reg_file;
    assign rs_val = reg_file[rs];
    assign rt_val = reg_file[rt];

    initial begin
        integer i;
        for (i=0; i < 1 << `NumRegsWidth; i++) begin
            reg_file[i] <= 0;
        end
    end

    always @(posedge clk) begin
        if (write_en) reg_file[rd] = reg_in;
    end
endmodule
