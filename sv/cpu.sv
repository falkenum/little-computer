`include "defs.vh"

module cpu(
    input clk,
    input rst,
    input [`WORD_WIDTH-1:0] instr,
    input [`WORD_WIDTH-1:0] data_in,
    output [`WORD_WIDTH-1:0] data_addr,
    output [`WORD_WIDTH-1:0] data_out,
    output reg [`WORD_WIDTH-1:0] pc,
    output reg mem_write_en
);

    assign data_addr = alu_out;
    assign data_out = rd_val;

    wire is_beq = op == `OP_BEQ;
    wire halted = op == `OP_HALT;
    wire jtype = op == `OP_J;
    wire is_lw = op == `OP_LW;
    wire is_sw = op == `OP_SW;
    wire itype = op[`OP_WIDTH-1:`OP_WIDTH-2] == 'b01;
    wire alu_use_imm = itype & ~is_beq;
    wire reg_write_en = op[`OP_WIDTH-1:`OP_WIDTH-2] == 'b00 | op == `OP_ADDI | op == `OP_LW;
    wire beq_taken = is_beq & (rt_val == rd_val);

    wire [`OP_WIDTH-1:0] op = instr[`WORD_WIDTH-1:`WORD_WIDTH-`OP_WIDTH];
    wire [`ALU_OP_WIDTH-1:0] alu_op = (is_lw | is_sw) ? `ALU_OP_ADD : op[`OP_WIDTH-3:`OP_WIDTH-4];

    wire [`NUM_REGS_WIDTH-1:0] rs = instr[3*`NUM_REGS_WIDTH-1:2*`NUM_REGS_WIDTH];
    wire [`NUM_REGS_WIDTH-1:0] rt = instr[2*`NUM_REGS_WIDTH-1:`NUM_REGS_WIDTH];
    wire [`NUM_REGS_WIDTH-1:0] rd = instr[`NUM_REGS_WIDTH-1:0];

    wire [`IMM_WIDTH-1:0] imm = instr[(`WORD_WIDTH-`OP_WIDTH-1):2*`NUM_REGS_WIDTH];
    wire [`JIMM_WIDTH-1:0] jimm = instr[`JIMM_WIDTH-1:0];

    wire [`WORD_WIDTH-1:0] imm_extended = {imm[`IMM_WIDTH-1] ? ~10'b0 : 10'b0, imm};
    wire [`WORD_WIDTH-1:0] jimm_extended = {jimm[`JIMM_WIDTH-1] ? ~4'b0 : 4'b0, jimm};
    wire [`WORD_WIDTH-1:0] reg_in = is_lw ? data_in : alu_out;

    wire [`WORD_WIDTH-1:0] rs_val, rt_val, rd_val, alu_out;

    registers registers_c(
        .rs(rs), 
        .rt(rt), 
        .rd(rd), 
        .reg_in(reg_in), 
        .write_en(reg_write_en), 
        .clk(clk), 
        .rst(rst), 
        .rs_val(rs_val), 
        .rt_val(rt_val), 
        .rd_val(rd_val)
    );

    alu alu_c(
        .op(alu_op), 
        .rs_val(alu_use_imm ? imm_extended : rs_val), 
        .rt_val(rt_val), 
        .result(alu_out)
    );

    always @(posedge clk, negedge rst) begin
        if (~rst) begin 
            pc = 0;
            mem_write_en = 0;
        end
        else begin
            pc = halted ? pc : 
                (beq_taken ? imm_extended + pc + 1 : 
                (jtype ? jimm_extended : pc + 1));

            // need to make sure word is clocked into mem following the sw instruction
            // to give time for alu to output the right value
            if (mem_write_en) mem_write_en = 0;
            if (is_sw) begin
                mem_write_en = 1;
            end
        end
    end
endmodule
