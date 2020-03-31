`include "defs.vh"

`timescale 1 ns / 1 ps 

module mem_ctl_tb;
    reg clk = 0;
    reg rst = 1;

    mem_ctl mem_ctl_c(.clk(clk), .rst(rst), .write_en(1'b1));

    initial begin
        repeat(200000) begin
            clk = 1; #10;
            clk = 0; #10;
        end
    end
    initial begin
        rst = 0; #10;
        rst = 1; #10;

        `ASSERT_EQ(mem_ctl_c.state, mem_ctl_c.STATE_RST_NOP);
        `ASSERT_EQ(mem_ctl_c.wait_count, 1);
        // `ASSERT_EQ(mem_ctl_c.wait_count, 4999);
        #99980;
        `ASSERT_EQ(mem_ctl_c.state, mem_ctl_c.STATE_RST_PRECHARGE);
        // $display(mem_ctl_c.state);
        #20;
        `ASSERT_EQ(mem_ctl_c.state, 2);
    end
endmodule