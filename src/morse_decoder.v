// Morse Decoder
// Converts morse code sequence to ASCII character

module morse_decoder (
    input  wire [4:0] morse_code,
    input  wire [2:0] morse_len,
    output reg  [7:0] ascii_out
);

    // Morse code: 0 = dot, 1 = dash
    // Codes are MSB first (first symbol in highest bit position based on length)
    
    always @(*) begin
        case (morse_len)
            3'd1: begin
                case (morse_code[4])
                    1'b0: ascii_out = 8'h45; // E .
                    1'b1: ascii_out = 8'h54; // T -
                endcase
            end
            
            3'd2: begin
                case (morse_code[4:3])
                    2'b00: ascii_out = 8'h49; // I ..
                    2'b01: ascii_out = 8'h41; // A .-
                    2'b10: ascii_out = 8'h4E; // N -.
                    2'b11: ascii_out = 8'h4D; // M --
                endcase
            end
            
            3'd3: begin
                case (morse_code[4:2])
                    3'b000: ascii_out = 8'h53; // S ...
                    3'b001: ascii_out = 8'h55; // U ..-
                    3'b010: ascii_out = 8'h52; // R .-.
                    3'b011: ascii_out = 8'h57; // W .--
                    3'b100: ascii_out = 8'h44; // D -..
                    3'b101: ascii_out = 8'h4B; // K -.-
                    3'b110: ascii_out = 8'h47; // G --.
                    3'b111: ascii_out = 8'h4F; // O ---
                endcase
            end
            
            3'd4: begin
                case (morse_code[4:1])
                    4'b0000: ascii_out = 8'h48; // H ....
                    4'b0001: ascii_out = 8'h56; // V ...-
                    4'b0010: ascii_out = 8'h46; // F ..-.
                    4'b0011: ascii_out = 8'h00; // (unused)
                    4'b0100: ascii_out = 8'h4C; // L .-..
                    4'b0101: ascii_out = 8'h00; // (unused)
                    4'b0110: ascii_out = 8'h50; // P .--.
                    4'b0111: ascii_out = 8'h4A; // J .---
                    4'b1000: ascii_out = 8'h42; // B -...
                    4'b1001: ascii_out = 8'h58; // X -..-
                    4'b1010: ascii_out = 8'h43; // C -.-.
                    4'b1011: ascii_out = 8'h59; // Y -.--
                    4'b1100: ascii_out = 8'h5A; // Z --..
                    4'b1101: ascii_out = 8'h51; // Q --.-
                    4'b1110: ascii_out = 8'h00; // (unused)
                    4'b1111: ascii_out = 8'h00; // (unused)
                endcase
            end
            
            3'd5: begin
                case (morse_code[4:0])
                    5'b00000: ascii_out = 8'h35; // 5 .....
                    5'b00001: ascii_out = 8'h34; // 4 ....-
                    5'b00011: ascii_out = 8'h33; // 3 ...--
                    5'b00111: ascii_out = 8'h32; // 2 ..---
                    5'b01111: ascii_out = 8'h31; // 1 .----
                    5'b11111: ascii_out = 8'h30; // 0 -----
                    5'b11110: ascii_out = 8'h39; // 9 ----.
                    5'b11100: ascii_out = 8'h38; // 8 ---..
                    5'b11000: ascii_out = 8'h37; // 7 --...
                    5'b10000: ascii_out = 8'h36; // 6 -....
                    default: ascii_out = 8'h00;
                endcase
            end
            
            default: ascii_out = 8'h00;
        endcase
    end

endmodule
