
`timescale 1ns / 1ps

module i2c_tb();
    logic CLK = 0, RST = 0;

    cpu cpu_comp(.MAX10_CLK1_50(CLK), .KEY({1'b1, RST}));

    task step_cycles(integer num_cycles);
        repeat (num_cycles << 6) begin
            #10 CLK = 1;
            #10 CLK = 0;
        end
    endtask

    // initial begin
    //     RST = 1; #10;
    //     RST = 0; #10;
    //     RST = 1; #10;
    //     cpu_comp.load_instr("as/i2c.mem", 12); #10;
    //     step_cycles(100);
    // end
endmodule
