`include "defs.vh"

`define SCL_ADDR 16'hF0
`define SDA_ADDR 16'hF1
`define SDA_CLEAR_ADDR 16'hF2
`define SEG_DISPLAY_OFF 8'hFF

module cpu(

	//////////// CLOCK //////////
	input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	input 		          		MAX10_CLK2_50,

	//////////// SDRAM //////////
	output		    [12:0]		DRAM_ADDR,
	output		     [1:0]		DRAM_BA,
	output		          		DRAM_CAS_N,
	output		          		DRAM_CKE,
	output		          		DRAM_CLK,
	output		          		DRAM_CS_N,
	inout 		    [15:0]		DRAM_DQ,
	output		          		DRAM_LDQM,
	output		          		DRAM_RAS_N,
	output		          		DRAM_UDQM,
	output		          		DRAM_WE_N,

	//////////// SEG7 //////////
	output		     [7:0]		HEX0,
	output		     [7:0]		HEX1,
	output		     [7:0]		HEX2,
	output		     [7:0]		HEX3,
	output		     [7:0]		HEX4,
	output		     [7:0]		HEX5,

	//////////// KEY //////////
	input 		     [1:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW,

	//////////// VGA //////////
	output		     [3:0]		VGA_B,
	output		     [3:0]		VGA_G,
	output		          		VGA_HS,
	output		     [3:0]		VGA_R,
	output		          		VGA_VS,

	//////////// Accelerometer //////////
	output		          		GSENSOR_CS_N,
	input 		     [2:1]		GSENSOR_INT,
	output		          		GSENSOR_SCLK,
	inout 		          		GSENSOR_SDI,
	output 		          		GSENSOR_SDO,

	//////////// Arduino //////////
	inout 		    [15:0]		ARDUINO_IO,
	inout 		          		ARDUINO_RESET_N,

	//////////// GPIO, GPIO connect to GPIO Default //////////
	output 		    [35:0]		DEBUGGPIO
);

    segdisplay seg0(~debug_mode, 0, pc[3:0], HEX0);
    segdisplay seg1(~debug_mode, 0, pc[7:4], HEX1);
    segdisplay seg2(~debug_mode, 1, instr[3:0], HEX2);
    segdisplay seg3(~debug_mode, 0, instr[7:4], HEX3);
    segdisplay seg4(~debug_mode, 0, instr[11:8], HEX4);
    segdisplay seg5(~debug_mode, 0, instr[15:12], HEX5);

    reg scl_r = 0, sda_r = 'bz;
    reg [`REG_WIDTH-1:0] pc;
    reg [`INSTR_WIDTH-1:0] mem [`MEM_LEN];
    reg [5:0] clk_divided_count = 0;
    wire jtype, halted, reg_write_en, alu_use_imm, is_beq, regs_equal, beq_taken;
    wire is_lw, is_sw, clk_800k, cpu_clk, rst, debug_mode;
    wire [`INSTR_WIDTH-1:0] instr;
    wire [`ALU_OP_WIDTH-1:0] alu_op;
    wire [`NUM_REGS_WIDTH-1:0] rs, rt, rd; 
    wire [`REG_WIDTH-1:0] rs_val, rt_val, rd_val, reg_in, alu_out, imm_extended, jimm_extended;
    wire [`IMM_WIDTH-1:0] imm;
    wire [`JIMM_WIDTH-1:0] jimm;


    assign debug_mode = SW[0];
    assign LEDR = {6'b0, MAX10_CLK1_50, clk_800k, GSENSOR_SCLK, KEY[0]};
	// i2c mode
	assign GSENSOR_CS_N = 1;
	// primary address mode, 0x1D is the address
	assign GSENSOR_SDO = 1;
    assign DEBUGGPIO = {clk_800k, KEY[0], GSENSOR_SCLK, GSENSOR_SDI, 4'b0};
    assign GSENSOR_SCLK = scl_r;
    assign GSENSOR_SDI = sda_r;
    assign clk_800k = clk_divided_count[5];
    assign cpu_clk = debug_mode ? ~KEY[1] : clk_800k;
    assign instr = mem[pc];
    assign rst = KEY[0];
    assign rs = instr[3*`NUM_REGS_WIDTH-1:2*`NUM_REGS_WIDTH];
    assign rt = instr[2*`NUM_REGS_WIDTH-1:`NUM_REGS_WIDTH];
    assign rd = instr[`NUM_REGS_WIDTH-1:0];
    assign beq_taken = is_beq & (rt_val == rd_val);

    assign imm = instr[(`INSTR_WIDTH-`OP_WIDTH-1):2*`NUM_REGS_WIDTH];
    assign imm_extended = {imm[`IMM_WIDTH-1] ? ~10'b0 : 10'b0, imm};
    assign jimm = instr[`JIMM_WIDTH-1:0];
    assign jimm_extended = {jimm[`JIMM_WIDTH-1] ? ~4'b0 : 4'b0, jimm};
    assign reg_in = is_lw ? (alu_out == `SDA_ADDR ? {15'b0, GSENSOR_SDI}: mem[alu_out]) : alu_out;

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
        .clk(cpu_clk), 
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
    
    always @(posedge MAX10_CLK1_50) begin
        clk_divided_count += 1;
    end
    always @(posedge cpu_clk, negedge rst) begin
        if (~rst) pc <= 0;
        else begin
            pc <= halted ? pc : 
                (beq_taken ? imm_extended + pc + 1 : 
                (jtype ? jimm_extended : pc + 1));
            if (is_sw)
            case(alu_out)
                `SCL_ADDR: begin
                    scl_r <= rd_val[0];
                end
                `SDA_ADDR: sda_r <= rd_val[0];
                `SDA_CLEAR_ADDR: sda_r <= 'bz;
                default: mem[alu_out] <= rd_val;
                // if (alu_out == `SCL_ADDR) scl_r <= rd_val[0];
                // else if (alu_out == `SDA_ADDR) sda_r <= rd_val[0];
                // else if (alu_out == `SDA_CLEAR_ADDR) sda_r <= 'bz;
                // else mem[alu_out] <= rd_val;
            endcase
        end
    end

    // always @(GSENSOR_SCLK) begin
    //     $display("scl val changed to %b", GSENSOR_SCLK);
    // end

    task load_instr(input [`MAX_PATH_LEN*8-1:0] instr_path, input integer num_instr);
        pc = 0;
        $readmemh("as/i2c.mem", mem, 0, 18);
        // $readmemh(instr_path, mem, 0, num_instr-1);
    endtask
endmodule

module segdisplay(
    input turn_off,
    input dp,
    input [3:0] num,
    output reg [7:0] segments
);
    always @*
        if (turn_off) segments <= 8'hff;
        else case (num)
            'h0: segments <= {~dp, 7'b1000000};
            'h1: segments <= {~dp, 7'b1111001};
            'h2: segments <= {~dp, 7'b0100100};
            'h3: segments <= {~dp, 7'b0110000};
            'h4: segments <= {~dp, 7'b0011001};
            'h5: segments <= {~dp, 7'b0010010};
            'h6: segments <= {~dp, 7'b0000010};
            'h7: segments <= {~dp, 7'b1111000};
            'h8: segments <= {~dp, 7'b0000000};
            'h9: segments <= {~dp, 7'b0011000};
            'ha: segments <= {~dp, 7'b0001000};
            'hb: segments <= {~dp, 7'b0000011};
            'hc: segments <= {~dp, 7'b1000110};
            'hd: segments <= {~dp, 7'b0100001};
            'he: segments <= {~dp, 7'b0000110};
            'hf: segments <= {~dp, 7'b0001110};
        endcase
endmodule
