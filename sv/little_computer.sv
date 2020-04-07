`include "defs.vh"

module little_computer(
    //////////// clock //////////
	// input 		          		ADC_CLK_10,
	input 		          		MAX10_CLK1_50,
	// input 		          		MAX10_CLK2_50,

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
	// output		          		GSENSOR_CS_N,
	// input 		     [2:1]		GSENSOR_INT,
	// output		          		GSENSOR_SCLK,
	// inout 		          		GSENSOR_SDI,
	// output 		          		GSENSOR_SDO,

	//////////// Arduino //////////
	// inout 		    [15:0]		ARDUINO_IO,
	// inout 		          		ARDUINO_RESET_N,

	//////////// GPIO, GPIO connect to GPIO Default //////////
	inout 		    [35:0]		GPIO
);
    localparam STATE_RESET = 0;
    localparam STATE_RUNNING = 1;

    // assign GPIO[7:0] = {instr[15:12], uart_byte_ready, uart_word_count[0], uart_tx, uart_rx};
    assign GPIO[9] = uart_tx;

    reg [`WORD_WIDTH-1:0] uart_word_count;
    reg [1:0] uart_word_ready_vals;
    reg [1:0] load_en_vals;
    reg [1:0] key1_vals;
    reg [1:0] state;
    reg internal_cpu_rst;
    reg [5:0] clk_800k_count;

    wire clk_800k = ~clk_800k_count[5];
    wire sysclk = MAX10_CLK1_50;
    wire uart_rx = GPIO[8];
    wire sysrst = KEY[0];
    wire debug_mode = SW[0];
    wire debug_clk = ~KEY[1];
    wire load_en = SW[1];
    wire cpu_rst = sysrst & internal_cpu_rst;
    wire cpu_ready = state == STATE_RUNNING;

    wire uart_byte_ready, uart_word_ready, cpu_mem_write_en, mem_map_dram_write_en,
        mem_map_to_dram_refresh, dram_to_mem_map_data_ready, dram_ready, uart_tx_ready, uart_tx,
        uart_tx_start_n, mem_map_dram_burst_en;
    wire [`WORD_WIDTH-1:0] uart_word, dram_data, mem_map_to_dram_data,
        mem_map_lw_data, instr, pc, cpu_data, cpu_data_addr;
    wire [7:0] uart_rx_byte, uart_tx_byte;
    wire [24:0] mem_map_dram_addr;
    wire vga_mem_fetch_en;
    wire [4:0] vga_x_group;
    wire [8:0] vga_y_val;
    wire [31:0][11:0] vga_bgr_buf;
    wire [31:0][15:0] dram_ctl_burst_buf;

    vga vga_c(
        .clk(sysclk),           // base clock
        .rst(sysrst),           // reset: restarts frame
        .clk_800k(clk_800k),
        .hs(VGA_HS),           // horizontal sync
        .vs(VGA_VS),           // vertical sync
        .rval(VGA_R),
        .gval(VGA_G),
        .bval(VGA_B),
        // .vblank()     // high during blanking interval
        .mem_fetch_en(vga_mem_fetch_en),
        .mem_fetch_x_group(vga_x_group),
        .mem_fetch_y_val(vga_y_val),
        .mem_bgr_buf(vga_bgr_buf)
    );

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
        .addr(load_en ? uart_word_count : mem_map_dram_addr),
        .refresh_data(load_en ? uart_word_ready : mem_map_to_dram_refresh),
        .data_in(load_en ? uart_word : mem_map_to_dram_data),
        .burst_en(mem_map_dram_burst_en),

        .burst_buf(dram_ctl_burst_buf),
        .data_out(dram_data),
        .data_ready(dram_to_mem_map_data_ready),
        .mem_ready(dram_ready)
    );

    uart_sr uart_sr_c(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_rx_byte),
        .rst(sysrst),
        .clk(sysclk),
        .uart_word_ready(uart_word_ready),
        .uart_word(uart_word)
    );

    uart_tx uart_tx_c(
        // white wire
        .tx(uart_tx),
        .clk(sysclk),
        .rst(sysrst),
        .data(uart_tx_byte),
        .start_n(uart_tx_start_n),
        .ready_to_send(uart_tx_ready)
    );

    uart_rx uart_rx_c(
        // green wire
        .rx(uart_rx),
        .clk(sysclk),
        .rst(sysrst),
        .data(uart_rx_byte),
        .data_ready(uart_byte_ready)
    );

    hex_seg_display hex_c(
        .debug_en(debug_mode), 
        .value({instr, pc[7:0]}),
        // .value({dram_data_out, pc[7:0]}),
        .hex({HEX5, HEX4, HEX3, HEX2, HEX1, HEX0})
    );

    mem_map mem_map_c(
        .dram_read_data(dram_data),
        .pc(pc),
        .data_addr(cpu_data_addr),
        .write_en(cpu_mem_write_en),
        .data_in(cpu_data),
        .clk(sysclk),
        .rst(sysrst),
        .uart_tx_ready(uart_tx_ready),
        .vga_en(vga_mem_fetch_en),
        .vga_x_group(vga_x_group),
        .vga_y_val(vga_y_val),
        .vga_bgr_buf(vga_bgr_buf),
        .dram_burst_buf(dram_ctl_burst_buf),

        .dram_data_ready(dram_to_mem_map_data_ready),
        .cpu_ready(cpu_ready),
        .dram_refresh_data(mem_map_to_dram_refresh),
        .dram_addr(mem_map_dram_addr),
        .dram_write_en(mem_map_dram_write_en),
        .dram_data_in(mem_map_to_dram_data),
        .dram_burst_en(mem_map_dram_burst_en),
        .led(LEDR),
        .uart_tx_byte(uart_tx_byte),
        .uart_tx_start_n(uart_tx_start_n),
        .read_data(mem_map_lw_data),
        .instr(instr)
    );

    cpu cpu_c(
        .clk(sysclk),
        .clk_800k(clk_800k),
        .rst(cpu_rst),
        .instr(instr),
        .data_in(mem_map_lw_data),
        .debug_clk(debug_clk),
        .debug_mode(debug_mode),

        .pc(pc),
        .data_addr(cpu_data_addr),
        .data_out(cpu_data),
        .mem_write_en(cpu_mem_write_en)
    );

    function [1:0] next_state_func;
        input [1:0] state;
        case(state)
            STATE_RESET:
                if (dram_ready) next_state_func = STATE_RUNNING;
                else next_state_func = state;
            STATE_RUNNING:
                next_state_func = state;
            default: next_state_func = STATE_RESET;
        endcase
        
    endfunction

    always @(posedge sysclk) begin
        if (~sysrst) begin
            clk_800k_count = 0;
            uart_word_count = 0;
            uart_word_ready_vals = 2'b00;
            state = STATE_RESET;
            load_en_vals = 2'b11;
            key1_vals = 2'b11;
            internal_cpu_rst = 0;
        end
        else state = next_state_func(state);
        clk_800k_count += 1;

        case(state)
            STATE_RESET: begin
                internal_cpu_rst = 0;
            end
            STATE_RUNNING: begin
                internal_cpu_rst = 1;
            end
        endcase

        // inc counter on negedge of uart_word_ready, its value is used on the posedge by sdram
        if (uart_word_ready_vals[1] == 1 && uart_word_ready_vals[0] == 0) begin
            uart_word_count += 16'b1;
        end
        uart_word_ready_vals = {uart_word_ready_vals[0], uart_word_ready};

        // reset word count on positive edge of load en
        if (load_en_vals[1] == 0 && load_en_vals[0] == 1) begin
            uart_word_count = 0;
        end

        load_en_vals = {load_en_vals[0], load_en};

    end

endmodule
