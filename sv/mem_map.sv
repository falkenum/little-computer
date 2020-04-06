`include "defs.vh"

module mem_map(
    input [`WORD_WIDTH-1:0] pc,
    input [`WORD_WIDTH-1:0] data_addr,
    input [`WORD_WIDTH-1:0] data_in,
    input [`WORD_WIDTH-1:0] dram_read_data,
    input uart_tx_ready,
    input dram_data_ready,
    input cpu_ready,
    input write_en,
    input clk,
    input rst,
    output dram_refresh_data,
    output reg [24:0] dram_addr,
    output reg dram_write_en,
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
    localparam STATE_IDLE = 0;
    localparam STATE_FETCH_INSTR = 1;
    localparam STATE_WAIT = 2;
    localparam STATE_INSTR_OUT = 3;
    localparam STATE_RW_DATA = 4;
    localparam STATE_DATA_OUT = 5;

    reg [2:0] state;
    reg [3:0] wait_count;
    reg [`WORD_WIDTH-1:0] last_pc;
    reg got_instr;
    reg [1:0] uart_tx_ready_vals;

    assign dram_refresh_data = state == STATE_FETCH_INSTR || state == STATE_RW_DATA;

    function [2:0] next_state_func;
        input [2:0] state;
        case(state)
            STATE_IDLE:
                if (cpu_ready && pc != last_pc) next_state_func = STATE_FETCH_INSTR;
                else next_state_func = state;
            STATE_FETCH_INSTR:
                next_state_func = STATE_WAIT;
            STATE_WAIT:
                if (dram_data_ready && !got_instr) next_state_func = STATE_INSTR_OUT;
                else if (dram_data_ready && got_instr) next_state_func = STATE_DATA_OUT;
                else next_state_func = state;
            STATE_INSTR_OUT:
                next_state_func = STATE_RW_DATA;
            STATE_RW_DATA:
                next_state_func = STATE_WAIT;
            STATE_DATA_OUT:
                next_state_func = STATE_IDLE;
            default: next_state_func = STATE_IDLE;
        endcase
    endfunction


    always @(posedge clk) begin
        // reset start_n as on posedge of uart_tx_ready
        uart_tx_ready_vals = {uart_tx_ready_vals[0], uart_tx_ready};
        if (uart_tx_ready_vals == 2'b01) begin
            // $display("resetting start_n");
            uart_tx_start_n = 1;
        end

        if (~rst) begin
            state = STATE_IDLE;
            last_pc = 0;
            wait_count = 0;
            got_instr = 0;
            uart_tx_start_n = 1;
            uart_tx_ready_vals = 2'b11;
            // nop
            instr = 'hF000;
        end

        else state = next_state_func(state);

        case(state)
            STATE_IDLE: begin
                last_pc = ~cpu_ready ? 'hffff : pc;
            end 
            STATE_FETCH_INSTR: begin
                dram_write_en = 1'b0;
                if (pc >= DRAM_FIRST && pc <= DRAM_LAST) begin
                    dram_addr = {9'b0, pc}; 
                end else begin
                    dram_addr = 25'b0; 
                end
                wait_count = 0;
                got_instr = 0;
            end
            STATE_WAIT: begin
                wait_count += 1;
            end
            STATE_INSTR_OUT: begin
                instr = dram_read_data;
                got_instr = 1;
            end
            STATE_RW_DATA: begin
                dram_data_in = data_in;
                if (data_addr >= DRAM_FIRST && data_addr <= DRAM_LAST) begin
                    dram_addr = {9'b0, data_addr}; 
                    dram_write_en = write_en;
                end else begin
                    dram_addr = 25'b0; 
                    dram_write_en = 1'b0;
                end

                // $display("fetching/writing to addr %x", data_addr);
                if (write_en && data_addr >= LED_FIRST && data_addr <= LED_LAST) begin
                    led[data_addr - LED_FIRST] = data_in[0];
                end

                if (write_en && data_addr == UART_TX_BYTE) begin
                    
                    // $display("writing tx byte %x", data_in[7:0]);
                    uart_tx_byte = data_in[7:0];
                    uart_tx_start_n = 0;
                end

                wait_count = 0;
            end
            STATE_DATA_OUT: begin
                if (data_addr == UART_TX_READY) begin   
                    read_data = uart_tx_ready ? 16'b1 : 16'b0;
                end
                else begin
                    read_data = dram_read_data;
                end

            end
        endcase

    end
endmodule