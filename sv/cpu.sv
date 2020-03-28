`include "defs.vh"

`define SEG_DISPLAY_OFF 8'hFF

module cpu(
//////////// clock //////////
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
	inout 		    [35:0]		GPIO
);

    reg [`REG_WIDTH-1:0] pc;
    reg [`CPU_CLK_DIV_WIDTH-1:0] clk_divided_count = 0;
    reg mem_write_en = 0;
    reg uart_sr_rst = 1;

    wire [`REG_WIDTH-1:0] uart_word_count;
    wire uart_word_ready;
    wire [`WORD_WIDTH-1:0] uart_word;
    wire uart_rx, uart_byte_ready;
    wire [7:0] uart_byte;
    wire jtype, halted, reg_write_en, alu_use_imm, is_beq, regs_equal, beq_taken;
    wire is_lw, is_sw, clk_800k, cpu_clk, rst;
    wire [`INSTR_WIDTH-1:0] instr;
    wire [`ALU_OP_WIDTH-1:0] alu_op;
    wire [`NUM_REGS_WIDTH-1:0] rs, rt, rd; 
    wire [`REG_WIDTH-1:0] rs_val, rt_val, rd_val, reg_in, alu_out, imm_extended, jimm_extended;
    wire [`IMM_WIDTH-1:0] imm;
    wire [`JIMM_WIDTH-1:0] jimm;
    wire debug_mode = SW[0];
    wire [`WORD_WIDTH-1:0] memory_data_out;
    wire load_en = SW[1];

    wire [`OP_WIDTH-1:0] op;
    wire itype;
    assign op = instr[`INSTR_WIDTH-1:`INSTR_WIDTH-`OP_WIDTH];
    
    assign is_beq = op == `OP_BEQ;
    assign halted = op == `OP_HALT;
    assign jtype = op == `OP_J;
    assign is_lw = op == `OP_LW;
    assign is_sw = op == `OP_SW;
    assign itype = op[`OP_WIDTH-1:`OP_WIDTH-2] == 'b01;
    assign alu_use_imm = itype & op != `OP_BEQ;
    assign reg_write_en = op[`OP_WIDTH-1:`OP_WIDTH-2] == 'b00 | op == `OP_ADDI | op == `OP_LW;
    assign alu_op = (is_lw | is_sw) ? `ALU_OP_ADD : op[`OP_WIDTH-3:`OP_WIDTH-4];

    assign GPIO[7:0] = {8'b0};
    assign clk_800k = clk_divided_count[5];
    assign cpu_clk = debug_mode ? ~KEY[1] : clk_800k;
    assign rst = ~load_en & KEY[0];
    assign rs = instr[3*`NUM_REGS_WIDTH-1:2*`NUM_REGS_WIDTH];
    assign rt = instr[2*`NUM_REGS_WIDTH-1:`NUM_REGS_WIDTH];
    assign rd = instr[`NUM_REGS_WIDTH-1:0];
    assign beq_taken = is_beq & (rt_val == rd_val);
    assign imm = instr[(`INSTR_WIDTH-`OP_WIDTH-1):2*`NUM_REGS_WIDTH];
    assign imm_extended = {imm[`IMM_WIDTH-1] ? ~10'b0 : 10'b0, imm};
    assign jimm = instr[`JIMM_WIDTH-1:0];
    assign jimm_extended = {jimm[`JIMM_WIDTH-1] ? ~4'b0 : 4'b0, jimm};
    assign reg_in = is_lw ? memory_data_out : alu_out;

    assign uart_rx = GPIO[8];

    uart_sr uart_sr_comp(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_byte),
        .rst(uart_sr_rst),
        .uart_word_ready(uart_word_ready),
        .uart_word_count(uart_word_count),
        .uart_word(uart_word)
    );

    uart_rx uart_rx_comp(
        // green wire
        .rx(uart_rx),
        .clk_50M(MAX10_CLK1_50),
        .data(uart_byte),
        .data_ready(uart_byte_ready)
    );

    always @(load_en, alu_out) begin
        // $display("load_en: %b; alu_out: %x", load_en, alu_out);
    end

    memory memory_comp(
        .data_addr(load_en ? uart_word_count : alu_out),
        .pc(pc),
        .data_in(load_en ? uart_word : rd_val),
        .clk(load_en ? uart_word_ready : cpu_clk),
        .write_en(mem_write_en),
        .instr(instr),
        .data_out(memory_data_out)
    );

    // wire spi_sck, spi_miso, spi_mosi, spi_cs, spi_begin_transaction;
    // wire [1:0] spi_state;
    // reg [`REG_WIDTH-1:0] spi_transaction_length = 1 << 8;
    // assign spi_begin_transaction = ~KEY[1];
    // assign ARDUINO_IO[13] = spi_sck;
    // assign spi_miso = ARDUINO_IO[12];
    // assign ARDUINO_IO[10] = spi_cs;

    // spi spi_comp(
    //     .clk_800k(clk_800k),
    //     .sck(spi_sck),
    //     .miso(spi_miso),
    //     .rst(rst),
    //     // .mosi(ARDUINO_IO[11]),
    //     .cs(spi_cs),
    //     .begin_transaction(spi_begin_transaction),
    //     // .transaction_length(spi_transaction_length),
    //     .state_out(spi_state)
    // );
    display display_comp(
        .enable(debug_mode), 
        .instr(instr), 
        .pc(pc[7:0]), 
        // .pc(uart_data), 
        .hex({HEX5, HEX4, HEX3, HEX2, HEX1, HEX0})
    );
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
        .result(alu_out)
    );

    
    always @(posedge MAX10_CLK1_50, negedge rst) begin
        if ~(rst) begin
            clk_divided_count = 0;
            uart_sr_rst = 0;
        end
        else begin
            clk_divided_count += 1;
            uart_sr_rst = 1;
        end
    end

    always @(posedge cpu_clk, negedge rst) begin
        // $display("posedge clk");
        if (~rst) begin 
            pc = 0;
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


module uart_sr(
    input uart_byte_ready,
    input [7:0] uart_byte,
    input rst,
    output reg uart_word_ready,
    output reg [`WORD_WIDTH-1:0] uart_word,
    output reg [`WORD_WIDTH-1:0] uart_word_count
);
    reg clocked_first_byte = 0;

    always @(posedge uart_byte_ready, negedge rst) begin
        if (~rst) begin
            uart_word_count = 0;
            uart_word_ready = 0;
            clocked_first_byte = 0;
        end
        else begin
            if (clocked_first_byte) begin
                uart_word = {uart_byte, uart_word[7:0]};
                clocked_first_byte = 0;
                uart_word_ready = 1;
            end
            else begin
                uart_word = {8'b0, uart_byte};
                clocked_first_byte = 1;
                uart_word_ready = 0;
                uart_word_count += 1;
            end
        end
    end
endmodule