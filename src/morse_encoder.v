// Morse Encoder
// Converts ASCII character to morse code sequence

module morse_encoder (
    input  wire [7:0] ascii_in,
    output reg  [4:0] morse_code,
    output reg  [2:0] morse_len
);

    // Morse code: 0 = dot, 1 = dash
    // MSB first (first symbol in bit 4)
    
    always @(*) begin
        case (ascii_in)
            // Letters A-Z (uppercase)
            8'h41: begin morse_code = 5'b01000; morse_len = 3'd2; end // A .-
            8'h42: begin morse_code = 5'b10000; morse_len = 3'd4; end // B -...
            8'h43: begin morse_code = 5'b10100; morse_len = 3'd4; end // C -.-.
            8'h44: begin morse_code = 5'b10000; morse_len = 3'd3; end // D -..
            8'h45: begin morse_code = 5'b00000; morse_len = 3'd1; end // E .
            8'h46: begin morse_code = 5'b00100; morse_len = 3'd4; end // F ..-.
            8'h47: begin morse_code = 5'b11000; morse_len = 3'd3; end // G --.
            8'h48: begin morse_code = 5'b00000; morse_len = 3'd4; end // H ....
            8'h49: begin morse_code = 5'b00000; morse_len = 3'd2; end // I ..
            8'h4A: begin morse_code = 5'b01110; morse_len = 3'd4; end // J .---
            8'h4B: begin morse_code = 5'b10100; morse_len = 3'd3; end // K -.-
            8'h4C: begin morse_code = 5'b01000; morse_len = 3'd4; end // L .-..
            8'h4D: begin morse_code = 5'b11000; morse_len = 3'd2; end // M --
            8'h4E: begin morse_code = 5'b10000; morse_len = 3'd2; end // N -.
            8'h4F: begin morse_code = 5'b11100; morse_len = 3'd3; end // O ---
            8'h50: begin morse_code = 5'b01100; morse_len = 3'd4; end // P .--.
            8'h51: begin morse_code = 5'b11010; morse_len = 3'd4; end // Q --.-
            8'h52: begin morse_code = 5'b01000; morse_len = 3'd3; end // R .-.
            8'h53: begin morse_code = 5'b00000; morse_len = 3'd3; end // S ...
            8'h54: begin morse_code = 5'b10000; morse_len = 3'd1; end // T -
            8'h55: begin morse_code = 5'b00100; morse_len = 3'd3; end // U ..-
            8'h56: begin morse_code = 5'b00010; morse_len = 3'd4; end // V ...-
            8'h57: begin morse_code = 5'b01100; morse_len = 3'd3; end // W .--
            8'h58: begin morse_code = 5'b10010; morse_len = 3'd4; end // X -..-
            8'h59: begin morse_code = 5'b10110; morse_len = 3'd4; end // Y -.--
            8'h5A: begin morse_code = 5'b11000; morse_len = 3'd4; end // Z --..
            
            // Numbers 0-9
            8'h30: begin morse_code = 5'b11111; morse_len = 3'd5; end // 0 -----
            8'h31: begin morse_code = 5'b01111; morse_len = 3'd5; end // 1 .----
            8'h32: begin morse_code = 5'b00111; morse_len = 3'd5; end // 2 ..---
            8'h33: begin morse_code = 5'b00011; morse_len = 3'd5; end // 3 ...--
            8'h34: begin morse_code = 5'b00001; morse_len = 3'd5; end // 4 ....-
            8'h35: begin morse_code = 5'b00000; morse_len = 3'd5; end // 5 .....
            8'h36: begin morse_code = 5'b10000; morse_len = 3'd5; end // 6 -....
            8'h37: begin morse_code = 5'b11000; morse_len = 3'd5; end // 7 --...
            8'h38: begin morse_code = 5'b11100; morse_len = 3'd5; end // 8 ---..
            8'h39: begin morse_code = 5'b11110; morse_len = 3'd5; end // 9 ----.
            
            default: begin morse_code = 5'b00000; morse_len = 3'd0; end
        endcase
    end

endmodule
