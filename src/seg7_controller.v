// 8-digit 7-Segment Controller
// Common Cathode (HIGH = ON)

module seg7_controller (
    input  wire       clk,        // 1MHz main clock for char_valid detection
    input  wire       clk_500hz,  // For display scanning
    input  wire       rst,
    input  wire [7:0] char_in,
    input  wire       char_valid,
    input  wire       clear,
    output reg  [7:0] seg,
    output reg  [7:0] digit_sel
);

    reg [7:0] char_buf [0:7];
    reg [2:0] char_idx;
    reg [2:0] scan_idx;
    integer i;
    
    // Edge detection for char_valid (in 1MHz domain)
    reg char_valid_prev;
    wire char_valid_rise;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            char_valid_prev <= 1'b0;
        else
            char_valid_prev <= char_valid;
    end
    assign char_valid_rise = char_valid & ~char_valid_prev;

    // Scan digits (500Hz domain)
    always @(posedge clk_500hz or posedge rst) begin
        if (rst)
            scan_idx <= 3'd0;
        else
            scan_idx <= scan_idx + 1'b1;
    end

    // Digit select
    always @(*) begin
        digit_sel = 8'b00000001 << scan_idx;
    end

    // Buffer management (1MHz domain for reliable char_valid detection)
    always @(posedge clk or posedge rst) begin
        if (rst || clear) begin
            for (i = 0; i < 8; i = i + 1)
                char_buf[i] <= 8'h20;
            char_idx <= 3'd0;
        end else if (char_valid_rise) begin
            char_buf[char_idx] <= char_in;
            char_idx <= (char_idx < 3'd7) ? char_idx + 1'b1 : 3'd0;
        end
    end

    // ASCII to 7-segment
    always @(*) begin
        case (char_buf[scan_idx])
            8'h41, 8'h61: seg = 8'b01110111; // A
            8'h42, 8'h62: seg = 8'b01111100; // b
            8'h43, 8'h63: seg = 8'b00111001; // C
            8'h44, 8'h64: seg = 8'b01011110; // d
            8'h45, 8'h65: seg = 8'b01111001; // E
            8'h46, 8'h66: seg = 8'b01110001; // F
            8'h47, 8'h67: seg = 8'b00111101; // G
            8'h48, 8'h68: seg = 8'b01110110; // H
            8'h49, 8'h69: seg = 8'b00000110; // I
            8'h4A, 8'h6A: seg = 8'b00011110; // J
            8'h4B, 8'h6B: seg = 8'b01110101; // K
            8'h4C, 8'h6C: seg = 8'b00111000; // L
            8'h4D, 8'h6D: seg = 8'b00010101; // M
            8'h4E, 8'h6E: seg = 8'b01010100; // n
            8'h4F, 8'h6F: seg = 8'b00111111; // O
            8'h50, 8'h70: seg = 8'b01110011; // P
            8'h51, 8'h71: seg = 8'b01100111; // Q
            8'h52, 8'h72: seg = 8'b01010000; // r
            8'h53, 8'h73: seg = 8'b01101101; // S
            8'h54, 8'h74: seg = 8'b01111000; // t
            8'h55, 8'h75: seg = 8'b00111110; // U
            8'h56, 8'h76: seg = 8'b00011100; // V
            8'h57, 8'h77: seg = 8'b00101010; // W
            8'h58, 8'h78: seg = 8'b01110110; // X
            8'h59, 8'h79: seg = 8'b01101110; // Y
            8'h5A, 8'h7A: seg = 8'b01011011; // Z
            8'h30: seg = 8'b00111111; // 0
            8'h31: seg = 8'b00000110; // 1
            8'h32: seg = 8'b01011011; // 2
            8'h33: seg = 8'b01001111; // 3
            8'h34: seg = 8'b01100110; // 4
            8'h35: seg = 8'b01101101; // 5
            8'h36: seg = 8'b01111101; // 6
            8'h37: seg = 8'b00000111; // 7
            8'h38: seg = 8'b01111111; // 8
            8'h39: seg = 8'b01101111; // 9
            8'h2D: seg = 8'b01000000; // -
            8'h2E: seg = 8'b10000000; // .
            default: seg = 8'b00000000;
        endcase
    end

endmodule
