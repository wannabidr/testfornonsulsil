//==============================================================================
// Morse Code Encoder ROM
// Converts alphabet (A-Z, 0-25) to morse code pattern
// Output format: {length[2:0], pattern[4:0]} where 0=dot, 1=dash
// Pattern is LSB-first (first symbol in bit[0])
//==============================================================================
module morse_encoder (
    input  wire [4:0] char_code,    // Input character (0-25 for A-Z)
    output reg  [2:0] morse_len,    // Number of symbols (1-5)
    output reg  [4:0] morse_pattern // Morse pattern (LSB first)
);

    // International Morse Code lookup table
    // A=0, B=1, ..., Z=25
    always @(*) begin
        case (char_code)
            // A: .-    (dot, dash)
            5'd0:  begin morse_len = 3'd2; morse_pattern = 5'b00010; end
            // B: -...  (dash, dot, dot, dot)
            5'd1:  begin morse_len = 3'd4; morse_pattern = 5'b00001; end
            // C: -.-.  (dash, dot, dash, dot)
            5'd2:  begin morse_len = 3'd4; morse_pattern = 5'b00101; end
            // D: -..   (dash, dot, dot)
            5'd3:  begin morse_len = 3'd3; morse_pattern = 5'b00001; end
            // E: .     (dot)
            5'd4:  begin morse_len = 3'd1; morse_pattern = 5'b00000; end
            // F: ..-.  (dot, dot, dash, dot)
            5'd5:  begin morse_len = 3'd4; morse_pattern = 5'b00100; end
            // G: --.   (dash, dash, dot)
            5'd6:  begin morse_len = 3'd3; morse_pattern = 5'b00011; end
            // H: ....  (dot, dot, dot, dot)
            5'd7:  begin morse_len = 3'd4; morse_pattern = 5'b00000; end
            // I: ..    (dot, dot)
            5'd8:  begin morse_len = 3'd2; morse_pattern = 5'b00000; end
            // J: .---  (dot, dash, dash, dash)
            5'd9:  begin morse_len = 3'd4; morse_pattern = 5'b01110; end
            // K: -.-   (dash, dot, dash)
            5'd10: begin morse_len = 3'd3; morse_pattern = 5'b00101; end
            // L: .-..  (dot, dash, dot, dot)
            5'd11: begin morse_len = 3'd4; morse_pattern = 5'b00010; end
            // M: --    (dash, dash)
            5'd12: begin morse_len = 3'd2; morse_pattern = 5'b00011; end
            // N: -.    (dash, dot)
            5'd13: begin morse_len = 3'd2; morse_pattern = 5'b00001; end
            // O: ---   (dash, dash, dash)
            5'd14: begin morse_len = 3'd3; morse_pattern = 5'b00111; end
            // P: .--.  (dot, dash, dash, dot)
            5'd15: begin morse_len = 3'd4; morse_pattern = 5'b00110; end
            // Q: --.-  (dash, dash, dot, dash)
            5'd16: begin morse_len = 3'd4; morse_pattern = 5'b01011; end
            // R: .-.   (dot, dash, dot)
            5'd17: begin morse_len = 3'd3; morse_pattern = 5'b00010; end
            // S: ...   (dot, dot, dot)
            5'd18: begin morse_len = 3'd3; morse_pattern = 5'b00000; end
            // T: -     (dash)
            5'd19: begin morse_len = 3'd1; morse_pattern = 5'b00001; end
            // U: ..-   (dot, dot, dash)
            5'd20: begin morse_len = 3'd3; morse_pattern = 5'b00100; end
            // V: ...-  (dot, dot, dot, dash)
            5'd21: begin morse_len = 3'd4; morse_pattern = 5'b01000; end
            // W: .--   (dot, dash, dash)
            5'd22: begin morse_len = 3'd3; morse_pattern = 5'b00110; end
            // X: -..-  (dash, dot, dot, dash)
            5'd23: begin morse_len = 3'd4; morse_pattern = 5'b01001; end
            // Y: -.--  (dash, dot, dash, dash)
            5'd24: begin morse_len = 3'd4; morse_pattern = 5'b01101; end
            // Z: --..  (dash, dash, dot, dot)
            5'd25: begin morse_len = 3'd4; morse_pattern = 5'b00011; end
            // Default: single dot
            default: begin morse_len = 3'd1; morse_pattern = 5'b00000; end
        endcase
    end

endmodule

