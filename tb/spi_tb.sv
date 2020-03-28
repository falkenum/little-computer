`include "../vh/defs.vh"

`timescale 1us / 1ps

module spi_tb();
    reg clk_800k = 0, spi_miso = 0, spi_begin_transaction = 0;
    wire spi_sck, spi_mosi, spi_cs;
    reg [7:0] data_out = 'h74;
    spi spi_comp(
        .clk_800k(clk_800k),
        .sck(spi_sck),
        .miso(spi_miso),
        // .mosi(spi_mosi),
        .cs(spi_cs),
        .begin_transaction(spi_begin_transaction)
    );

    // initial begin
    //     #100;
    //     spi_begin_transaction = 0; #10;
    //     `ASSERT_EQ (spi_cs, 1);
    //     spi_begin_transaction = 1; #100;
    //     `ASSERT_EQ (spi_comp.cs, 0);
    //     `ASSERT_EQ (spi_comp.state, 1);
    //     `ASSERT_EQ (spi_comp.delay_finished, 0);
    //     `ASSERT_EQ (spi_comp.delay_finished, 0);
    //     `ASSERT_EQ (spi_comp.delay_finished, 1);
    //     spi_begin_transaction = 0; #500;
    //     `ASSERT_EQ (spi_comp.state, 2);
    // end

    // always @(negedge spi_sck) begin
    // end
    // initial begin
    //     integer i;
    //     for (i = 0; i < 100000; i++) begin
    //         #1 clk_800k = ~clk_800k;
    //     end
    // end
endmodule