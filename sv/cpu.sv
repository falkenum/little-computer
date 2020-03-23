`include "defs.vh"

module cpu (
    input CLK,
    output halted,
    output [`RegWidth-1:0] reg_state [`NumRegs],
    output reg [`RegWidth-1:0] pc
);
    reg [`InstrWidth-1:0] instr_mem [`InstrMemLen-1:0];
    wire [`InstrWidth-1:0] instr;
    wire reg_write_en, itype;
    wire [`AluOpWidth-1:0] alu_op;

    wire [`NumRegsWidth-1:0] rs; 
    wire [`NumRegsWidth-1:0] rt; 
    wire [`NumRegsWidth-1:0] rd; 
    wire [`RegWidth-1:0] reg_in;
    wire [`RegWidth-1:0] rs_val;
    wire [`RegWidth-1:0] rt_val;
    wire [`ImmWidth-1:0] imm;

    assign instr = instr_mem[pc];
    assign rs = instr[3*`NumRegsWidth-1:2*`NumRegsWidth];
    assign rt = instr[2*`NumRegsWidth-1:`NumRegsWidth];
    assign rd = instr[`NumRegsWidth-1:0];
    assign imm = {rs[`NumRegsWidth-1] ? 3'b111 : 3'b0, rs};

    control control_comp(instr, halted, reg_write_en, itype, alu_op);
    registers registers_comp(rs, rt, rd, reg_in, reg_write_en, CLK, rs_val, rt_val, reg_state);
    alu alu_comp(alu_op, itype ? imm : rs_val, rt_val, reg_in);
    
    always @(posedge CLK) begin
        pc = halted ? pc : pc + 1;
    end

    initial begin
        integer i;
        for (i = 0; i < 1 << `RegWidth; i++) begin
            instr_mem[i] <= 0;
        end
    end

    task load_instr(input [`MAX_PATH_LEN*8-1:0] instr_path, input integer num_instr);
        pc = 0;
        $readmemh(instr_path, instr_mem, 0, num_instr-1);
    endtask
endmodule
