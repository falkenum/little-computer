
`timescale 1us / 1ps

`define I2C_ADDR 7'h1D
`define STATE_LEN 3
`define COUNTER_LEN 64
`define STATE_TRANSACTION_BEGIN 0
`define STATE_START_0 1
`define STATE_START_1 2
`define STATE_ADDR_WRITE 3
`define STATE_ACK_WAIT 4
`define STATE_DATA_WRITE 5
`define BEGIN_ADDR_WRITE 100
`define BEGIN_START_COND 50

module i2c(
	input clk, 
	input rst,
	output scl,
	inout sda
	);

	logic [`COUNTER_LEN-1:0] count = 0, count_at_start = 0;
    logic read_en, ack_phase_complete, was_ack, addr_written, data_written, sclr, sdar;
	logic [7:0] byte_sr = 0;
    logic [8:0] byte_write = 0;

	logic [`STATE_LEN-1:0] state;
	logic [`STATE_LEN-1:0] next_state;

    wire [`COUNTER_LEN-1:0] count_since_start = 0;
    assign count_since_start = count - count_at_start;
    assign scl = sclr;
    assign sda = sdar;

	always @*
	case (state)
		`STATE_TRANSACTION_BEGIN: begin
            count_at_start = 0;
            data_written = 0;
            addr_written = 0;
			next_state = `STATE_START_0;
		end
		`STATE_START_0: begin
			if (count_since_start > `BEGIN_START_COND) begin
				next_state = `STATE_START_1;
			end
            else next_state = state;
		end
		`STATE_START_1: begin
			if (count_since_start > `BEGIN_ADDR_WRITE) begin
                byte_sr = {`I2C_ADDR, read_en};
                byte_write = 1;
				next_state = `STATE_ADDR_WRITE;
            end else next_state = state;
        end
		`STATE_ADDR_WRITE: begin
			if (!byte_write) begin
				addr_written = 1;
				next_state = `STATE_ACK_WAIT;
			end
			else next_state = state;
        end
		`STATE_ACK_WAIT:
			if (ack_phase_complete) begin
                // if it was a nack, then start over
                if (!was_ack) next_state = `STATE_TRANSACTION_BEGIN;
				else if (addr_written) begin
					// writing reg 0
					byte_sr = 0;
					byte_write = 1;
					next_state = `STATE_DATA_WRITE;
				end
				else if (data_written) begin
					// next_state = `STATE_RESTART_0;
				end
				else next_state = state;
			end
			else next_state = state;
		`STATE_DATA_WRITE:
			if (!byte_write) begin
				data_written = 1;
				next_state = `STATE_ACK_WAIT;
			end
			else next_state = state;
		default: 
			next_state = `STATE_START_0;
	endcase

	always @*
	case (state)
		`STATE_START_0: 
		begin
			sdar = 'bz;
			sclr = 1;
		end
		`STATE_START_1: 
		begin
			sdar = 0;
			sclr = 1;
		end
		`STATE_ADDR_WRITE:
		begin
			sdar = byte_sr[7];
			// divide CLK by 128
			sclr = count_since_start[6];
		end
		`STATE_ACK_WAIT:
		begin
			sdar = 'bz;
			sclr = count_since_start[6];
		end
		`STATE_DATA_WRITE:
		begin
			sdar = byte_sr[7];
			sclr = count_since_start[6];
		end
	endcase

	always @(negedge scl)
	case (state)
		`STATE_ADDR_WRITE: begin
			byte_sr = byte_sr << 1;
			byte_write = byte_write << 1;
		end
		`STATE_DATA_WRITE: begin
			byte_sr = byte_sr << 1;
			byte_write = byte_write << 1;
		end
	endcase
    always @(posedge scl)
    case (state)
		`STATE_ACK_WAIT: begin
            ack_phase_complete = 1;
			if (!sda) was_ack = 1;
            else was_ack = 0;
        end
		`STATE_ADDR_WRITE:
            ack_phase_complete = 0;
		`STATE_DATA_WRITE:
            ack_phase_complete = 0;
        
    endcase

	always @(posedge clk) begin
		count = count + 1;
		if (!rst) begin
			state = `STATE_TRANSACTION_BEGIN;
		end 
		else 
			state = next_state;
	end
endmodule