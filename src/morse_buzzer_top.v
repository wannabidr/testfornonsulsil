//==============================================================================
// Morse Buzzer Test Top Module
// Keypad input -> Morse encode -> Buzzer output
//==============================================================================
module morse_buzzer_top (
    input  wire       clk,          // 25MHz system clock
    input  wire       rst_n,        // Active low reset (directly active)
    input  wire [3:0] keypad_col,   // Keypad column input
    output wire [3:0] keypad_row,   // Keypad row scan output
    output wire       buzzer,       // Piezo buzzer output
    output wire [7:0] led_debug     // Debug LEDs
);

    // Internal signals
    wire clk_1khz;
    wire clk_800hz;
    wire [4:0] key_code;
    wire key_valid;
    wire [2:0] morse_len;
    wire [4:0] morse_pattern;
    wire buzzer_busy;

    // Registers for control
    reg start_buzzer;
    reg [4:0] current_char;
    reg key_valid_d;

    // Clock divider instance
    clk_divider u_clk_divider (
        .clk       (clk),
        .rst_n     (rst_n),
        .clk_1khz  (clk_1khz),
        .clk_800hz (clk_800hz)
    );

    // Keypad scanner instance
    keypad_scanner u_keypad_scanner (
        .clk       (clk),
        .rst_n     (rst_n),
        .col       (keypad_col),
        .row       (keypad_row),
        .key_code  (key_code),
        .key_valid (key_valid)
    );

    // Morse encoder instance
    morse_encoder u_morse_encoder (
        .char_code     (current_char),
        .morse_len     (morse_len),
        .morse_pattern (morse_pattern)
    );

    // Buzzer driver instance
    buzzer_driver u_buzzer_driver (
        .clk           (clk),
        .rst_n         (rst_n),
        .clk_800hz     (clk_800hz),
        .start         (start_buzzer),
        .morse_len     (morse_len),
        .morse_pattern (morse_pattern),
        .buzzer_out    (buzzer),
        .busy          (buzzer_busy)
    );

    // Control logic: trigger buzzer on key press when not busy
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_buzzer <= 1'b0;
            current_char <= 5'd0;
            key_valid_d  <= 1'b0;
        end else begin
            key_valid_d <= key_valid;
            
            // Rising edge of key_valid and buzzer not busy
            if (key_valid && !key_valid_d && !buzzer_busy) begin
                current_char <= key_code;
                start_buzzer <= 1'b1;
            end else begin
                start_buzzer <= 1'b0;
            end
        end
    end

    // Debug LED output
    // [7:5] = morse_len (current)
    // [4:0] = key_code (last pressed)
    assign led_debug[4:0] = current_char;
    assign led_debug[5]   = buzzer_busy;
    assign led_debug[6]   = key_valid;
    assign led_debug[7]   = buzzer;

endmodule

