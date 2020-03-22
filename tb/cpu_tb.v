
`timescale 1 ns / 1 ps
module cpu_tb;
    reg CLK = 0;
    integer i;
    cpu cpu_comp(.CLK(CLK));

    initial begin
        for (i=0; i<256; ++i) begin
            CLK = ~CLK; #20;
        end
    end
endmodule
