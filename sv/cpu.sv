`include "defs.vh"


module cpu (
    input CLK,
    input RST,
    input GSENSOR_INT1,
    input GSENSOR_INT2,
    output GSENSOR_CS_n,
    output GSENSOR_SCLK,
    output GSENSOR_SDO,
    inout GSENSOR_SDA
);
    reg [`RegWidth-1:0] pc;
    reg [`InstrWidth-1:0] mem [`MemLen];
    wire jtype, halted, reg_write_en, alu_use_imm, is_beq, regs_equal, beq_taken;
    wire is_lw, is_sw;
    wire [`InstrWidth-1:0] instr;
    wire [`AluOpWidth-1:0] alu_op;
    wire [`NumRegsWidth-1:0] rs, rt, rd; 
    wire [`RegWidth-1:0] rs_val, rt_val, rd_val, reg_in, alu_out, imm_extended, jimm_extended;
    wire [`ImmWidth-1:0] imm;
    wire [`JImmWidth-1:0] jimm;
    wire [`RegWidth-1:0] reg_file [`NumRegs];

    assign instr = mem[pc];
    assign rs = instr[3*`NumRegsWidth-1:2*`NumRegsWidth];
    assign rt = instr[2*`NumRegsWidth-1:`NumRegsWidth];
    assign rd = instr[`NumRegsWidth-1:0];
    assign beq_taken = is_beq & (rt_val == rd_val);

    assign imm = instr[(`InstrWidth-`OpWidth-1):2*`NumRegsWidth];
    assign imm_extended = {imm[`ImmWidth-1] ? ~10'b0 : 10'b0, imm};
    assign jimm = instr[`JImmWidth-1:0];
    assign jimm_extended = {jimm[`JImmWidth-1] ? ~4'b0 : 4'b0, jimm};
    assign reg_in = is_lw ? mem[alu_out] : alu_out;

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
    registers registers_comp(
        .rs(rs), 
        .rt(rt), 
        .rd(rd), 
        .reg_in(reg_in), 
        .write_en(reg_write_en), 
        .clk(CLK), 
        .rst(RST), 
        .rs_val(rs_val), 
        .rt_val(rt_val), 
        .rd_val(rd_val), 
        .reg_file(reg_file));
    alu alu_comp(
        .op(alu_op), 
        .rs_val(alu_use_imm ? imm_extended : rs_val), 
        .rt_val(rt_val), 
        .result(alu_out));
    i2c i2c_comp(
        .clk(CLK),
        .rst(RST),
        .GSENSOR_INT1(GSENSOR_INT1),
        .GSENSOR_INT2(GSENSOR_INT2),
        .GSENSOR_SCLK(GSENSOR_SCLK),
        .GSENSOR_CS_n(GSENSOR_CS_n),
        .GSENSOR_SDO(GSENSOR_SDO),
        .GSENSOR_SDA(GSENSOR_SDA)
    );
    
    always @(posedge CLK) begin
        pc = halted ? pc : 
             (beq_taken ? imm_extended + pc + 1 : 
             (jtype ? jimm_extended : pc + 1));
        if (is_sw) begin
            mem[alu_out] = rd_val;
        end
    end

    always @* begin
        if (~RST) begin
            pc = 0;
        end
    end

    task load_instr(input [`MAX_PATH_LEN*8-1:0] instr_path, input integer num_instr);
        pc = 0;
        $readmemh(instr_path, mem, 0, num_instr-1);
    endtask
endmodule
