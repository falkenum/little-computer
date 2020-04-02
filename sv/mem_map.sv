`include "defs.vh"

module mem_map(
    input [`WORD_WIDTH-1:0] pc,
    input [`WORD_WIDTH-1:0] data_addr,
    input [`WORD_WIDTH-1:0] data_in,
    input [`WORD_WIDTH-1:0] dram_read_data,
    input dram_data_ready,
    input write_en,
    input clk,
    input rst,
    output reg [24:0] dram_addr,
    output reg dram_write_en,
    output reg [15:0] dram_data_in,
    output reg dram_refresh_data,
    output reg [15:0] read_data,
    output reg [15:0] instr
);
    localparam DRAM_FIRST = 16'h0;
    localparam DRAM_LAST = 16'hF7FF;
    localparam STATE_IDLE = 0;
    localparam STATE_FETCH_INSTR = 1;
    localparam STATE_WAIT = 2;
    localparam STATE_INSTR_OUT_FETCH_DATA = 3;
    localparam STATE_DATA_OUT = 4;

    reg [2:0] state;
    reg [3:0] wait_count;
    reg [`WORD_WIDTH-1:0] last_pc;
    reg got_instr;

    // wire pc_changed = pc_vals[1] == pc_vals[0] && pc_vals[2] != pc_vals[1];

    function [2:0] next_state_func;
        input [2:0] state;
        case(state)
            STATE_IDLE:
                if (pc != last_pc) next_state_func = STATE_FETCH_INSTR;
                else next_state_func = state;
            STATE_FETCH_INSTR:
                next_state_func = STATE_WAIT;
            STATE_WAIT:
                if (dram_data_ready && !got_instr) next_state_func = STATE_INSTR_OUT_FETCH_DATA;
                else if (dram_data_ready && got_instr) next_state_func = STATE_DATA_OUT;
                else next_state_func = state;
            STATE_INSTR_OUT_FETCH_DATA:
                next_state_func = STATE_WAIT;
            STATE_DATA_OUT:
                next_state_func = STATE_IDLE;
            default: next_state_func = STATE_IDLE;
        endcase
    endfunction

    always @(posedge clk) begin
        if (~rst) begin
            state = STATE_IDLE;
            last_pc = 16'hffff;
            wait_count = 0;
            got_instr = 0;
            dram_refresh_data = 0;
        end

        else state = next_state_func(state);

        case(state)
            STATE_IDLE: begin
                last_pc = pc;
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
                dram_refresh_data = 1;
            end
            STATE_WAIT: begin
                // reset the flag after the first wait cycle
                // to give sdram_ctl a chance to read it
                if(wait_count == 1) dram_refresh_data = 0;
                wait_count += 1;
            end
            STATE_INSTR_OUT_FETCH_DATA: begin
                instr = dram_read_data;
                got_instr = 1;
                dram_data_in = data_in;
                if (data_addr >= DRAM_FIRST && data_addr <= DRAM_LAST) begin
                    dram_addr = {9'b0, data_addr}; 
                    dram_write_en = write_en;
                end else begin
                    dram_addr = 25'b0; 
                    dram_write_en = 1'b0;
                end
                wait_count = 0;
                dram_refresh_data = 1;
            end
            STATE_DATA_OUT: begin
                read_data = dram_read_data;
            end
        endcase

    end
endmodule