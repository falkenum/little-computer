`include "defs.vh"

module cpu(
    input clk,
    input clk_stb_800k,
    input rst,
    input [`WORD_WIDTH-1:0] instr,
    input [`WORD_WIDTH-1:0] data_in,
    input debug_clk,
    input debug_mode,
    output [`WORD_WIDTH-1:0] data_addr,
    output [`WORD_WIDTH-1:0] data_out,
    output reg [`WORD_WIDTH-1:0] pc,
    output mem_write_en
);


    reg [`WORD_WIDTH-1:0] sp;
    reg [`NUM_REGS-1:0][`WORD_WIDTH-1:0] reg_file;
    // reg [1:0] cpu_clk_vals;

    wire [`OP_WIDTH-1:0] op = instr[`WORD_WIDTH-1:`WORD_WIDTH-`OP_WIDTH];
    wire [`NUM_REGS_WIDTH-1:0] rs = instr[3*`NUM_REGS_WIDTH-1:2*`NUM_REGS_WIDTH];
    wire [`NUM_REGS_WIDTH-1:0] rt = instr[2*`NUM_REGS_WIDTH-1:`NUM_REGS_WIDTH];
    wire [`NUM_REGS_WIDTH-1:0] rd = instr[`NUM_REGS_WIDTH-1:0];
    wire [`WORD_WIDTH-1:0] rs_val = reg_file[rs], rt_val = reg_file[rt], rd_val = reg_file[rd];
    wire is_beq = op == `OP_BEQ;
    wire halted = op == `OP_HALT;
    wire jtype = op == `OP_J | op == `OP_JL;
    wire is_lw = op == `OP_LW;
    wire is_sw = op == `OP_SW;
    wire use_data_in = is_lw | (op == `OP_POP);
    wire itype = op[`OP_WIDTH-1:`OP_WIDTH-2] == 'b01;
    wire alu_use_imm = itype & ~is_beq;
    wire reg_write_en = op[`OP_WIDTH-1:`OP_WIDTH-2] == 'b00 | op == `OP_ADDI | op == `OP_LW | op == `OP_POP;
    wire beq_taken = is_beq & (rt_val == rd_val);

    wire [`ALU_OP_WIDTH-1:0] alu_op = (is_lw | is_sw) ? `ALU_OP_ADD : op[`OP_WIDTH-3:`OP_WIDTH-4];
    wire [`IMM_WIDTH-1:0] imm = instr[(`WORD_WIDTH-`OP_WIDTH-1):2*`NUM_REGS_WIDTH];
    wire [`JIMM_WIDTH-1:0] jimm = instr[`JIMM_WIDTH-1:0];
    wire [`WORD_WIDTH-1:0] imm_extended = {imm[`IMM_WIDTH-1] ? ~10'b0 : 10'b0, imm};
    wire [`WORD_WIDTH-1:0] jimm_extended = {jimm[`JIMM_WIDTH-1] ? ~4'b0 : 4'b0, jimm};
    wire [`WORD_WIDTH-1:0] alu_out;
    wire [`WORD_WIDTH-1:0] reg_in = use_data_in ? data_in : alu_out;


    assign data_addr = op == `OP_PUSH ? sp :
                       (op == `OP_POP ? sp + 1 : alu_out);
    assign data_out = rd_val;
    assign mem_write_en = is_sw | op == `OP_PUSH;

    alu alu_c(
        .op(alu_op), 
        .rs_val(alu_use_imm ? imm_extended : rs_val), 
        .rt_val(rt_val), 
        .result(alu_out)
    );

    localparam STACK_BEGIN = 16'hF7FF;

    always @(posedge clk) begin
        // cpu_clk_vals = {cpu_clk_vals[0], cpu_clk};
        if (~rst) begin 
            // first clk strobe will change the pc to 0
            pc <= 16'hFFFF;
            sp <= STACK_BEGIN;
            // cpu_clk_vals <= 2'b11;
            reg_file <= 0;
        end

        // posedge of cpu clk
        else if (clk_stb_800k) begin
            // $display("pc changed at time ", $time);
            
            // r7 is lr
            reg_file[7] <= op == `OP_JL ? pc + 1 : reg_file[7];
            sp <= op == `OP_PUSH ? sp - 1 :
                 (op == `OP_POP ? sp + 1 : sp);

            // $display("cpu is halted: %b", halted);
            pc <= pc == 'hFFFF ? 0 : 
                (halted ? pc : 
                (beq_taken ? imm_extended + pc + 1 : 
                (jtype ? jimm_extended : 
                (op == `OP_RTS ? reg_file[7] : pc + 1))));
            // $display("pc is now: %x", pc);
            if (reg_write_en) begin
                // $display("rs_val: %x, rt_val: %x, rs: %x, rt: %x", rs_val, rt_val, rs, rt);
                // $display("writing value %x to register %x", reg_in, rd);
                reg_file[rd] <= reg_in;
            end
        end
    end
endmodule
