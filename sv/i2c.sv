
`timescale 1ns / 1ps

`define I2C_ADDR 7'h1D
`define STATE_LEN 3
`define COUNTER_LEN 32
`define STATE_BEGIN 0
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
	input GSENSOR_INT1,
	input GSENSOR_INT2,
	output GSENSOR_SCLK,
	output GSENSOR_CS_n,
	output GSENSOR_SDO,
	inout GSENSOR_SDA
	);

	reg [`COUNTER_LEN-1:0] count = 0;
	reg [`COUNTER_LEN-1:0] count_at_start;
	wire [`COUNTER_LEN-1:0] count_since_start;
	reg scl, sda, ack_complete, data_written, addr_written, read_en;
	reg [7:0] byte_sr;
	reg [8:0] byte_write;
	assign count_since_start = count - count_at_start;
	assign GSENSOR_SCLK = scl;
	assign GSENSOR_SDA = sda;
	assign addr_write_count = count - `BEGIN_ADDR_WRITE;

	// i2c mode
	assign GSENSOR_CS_n = 1;
	// primary address mode, 0x1D is the address
	assign GSENSOR_SDO = 1;

	reg [`STATE_LEN-1:0] state;
	reg [`STATE_LEN-1:0] next_state;

	always @*
	case (state)
		`STATE_BEGIN: begin
			count = 0;
			data_written = 0;
			addr_written = 0;
			read_en = 0;
			byte_sr = {`I2C_ADDR, read_en};
			byte_write = 1;
			count_at_start = count;
			next_state = `STATE_START_0;
		end
		`STATE_START_0: begin
			if (count_since_start > `BEGIN_START_COND) begin
				next_state = `STATE_START_1;
			end
		end
		`STATE_START_1: 
			if (count_since_start > `BEGIN_ADDR_WRITE)
				next_state = `STATE_ADDR_WRITE;
		`STATE_ADDR_WRITE:
			if (!byte_write) begin
				ack_complete = 0;
				addr_written = 1;
				next_state = `STATE_ACK_WAIT;
			end
			else next_state = state;
		`STATE_ACK_WAIT:
			if (ack_complete) begin
				if (addr_written) begin
					// writing reg 0
					byte_sr = 0;
					byte_write = 1;
					next_state = `STATE_DATA_WRITE;
				end
				else if (data_written) begin
					next_state = `STATE_RESTART_0;
				end
				else next_state = state;
			end
			else next_state = state;
		`STATE_DATA_WRITE:
			if (!byte_write) begin
				data_written = 1;
				ack_complete = 0;
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
			sda = 'bz;
			scl = 1;
		end
		`STATE_START_1: 
		begin
			sda = 0;
			scl = 1;
		end
		`STATE_ADDR_WRITE:
		begin
			// divide CLK by 128
			scl = count_since_start[6];
		end
		`STATE_ACK_WAIT:
		begin
			sda = 'bz;
			scl = count_since_start[6];
		end
		`STATE_DATA_WRITE:
		begin
			sda = 0;
			scl = count_since_start[6];
		end
	endcase

	always @(negedge scl)
	case (state)
		`STATE_ADDR_WRITE: begin
			sda = byte_sr[7];
			byte_sr = byte_sr << 1;
			byte_write = byte_write << 1;
		end
		`STATE_ACK_WAIT:
			if (!sda) ack_complete = 1;
		`STATE_DATA_WRITE: begin
			sda = byte_sr[7];
			byte_sr = byte_sr << 1;
			byte_write = byte_write << 1;
		end
	endcase

	always @(posedge clk) begin
		count = count + 1;
		if (!rst) begin
			state = `STATE_BEGIN;
		end 
		else 
			state = next_state;
	end
endmodule