
`timescale 1us / 1ps

module i2c(
	input clk, 
    input [7:0] data_in,
    input rw,
	output reg scl,
	output [7:0] data_out,
	inout sda
);

reg sda_r;
assign sda = sda_r;

always begin
    scl = 1;
    sda_r = 1;
    #5 sda_r = 0;
    #5 scl = 0; #1000;
end

endmodule