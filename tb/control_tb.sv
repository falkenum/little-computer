`include "defs.vh"
`timescale 1 ns / 1 ps

module control_tb;
    reg [`InstrWidth-1:0] instr;
    wire halted;
    wire jtype;
    wire reg_write_en;
    wire alu_use_imm;
    wire is_beq;
    wire [`AluOpWidth-1:0] alu_op;
   
    control control_comp(instr, halted, jtype, reg_write_en, alu_use_imm, is_beq, alu_op);

    initial begin
        instr = {`OP_HALT, 12'b0}; #10;
        `assert_eq(halted, 1);
        `assert_eq(reg_write_en, 0);
        `assert_eq(alu_use_imm, 0);
        instr = {`OP_ADD, 12'b0}; #10;
        `assert_eq(halted, 0);
        `assert_eq(reg_write_en, 1);
        `assert_eq(alu_op, 0);
        `assert_eq(alu_use_imm, 0);
        instr = {`OP_LSL, 12'b0}; #10;
        `assert_eq(halted, 0);
        `assert_eq(reg_write_en, 1);
        `assert_eq(alu_op, 1);
        `assert_eq(alu_use_imm, 0);
        instr = {`OP_ADDI, 12'b0}; #10;
        `assert_eq(halted, 0);
        `assert_eq(reg_write_en, 1);
        `assert_eq(alu_op, 0);
        `assert_eq(alu_use_imm, 1);
    end
endmodule
