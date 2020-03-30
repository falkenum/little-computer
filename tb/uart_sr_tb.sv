`include "defs.vh"

`timescale 1 ns / 1 ps

module uart_sr_tb();
    reg uart_byte_ready = 0, rst = 1, clk = 0;
    reg [7:0] uart_byte = 0;
    wire uart_word_ready;
    wire [`WORD_WIDTH-1:0] uart_word;

    uart_sr uart_sr_c(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_byte),
        .rst(rst),
        .clk(clk),
        .uart_word_ready(uart_word_ready),
        .uart_word(uart_word)
    );

    initial begin
        repeat(1000) begin
            clk = 1; #20;
            clk = 0; #20;
        end
    end

    initial begin
        // #10;
        // rst = 0; #20;
        // rst = 1; #20;

        // `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        // `ASSERT_EQ(uart_sr_c.uart_word_ready, 0);
        // `ASSERT_EQ(uart_sr_c.clocked_first_byte, 0);
        // `ASSERT_EQ(uart_sr_c.clocked_second_byte, 0);
        // `ASSERT_EQ(uart_sr_c.state, 0);

        // #10000;
        // `ASSERT_EQ(uart_sr_c.state, 1);
        // `ASSERT_EQ(uart_sr_c.byte_ready_vals, 4'b0);

        // uart_byte_ready = 1; #3000;

        // `ASSERT_EQ(uart_sr_c.clocked_first_byte, 1);
        // `ASSERT_EQ(uart_sr_c.state, 2);
        // uart_byte_ready = 0; #2000;

        // uart_byte_ready = 1; #4000;
        // `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        // `ASSERT_EQ(uart_sr_c.uart_word_ready, 0);
        // `ASSERT_EQ(uart_sr_c.clocked_second_byte, 1);
        // `ASSERT_EQ(uart_sr_c.state, 3);
        // uart_byte_ready = 0; #2000;

        // `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        // `ASSERT_EQ(uart_sr_c.uart_word_ready, 1);
        // `ASSERT_EQ(uart_sr_c.state, 3);

        // `ASSERT_EQ(uart_sr_c.uart_word_count, 1);
        // `ASSERT_EQ(uart_sr_c.state, 4);

        // `ASSERT_EQ(uart_sr_c.state, 0);

        // `ASSERT_EQ(uart_sr_c.state, 0);

        // $display("uart_sr state: ", uart_sr_c.state);
    end
endmodule