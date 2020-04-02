
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

    assign GPIO[7:0] = {instr[15:12], uart_byte_ready, uart_word_count[0], uart_word_ready, uart_rx};

    reg [`CPU_CLK_DIV_WIDTH-1:0] clk_800k_count = 0;
    reg [`WORD_WIDTH-1:0] uart_word_count = 0;
    reg [1:0] uart_word_ready_vals = 2'b00;
    reg [1:0] load_en_vals = 2'b11;
    reg [1:0] key1_vals = 2'b11;
    reg debug_clk = 0;

    wire sysclk = MAX10_CLK1_50;
    wire uart_rx = GPIO[8];
    wire sysrst = KEY[0];
    wire debug_mode = SW[0];
    wire load_en = SW[1];
    wire clk_800k = clk_800k_count[5];
    wire cpu_clk = debug_mode ? debug_clk : clk_800k;
    wire cpu_rst = sysrst & ~load_en;

    wire uart_byte_ready, uart_word_ready, cpu_mem_write_en, mem_map_dram_write_en;
    wire [`WORD_WIDTH-1:0] uart_word, dram_data,
        mem_map_lw_data, instr, pc, cpu_data, cpu_data_addr;
    wire [7:0] uart_byte;
    wire [24:0] mem_map_dram_addr;

    wire [24:0] dram_read_addr = load_en ? {9'b0, uart_word_count} : pc; 

    sdram_ctl sdram_ctl_c(
        .dram_clk(DRAM_CLK),
        .dram_cs_n(DRAM_CS_N),
        .dram_ldqm(DRAM_LDQM),
        .dram_udqm(DRAM_UDQM),
        .dram_addr(DRAM_ADDR),
        .dram_ba(DRAM_BA),
        .dram_cke(DRAM_CKE),
        .dram_cas_n(DRAM_CAS_N),
        .dram_ras_n(DRAM_RAS_N),
        .dram_we_n(DRAM_WE_N),
        .dram_dq(DRAM_DQ),

        .rst(sysrst),
        .clk(sysclk),
        .write_en(load_en ? 1'b1 : mem_map_dram_write_en),
        .addr(dram_read_addr),
        .data_in(load_en ? uart_word : cpu_data),
        .data_out(dram_data)
    );

    uart_sr uart_sr_c(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_byte),
        .rst(sysrst),
        .clk(sysclk),
        .uart_word_ready(uart_word_ready),
        .uart_word(uart_word)
    );

    uart_rx uart_rx_c(
        // green wire
        .rx(uart_rx),
        .clk(sysclk),
        .rst(sysrst),
        .data(uart_byte),
        .data_ready(uart_byte_ready)
    );

    display display_c(
        .debug_en(debug_mode), 
        .value({instr, dram_read_addr[7:0]}),
        // .value({dram_data_out, pc[7:0]}),
        .hex({HEX5, HEX4, HEX3, HEX2, HEX1, HEX0})
    );

    mem_map mem_map_c(
        .dram_read_data(dram_data),
        .pc(pc),
        .data_addr(cpu_data_addr),
        .write_en(cpu_mem_write_en),
        .clk(sysclk),
        .rst(sysrst),

        .dram_addr(mem_map_dram_addr),
        .dram_write_en(mem_map_dram_write_en),
        .read_data(mem_map_lw_data),
        .instr(instr)
    );

    cpu cpu_c(
        .clk(cpu_clk),
        .rst(cpu_rst),
        .instr(instr),
        .data_in(mem_map_lw_data),

        .pc(pc),
        .data_addr(cpu_data_addr),
        .data_out(cpu_data),
        .mem_write_en(cpu_mem_write_en)
    );

    always @(posedge sysclk) begin
        if (~sysrst) begin
            uart_word_count = 0;
            uart_word_ready_vals = 2'b00;
        end
        clk_800k_count += 6'b1;

        // inc counter on negedge of uart_word_ready
        if (uart_word_ready_vals[1] == 1 && uart_word_ready_vals[0] == 0) begin
            uart_word_count += 16'b1;
        end
        uart_word_ready_vals = {uart_word_ready_vals[0], uart_word_ready};

        // reset word count on positive edge of load en
        if (load_en_vals[1] == 0 && load_en_vals[0] == 1) begin
            uart_word_count = 0;
        end

        load_en_vals = {load_en_vals[0], load_en};

        if (key1_vals[1] == 1 && key1_vals[0] == 0) begin
            debug_clk = 1;
        end else if(key1_vals[1] == 0 && key1_vals[0] == 1) begin
            debug_clk = 0;
        end
        key1_vals = {key1_vals[0], KEY[1]};
    end

endmodule
