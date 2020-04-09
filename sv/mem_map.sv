`include "defs.vh"

module mem_map(
    input [`WORD_WIDTH-1:0] pc,
    input [`WORD_WIDTH-1:0] data_addr,
    input [`WORD_WIDTH-1:0] data_in,
    input [`WORD_WIDTH-1:0] dram_read_data,
    input [31:0][15:0] dram_burst_buf,
    input uart_tx_ready,
    input dram_data_ready,
    input cpu_ready,
    input write_en,
    input vga_en,
    input [4:0] vga_x_group,
    input [8:0] vga_y_val,
    input clk,
    input clk_800k,
    input rst,
    output dram_refresh_data,
    output [31:0][11:0] vga_bgr_buf,
    output reg [24:0] dram_addr,
    output reg dram_write_en,
    output reg dram_burst_en,
    output reg [15:0] dram_data_in,
    output reg [15:0] read_data,
    output reg [15:0] instr,
    output reg [9:0] led,
    output reg [7:0] uart_tx_byte,
    output reg uart_tx_start_n

);
    localparam DRAM_FIRST = 16'h0;
    localparam DRAM_LAST = 16'hF7FF;
    localparam LED_FIRST = 16'hF800;
    localparam LED_LAST = 16'hF809;
    localparam UART_TX_READY = 16'hF80A;
    localparam UART_TX_BYTE = 16'hF80B;
    localparam VGA_WRITE = 16'hF80C;

    // write 1: x
    // write 2: y
    // write 3: BGR
    localparam VGA_WRITE_STATE_X = 0;
    localparam VGA_WRITE_STATE_Y = 1;
    localparam VGA_WRITE_STATE_BGR = 2;

    localparam STATE_IDLE = 0;
    localparam STATE_FETCH_INSTR = 1;
    localparam STATE_WAIT = 2;
    localparam STATE_INSTR_OUT = 3;
    localparam STATE_RW_DATA = 4;
    localparam STATE_DATA_OUT = 5;
    localparam STATE_FETCH_VGA = 6;

    reg [2:0] state;
    reg [5:0] wait_count;
    reg got_instr, got_data;
    reg [1:0] uart_tx_ready_vals;
    reg [2:0] clk_800k_vals;
    reg [1:0] vga_write_state;
    reg [9:0] vga_x_in;
    reg [8:0] vga_y_in;

    genvar i;
    generate
        for (i=0; i < 32; i = i + 1) begin : for_buf
            assign vga_bgr_buf[i] = dram_burst_buf[i][11:0];
        end
    endgenerate

    assign dram_refresh_data = state == STATE_FETCH_INSTR || state == STATE_RW_DATA || state == STATE_FETCH_VGA;

    function [2:0] next_state_func;
        input [2:0] state;
        case(state)
            STATE_IDLE:
                // need to change state the tick after pc is updated
                if (cpu_ready && clk_800k_vals == 3'b011) next_state_func = STATE_FETCH_INSTR;
                else next_state_func = state;
            STATE_FETCH_INSTR:
                next_state_func = STATE_WAIT;
            STATE_WAIT:
                if (dram_data_ready && !got_instr) next_state_func = STATE_INSTR_OUT;
                else if (dram_data_ready && !got_data) next_state_func = STATE_DATA_OUT;
                else if (dram_data_ready && got_instr && got_data) next_state_func = STATE_IDLE;
                else next_state_func = state;
            STATE_INSTR_OUT:
                next_state_func = STATE_RW_DATA;
            STATE_RW_DATA:
                next_state_func = STATE_WAIT;
            STATE_DATA_OUT:
                if (vga_en) next_state_func = STATE_FETCH_VGA;
                else next_state_func = STATE_IDLE;
            STATE_FETCH_VGA:
                next_state_func = STATE_WAIT;

            default: next_state_func = STATE_IDLE;
        endcase
    endfunction


    always @(posedge clk) begin
        // reset start_n as on posedge of uart_tx_ready
        uart_tx_ready_vals = {uart_tx_ready_vals[0], uart_tx_ready};
        if (cpu_ready) clk_800k_vals = {clk_800k_vals[1:0], clk_800k};
        if (uart_tx_ready_vals == 2'b01) begin
            // $display("resetting start_n");
            uart_tx_start_n = 1;
        end

        if (~rst) begin
            state = STATE_IDLE;
            clk_800k_vals = 3'b00;
            wait_count = 0;
            got_instr = 0;
            got_data = 0;
            uart_tx_start_n = 1;
            uart_tx_ready_vals = 2'b11;
            vga_write_state = VGA_WRITE_STATE_X;
            dram_burst_en = 1'b0;
            led = 10'b0;
            instr = 'hFFFF;
        end

        else state = next_state_func(state);

        case(state)
            STATE_IDLE: begin
            end 
            STATE_FETCH_INSTR: begin
                dram_burst_en = 0;
                dram_write_en = 1'b0;
                if (pc >= DRAM_FIRST && pc <= DRAM_LAST) begin
                    dram_addr = {9'b0, pc}; 
                end else begin
                    dram_addr = 25'b0; 
                end
                wait_count = 0;
                got_instr = 0;
                got_data = 0;
            end
            STATE_WAIT: begin
                wait_count += 1;
            end
            STATE_INSTR_OUT: begin
                instr = dram_read_data;
                got_instr = 1;
            end
            STATE_RW_DATA: begin
                if (data_addr >= DRAM_FIRST && data_addr <= DRAM_LAST) begin
                    dram_data_in = data_in;
                    dram_addr = {9'b0, data_addr}; 
                    dram_write_en = write_en;
                end else begin
                    dram_addr = 25'b0; 
                    dram_write_en = 1'b0;
                end

                if (write_en && data_addr >= LED_FIRST && data_addr <= LED_LAST) begin
                    led[data_addr - LED_FIRST] = data_in[0];
                end

                if (write_en && data_addr == UART_TX_BYTE) begin
                    
                    // $display("writing tx byte %x", data_in[7:0]);
                    uart_tx_byte = data_in[7:0];
                    uart_tx_start_n = 0;
                end

                if (write_en && data_addr == VGA_WRITE) begin
                    case(vga_write_state)
                        VGA_WRITE_STATE_X: begin
                            vga_x_in = data_in[9:0];
                            vga_write_state = VGA_WRITE_STATE_Y;
                        end
                        VGA_WRITE_STATE_Y: begin
                            vga_y_in = data_in[8:0];
                            vga_write_state = VGA_WRITE_STATE_BGR;
                        end
                        VGA_WRITE_STATE_BGR: begin
                            // pixels start at address 'h80000
                            dram_addr = {6'b1, vga_y_in, vga_x_in};
                            dram_write_en = 1'b1;
                            dram_data_in = data_in;
                            vga_write_state = VGA_WRITE_STATE_X;
                        end
                        default: vga_write_state = VGA_WRITE_STATE_X;
                    endcase
                end

                wait_count = 0;
            end
            STATE_DATA_OUT: begin
                got_data = 1;
                if (data_addr == UART_TX_READY) begin   
                    read_data = uart_tx_ready ? 16'b1 : 16'b0;
                end
                else begin
                    read_data = dram_read_data;
                end

            end
            STATE_FETCH_VGA: begin
                dram_burst_en = 1;
                dram_write_en = 0;
                dram_addr = {6'b1, vga_y_val, vga_x_group, 5'b0};
                // dram_addr = {6'b0, 9'b0, 5'h0, 5'h1F};
                dram_addr = 0;
                wait_count = 0;
            end
        endcase
    end
endmodule