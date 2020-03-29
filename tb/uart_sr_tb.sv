`include "defs.vh"

`timescale 1 us / 1 ps

module uart_sr_tb();
    reg uart_byte_ready = 0, rst = 1, clk = 0;
    reg [7:0] uart_byte;
    wire uart_word_ready;
    wire [`WORD_WIDTH-1:0] uart_word, uart_word_count;

    uart_sr uart_sr_c(
        .uart_byte_ready(uart_byte_ready),
        .uart_byte(uart_byte),
        .rst(rst),
        .clk(clk),
        .uart_word_ready(uart_word_ready),
        .uart_word_count(uart_word_count),
        .uart_word(uart_word)
    );
    initial begin
        rst = 0; #10;
        rst = 1; #10;
        clk = 1; #10;
        clk = 0; #10;

        `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        `ASSERT_EQ(uart_sr_c.uart_word_ready, 0);
        `ASSERT_EQ(uart_sr_c.clocked_first_byte, 0);
        `ASSERT_EQ(uart_sr_c.clocked_second_byte, 0);
        `ASSERT_EQ(uart_sr_c.state, 0);

        clk = 1; #10;
        clk = 0; #10;
        `ASSERT_EQ(uart_sr_c.state, 0);
        uart_byte_ready = 1; #10;
        clk = 1; #10;
        clk = 0; #10;
        uart_byte_ready = 0; #10;
        `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        `ASSERT_EQ(uart_sr_c.uart_word_ready, 0);
        `ASSERT_EQ(uart_sr_c.clocked_second_byte, 0);
        `ASSERT_EQ(uart_sr_c.clocked_first_byte, 1);
        `ASSERT_EQ(uart_sr_c.state, 0);

        clk = 1; #10;
        clk = 0; #10;
        `ASSERT_EQ(uart_sr_c.state, 1);

        repeat (1 << 23) begin
            clk = 1; #10;
            clk = 0; #10;
        end

        uart_byte_ready = 1; #10;
        clk = 1; #10;
        clk = 0; #10;
        uart_byte_ready = 0; #10;
        `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        `ASSERT_EQ(uart_sr_c.uart_word_ready, 0);
        `ASSERT_EQ(uart_sr_c.clocked_second_byte, 1);
        `ASSERT_EQ(uart_sr_c.state, 2);

        clk = 1; #10;
        clk = 0; #10;
        `ASSERT_EQ(uart_sr_c.uart_word_count, 0);
        `ASSERT_EQ(uart_sr_c.uart_word_ready, 1);
        `ASSERT_EQ(uart_sr_c.state, 3);

        clk = 1; #10;
        clk = 0; #10;
        `ASSERT_EQ(uart_sr_c.uart_word_count, 1);
        `ASSERT_EQ(uart_sr_c.state, 4);

        clk = 1; #10;
        clk = 0; #10;
        `ASSERT_EQ(uart_sr_c.state, 0);

        clk = 1; #10;
        clk = 0; #10;
        `ASSERT_EQ(uart_sr_c.state, 0);

        // $display("uart_sr state: ", uart_sr_c.state);
    end
endmodule