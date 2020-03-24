`include "defs.vh"

module cpu (
    input CLK
);
    reg [`RegWidth-1:0] pc;
    reg [`InstrWidth-1:0] instr_mem [`InstrMemLen-1:0];

    wire halted, reg_write_en, alu_use_imm, is_beq, regs_equal, beq_taken;
    wire [`InstrWidth-1:0] instr;
    wire [`AluOpWidth-1:0] alu_op;

    wire [`NumRegsWidth-1:0] rs, rt, rd; 
    wire [`RegWidth-1:0] rs_val, rt_val, rd_val, reg_in, imm_extended;

    wire [`ImmWidth-1:0] imm;

    wire [`RegWidth-1:0] reg_state [`NumRegs];

    assign instr = instr_mem[pc];
    assign rs = instr[3*`NumRegsWidth-1:2*`NumRegsWidth];
    assign rt = instr[2*`NumRegsWidth-1:`NumRegsWidth];
    assign rd = instr[`NumRegsWidth-1:0];
    assign beq_taken = is_beq & (rt_val == rd_val);

    assign imm = instr[(`InstrWidth-`OpWidth-1):2*`NumRegsWidth];
    assign imm_extended = {imm[`ImmWidth-1] ? ~10'b0 : 10'b0, imm};

    control control_comp(instr, halted, reg_write_en, alu_use_imm, is_beq, alu_op);
    registers registers_comp(rs, rt, rd, reg_in, reg_write_en, CLK, rs_val, rt_val, rd_val, reg_state);
    alu alu_comp(alu_op, alu_use_imm ? imm_extended : rs_val, rt_val, reg_in);
    
    always @(posedge CLK) begin
        pc = halted ? pc : (beq_taken ? imm_extended + pc + 1 : pc + 1);
    end

    task load_instr(input [`MAX_PATH_LEN*8-1:0] instr_path, input integer num_instr);
        pc = 0;
        $readmemh(instr_path, instr_mem, 0, num_instr-1);
    endtask
endmodule
