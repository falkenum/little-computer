`include "defs.vh"
`timescale 1 ns / 1 ps

module control_tb;
    reg [`INSTR_WIDTH-1:0] instr;
    wire halted;
    wire jtype;
    wire is_beq;
    wire is_lw;
    wire alu_use_imm;
    wire reg_write_en;
    wire data_mem_en;
    wire [`ALU_OP_WIDTH-1:0] alu_op;
   
    control control_comp(
        .instr(instr), 
        .halted(halted), 
        .jtype(jtype), 
        .is_beq(is_beq), 
        .is_lw(is_lw), 
        .is_sw(is_sw),
        .alu_use_imm(alu_use_imm),
        .reg_write_en(reg_write_en), 
        .alu_op(alu_op));

    initial begin
        instr = {`OP_HALT, 12'b0}; #10;
        `ASSERT_EQ(halted, 1);
        `ASSERT_EQ(reg_write_en, 0);
        `ASSERT_EQ(alu_use_imm, 0);
        instr = {`OP_ADD, 12'b0}; #10;
        `ASSERT_EQ(halted, 0);
        `ASSERT_EQ(reg_write_en, 1);
        `ASSERT_EQ(alu_op, 0);
        `ASSERT_EQ(alu_use_imm, 0);
        instr = {`OP_LSL, 12'b0}; #10;
        `ASSERT_EQ(halted, 0);
        `ASSERT_EQ(reg_write_en, 1);
        `ASSERT_EQ(alu_op, 1);
        `ASSERT_EQ(alu_use_imm, 0);
        instr = {`OP_ADDI, 12'b0}; #10;
        `ASSERT_EQ(halted, 0);
        `ASSERT_EQ(reg_write_en, 1);
        `ASSERT_EQ(alu_op, 0);
        `ASSERT_EQ(alu_use_imm, 1);
    end
endmodule
