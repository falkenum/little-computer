
module vga(
    input clk,           // base clock
    input mem_stb,           
    input pix_stb,           
    input rst,           // reset: restarts frame
    input [31:0][11:0] mem_bgr_buf,
    input enable,
    output hs,           // horizontal sync
    output vs,           // vertical sync
    output [3:0] rval,
    output [3:0] gval,
    output [3:0] bval,
    output vblank,
    output mem_fetch_en,
    output [4:0] mem_fetch_x_group,
    output [8:0] mem_fetch_y_val
);

    localparam HS_START = 16;              // horizontal sync start
    localparam HS_END = 16 + 96;         // horizontal sync end
    localparam HA_START = 16 + 96 + 48;    // horizontal active pixel start
    localparam VS_START = 480 + 10;        // vertical sync start
    localparam VS_END = 480 + 10 + 2;    // vertical sync end
    localparam VA_END = 480;             // vertical active pixel end
    localparam TICKS_PER_LINE = 800;             // complete line (pixels)
    localparam LINES_PER_SCREEN = 525;             // complete screen (lines)

    reg [9:0] h_count;  // line position
    reg [9:0] v_count;  // screen position
    reg [31:0][11:0] mem_bgr_buf_r;

    wire active = enable & ~((h_count < HA_START) | (v_count > VA_END - 1)); 

    assign mem_fetch_en = (enable && v_count < VA_END) ? (h_count >= 128 && h_count < 768) : 0;
    assign mem_fetch_x_group = (h_count - 128) >> 5;
    // assign mem_fetch_x_group = 1;
    assign mem_fetch_y_val = v_count[8:0];
    // assign mem_fetch_y_val = 0;


    assign rval = active ? mem_bgr_buf_r[h_count & 'h1F][3:0] : 4'b0;
    assign gval = active ? mem_bgr_buf_r[h_count & 'h1F][7:4] : 4'b0;
    assign bval = active ? mem_bgr_buf_r[h_count & 'h1F][11:8] : 4'b0;
    assign hs = ~((h_count >= HS_START) & (h_count < HS_END));
    assign vs = ~((v_count >= VS_START) & (v_count < VS_END));

    // keep x and y bound within the active pixels
    // assign x = (h_count < HA_START) ? 0 : (h_count - HA_START);
    // assign y = (v_count >= VA_END) ? (VA_END - 1) : (v_count);

    // blanking: high within the blanking period
    assign vblank = v_count > VA_END - 1;

    // active: high during active pixel drawing

    // screenend: high for one tick at the end of the screen
    // assign o_screenend = ((v_count == SCREEN - 1) & (h_count == LINE));

    // animate: high for one tick at the end of the final active pixel line
    // assign o_animate = ((v_count == VA_END - 1) & (h_count == LINE));

    always @ (posedge clk) begin
        if (~rst)  // reset to start of frame
        begin
            h_count <= 0;
            v_count <= 0;
        end

        if (mem_stb) begin
            mem_bgr_buf_r <= mem_bgr_buf;
        end
        
        if (pix_stb)
        begin
            if (h_count == TICKS_PER_LINE - 1)  // end of line
            begin
                h_count <= 0;
                v_count <= v_count + 1;
            end
            else 
                h_count <= h_count + 1;

            if (v_count == LINES_PER_SCREEN - 1)  // end of screen
                v_count <= 0;
        end
    end
endmodule