`include "defs.vh"

module hex_seg_display(
    input debug_en,
    input [23:0] value,
    output [5:0][7:0] hex
);
    segdisplay seg0(debug_en, 1'b0, value[3:0], hex[0]);
    segdisplay seg1(debug_en, 1'b0, value[7:4], hex[1]);
    segdisplay seg2(debug_en, 1'b1, value[11:8], hex[2]);
    segdisplay seg3(debug_en, 1'b0, value[15:12], hex[3]);
    segdisplay seg4(debug_en, 1'b0, value[19:16], hex[4]);
    segdisplay seg5(debug_en, 1'b0, value[23:20], hex[5]);

endmodule

module segdisplay(
    input enable,
    input dp,
    input [3:0] num,
    output reg [7:0] segments
);
    always @*
        if (~enable) segments <= 8'hff;
        else case (num)
            'h0: segments <= {~dp, 7'b1000000};
            'h1: segments <= {~dp, 7'b1111001};
            'h2: segments <= {~dp, 7'b0100100};
            'h3: segments <= {~dp, 7'b0110000};
            'h4: segments <= {~dp, 7'b0011001};
            'h5: segments <= {~dp, 7'b0010010};
            'h6: segments <= {~dp, 7'b0000010};
            'h7: segments <= {~dp, 7'b1111000};
            'h8: segments <= {~dp, 7'b0000000};
            'h9: segments <= {~dp, 7'b0011000};
            'ha: segments <= {~dp, 7'b0001000};
            'hb: segments <= {~dp, 7'b0000011};
            'hc: segments <= {~dp, 7'b1000110};
            'hd: segments <= {~dp, 7'b0100001};
            'he: segments <= {~dp, 7'b0000110};
            'hf: segments <= {~dp, 7'b0001110};
        endcase
endmodule