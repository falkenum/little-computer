// Copyright (C) 2019  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.

// *****************************************************************************
// This file contains a Verilog test bench template that is freely editable to  
// suit user's needs .Comments are provided in each section to help the user    
// fill out necessary details.                                                  
// *****************************************************************************
// Generated on "03/15/2020 16:30:00"
                                                                                
// Verilog Test Bench template for design : fpgatest
// 
// Simulation tool : ModelSim-Altera (Verilog)
// 

`timescale 1 ns/ 1 ns
module i2c_tb();
// constants                                           
// general purpose registers
reg eachvec;
// test vector input registers
reg CLK = 0;
reg RST = 0;
reg GSENSOR_INT1;
reg GSENSOR_INT2;
// wires                                               
wire GSENSOR_CS_n;
wire GSENSOR_SCLK;
wire GSENSOR_SDA;
wire GSENSOR_SDO;

// assign statements (if any)                          
cpu cpu_comp (
// port map - connection between master ports and signals/registers   
	.CLK_50(CLK),
	.KEY0(RST),
	.GSENSOR_CS_n(GSENSOR_CS_n),
	.GSENSOR_INT1(GSENSOR_INT1),
	.GSENSOR_INT2(GSENSOR_INT2),
	.GSENSOR_SCLK(GSENSOR_SCLK),
	.GSENSOR_SDA(GSENSOR_SDA),
	.GSENSOR_SDO(GSENSOR_SDO)
);
initial                                                
begin                                                  
// code that executes only once                        
// insert code here --> begin                          
	repeat(1000 << 6)
		CLK <= ~CLK; #20;
                                                       
// --> end                                             
end                                                    

// reg [7:0] ack_sr = 1;
// reg is_ack = 0;
// assign GSENSOR_SDA = is_ack ? 0 : 'bz;
// always @(posedge GSENSOR_SCLK) begin
// 	if (ack_sr)
// 		ack_sr = ack_sr << 1;
// 	else if (!is_ack)
// 		is_ack = 1;
// 	else begin
// 		is_ack = 0;
// 		ack_sr = 1;
// 	end
// end

endmodule

