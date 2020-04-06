
`include "defs.vh"

`timescale 1 ns / 1 ps
module lc_load_tb;
    reg clk = 0, rst = 1;
    // reg load_en = 1;
    // reg debug_mode = 1;
    wire rx, byte_ready;
    wire [7:0] data_received;
    wire nada = 'bz;

    wire [25:0] gpio_upper = {26{nada}};
    wire [8:0] gpio_lower = {9{nada}};
    
	wire		    [12:0]		addr;
	wire		     [1:0]		ba;
	wire		          		ras_n;
	wire		          		cas_n;
	wire		          		we_n;
	wire		          		dram_clk;
	wire 		    [15:0]		dq;

    localparam SYS_CYCLE = 20;
    localparam CPU_CYCLE = 64*SYS_CYCLE;
    localparam BAUD_CYCLE = SYS_CYCLE*325*16;

    uart_rx uart_rx_c(
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data(data_received),
        .data_ready(byte_ready)
    );
    
    sdram_sim sdram_c(
        .addr(addr),
        .ba(ba),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .clk(dram_clk),
        .dq(dq)
    );
    little_computer lc_c(
        .MAX10_CLK1_50(clk), 
        .KEY({1'b1, rst}), 
        .SW(10'b0),
        .GPIO({gpio_upper, rx, gpio_lower}),
        .DRAM_ADDR(addr),
        .DRAM_BA(ba),
        .DRAM_RAS_N(ras_n),
        .DRAM_CAS_N(cas_n),
        .DRAM_WE_N(we_n),
        .DRAM_CLK(dram_clk),
        .DRAM_DQ(dq)
    );

    task load_instr(string filename, integer length);
        $readmemh(filename, sdram_c.mem, 0, length - 1);
        rst = 0; #SYS_CYCLE;
        rst = 1; #(CPU_CYCLE*10);
        while (lc_c.state != lc_c.STATE_RUNNING) begin
            #SYS_CYCLE;
        end
    endtask

    initial begin
        forever begin
            #10 clk = 1;
            #10 clk = 0;
        end
    end

    initial begin
    end


    initial begin

        // load_instr("as/hello.mem", 25);

        // while (lc_c.cpu_c.halted !== 1) begin
        //     #CPU_CYCLE;
        // end
        // `ASSERT_EQ(lc_c.uart_tx_c.data, 'h74);
        // while (lc_c.uart_tx_c.state === lc_c.uart_tx_c.STATE_IDLE) begin
        //     #CPU_CYCLE;
        //     // $display("pc: %x, instr: %x, r3: %x", lc_c.pc, lc_c.instr, lc_c.cpu_c.reg_file[3]);
        // end
        // while (lc_c.uart_tx_c.state !== lc_c.uart_tx_c.STATE_IDLE) begin
        //     #CPU_CYCLE;
        //     // $display("pc: %x, instr: %x, r3: %x", lc_c.pc, lc_c.instr, lc_c.cpu_c.reg_file[3]);
        // end
        // while (lc_c.uart_tx_c.state === lc_c.uart_tx_c.STATE_IDLE) begin
        //     #CPU_CYCLE;
        //     // $display("pc: %x, instr: %x, r3: %x", lc_c.pc, lc_c.instr, lc_c.cpu_c.reg_file[3]);
        // end
        // while (lc_c.uart_tx_c.state !== lc_c.uart_tx_c.STATE_IDLE) begin
        //     #CPU_CYCLE;
        //     // $display("pc: %x, instr: %x, r3: %x", lc_c.pc, lc_c.instr, lc_c.cpu_c.reg_file[3]);
        // end

        // `ASSERT_EQ(lc_c.uart_tx_c., 'h74);
        // `ASSERT_EQ(data_received, 'h74);
        // $display("%x", data_received);
        $finish;
    end
endmodule

