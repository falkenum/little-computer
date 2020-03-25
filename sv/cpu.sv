`include "defs.vh"


module cpu (
    input CLK_50,
    input KEY0,
    input GSENSOR_INT1,
    input GSENSOR_INT2,
    output GSENSOR_CS_n,
    output GSENSOR_SCLK,
    output GSENSOR_SDO,
    output [7:0] GPIO_DEBUG,
    inout GSENSOR_SDA
);
	// i2c mode
	assign GSENSOR_CS_n = 1;
	// primary address mode, 0x1D is the address
	assign GSENSOR_SDO = 1;
    assign GPIO_DEBUG = {clk_800k, KEY0, GSENSOR_SCLK, GSENSOR_SDA, 4'b0};

    reg [`REG_WIDTH-1:0] pc;
    reg [`INSTR_WIDTH-1:0] mem [`MEM_LEN];
    reg [5:0] clk_divided_count = 0;
    wire jtype, halted, reg_write_en, alu_use_imm, is_beq, regs_equal, beq_taken;
    wire is_lw, is_sw, clk_800k, rst;
    wire [`INSTR_WIDTH-1:0] instr;
    wire [`ALU_OP_WIDTH-1:0] alu_op;
    wire [`NUM_REGS_WIDTH-1:0] rs, rt, rd; 
    wire [`REG_WIDTH-1:0] rs_val, rt_val, rd_val, reg_in, alu_out, imm_extended, jimm_extended;
    wire [`IMM_WIDTH-1:0] imm;
    wire [`JIMM_WIDTH-1:0] jimm;

    assign clk_800k = clk_divided_count[5];
    assign instr = mem[pc];
    assign rst = KEY0;
    assign rs = instr[3*`NUM_REGS_WIDTH-1:2*`NUM_REGS_WIDTH];
    assign rt = instr[2*`NUM_REGS_WIDTH-1:`NUM_REGS_WIDTH];
    assign rd = instr[`NUM_REGS_WIDTH-1:0];
    assign beq_taken = is_beq & (rt_val == rd_val);

    assign imm = instr[(`INSTR_WIDTH-`OP_WIDTH-1):2*`NUM_REGS_WIDTH];
    assign imm_extended = {imm[`IMM_WIDTH-1] ? ~10'b0 : 10'b0, imm};
    assign jimm = instr[`JIMM_WIDTH-1:0];
    assign jimm_extended = {jimm[`JIMM_WIDTH-1] ? ~4'b0 : 4'b0, jimm};
    assign reg_in = is_lw ? mem[alu_out] : alu_out;

	// i2c mode
	assign GSENSOR_CS_n = 1;
	// primary address mode, 0x1D is the address
	assign GSENSOR_SDO = 1;

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
        .clk(clk_800k), 
        .rst(rst), 
        .rs_val(rs_val), 
        .rt_val(rt_val), 
        .rd_val(rd_val)
     );
    alu alu_comp(
        .op(alu_op), 
        .rs_val(alu_use_imm ? imm_extended : rs_val), 
        .rt_val(rt_val), 
        .result(alu_out));
    
    always @(posedge CLK_50) begin
        clk_divided_count += 1;
    end
    always @(posedge clk_800k, negedge rst) begin
        if (~rst) pc = 0;
        else begin
            pc = halted ? pc : 
                (beq_taken ? imm_extended + pc + 1 : 
                (jtype ? jimm_extended : pc + 1));
            if (is_sw) mem[alu_out] = rd_val;
        end
    end

    task load_instr(input [`MAX_PATH_LEN*8-1:0] instr_path, input integer num_instr);
        pc = 0;
        $readmemh(instr_path, mem, 0, num_instr-1);
    endtask
endmodule
