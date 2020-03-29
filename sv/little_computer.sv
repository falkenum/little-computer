
module little_computer(
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

    assign GPIO[7:0] = {8'b0};

    reg [`CPU_CLK_DIV_WIDTH-1:0] clk_800k_count = 0;
    // reg [1:0] uart_sr_rst_inv = 0;

    wire sysclk = MAX10_CLK1_50;
    wire uart_rx = GPIO[8];
    wire sysrst = KEY[0];
    wire debug_mode = SW[0];
    wire load_en = SW[1];
    wire clk_800k = clk_800k_count[5];
    wire cpu_clk = debug_mode ? ~KEY[1] : clk_800k;
    wire cpu_rst = sysrst & ~load_en;

    wire uart_byte_ready, uart_word_ready, cpu_mem_write_en;
    wire [`WORD_WIDTH-1:0] uart_word_count, uart_word, 
        memory_data_out, instr, pc, cpu_data_out, cpu_data_addr;
    wire [7:0] uart_byte;

    uart_sr uart_sr_c(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_byte),
        .rst(sysrst),
        .clk(sysclk),
        .uart_word_ready(uart_word_ready),
        .uart_word_count(uart_word_count),
        .uart_word(uart_word)
    );

    uart_rx uart_rx_c(
        // green wire
        .rx(uart_rx),
        .clk_50M(MAX10_CLK1_50),
        .data(uart_byte),
        .data_ready(uart_byte_ready)
    );

    display display_c(
        .debug_en(debug_mode), 
        .value({instr, pc[7:0]}),
        .hex({HEX5, HEX4, HEX3, HEX2, HEX1, HEX0})
    );

    memory memory_c(
        .data_addr(load_en ? uart_word_count : cpu_data_addr),
        .pc(pc),
        .data_in(load_en ? uart_word : cpu_data_out),
        .clk(load_en ? uart_word_ready : cpu_clk),
        .write_en(load_en | cpu_mem_write_en),
        .instr(instr),
        .data_out(memory_data_out)
    );

    cpu cpu_c(
        .clk(cpu_clk),
        .rst(cpu_rst),
        .instr(instr),
        .data_in(memory_data_out),
        .pc(pc),
        .data_addr(cpu_data_addr),
        .data_out(cpu_data_out),
        .mem_write_en(cpu_mem_write_en)
    );


    always @(posedge sysclk, negedge sysrst) begin
        if (~sysrst) begin
            clk_800k_count = 0;
        end
        else begin
            clk_800k_count += 1;
        end
    end

endmodule