// Morse Code Translator - Top Module
// Mode 0: Alphabet -> Morse (Buzzer output)
// Mode 1: Morse -> Alphabet (7-segment output)

module morse_top (
    input  wire       clk,           // 1MHz clock
    input  wire       rst,           // Reset button
    input  wire       mode_sw,       // Mode switch (0: A->M, 1: M->A)
    input  wire [7:0] btn,           // 8 push buttons
    input  wire       btn_confirm,   // Confirm/Enter button
    input  wire       btn_dot,       // Dot input (Mode 1)
    input  wire       btn_dash,      // Dash input (Mode 1)
    output wire [7:0] seg,           // 7-segment segments
    output wire [7:0] digit_sel,     // 7-segment digit select
    output wire       buzzer         // Piezo buzzer
);

    // Internal clocks
    wire clk_1khz, clk_500hz, clk_5hz;
    
    // Debounced buttons
    wire [7:0] btn_db;
    wire btn_confirm_db, btn_dot_db, btn_dash_db, rst_db;
    
    // Mode 0 signals
    wire [7:0] keypad_ascii;
    wire keypad_valid;
    wire [4:0] enc_morse_code;
    wire [2:0] enc_morse_len;
    
    // Mode 1 signals
    wire [4:0] dec_morse_code;
    wire [2:0] dec_morse_len;
    wire decode_valid;
    wire [7:0] decoded_ascii;
    
    // Output signals
    wire [7:0] display_char;
    wire display_valid;
    wire buzzer_start;
    wire [4:0] buzzer_morse;
    wire [2:0] buzzer_len;
    wire buzzer_busy;
    
    // Clock divider
    clk_divider u_clk_div (
        .clk(clk),
        .rst(rst),
        .clk_1khz(clk_1khz),
        .clk_500hz(clk_500hz),
        .clk_5hz(clk_5hz)
    );
    
    // Debounce for all buttons
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : btn_debounce
            debounce u_db (
                .clk_1khz(clk_1khz),
                .rst(rst),
                .btn_in(btn[i]),
                .btn_out(btn_db[i])
            );
        end
    endgenerate
    
    debounce u_db_confirm (
        .clk_1khz(clk_1khz),
        .rst(rst),
        .btn_in(btn_confirm),
        .btn_out(btn_confirm_db)
    );
    
    debounce u_db_dot (
        .clk_1khz(clk_1khz),
        .rst(rst),
        .btn_in(btn_dot),
        .btn_out(btn_dot_db)
    );
    
    debounce u_db_dash (
        .clk_1khz(clk_1khz),
        .rst(rst),
        .btn_in(btn_dash),
        .btn_out(btn_dash_db)
    );
    
    // Mode 0: Keypad decoder
    keypad_decoder u_keypad (
        .clk(clk),
        .clk_5hz(clk_5hz),
        .rst(rst),
        .btn(btn_db),
        .btn_confirm(btn_confirm_db),
        .ascii_out(keypad_ascii),
        .char_valid(keypad_valid)
    );
    
    // Mode 0: Morse encoder
    morse_encoder u_encoder (
        .ascii_in(keypad_ascii),
        .morse_code(enc_morse_code),
        .morse_len(enc_morse_len)
    );
    
    // Mode 1: Morse input FSM
    morse_input_fsm u_morse_input (
        .clk(clk),
        .rst(rst),
        .btn_dot(btn_dot_db),
        .btn_dash(btn_dash_db),
        .btn_enter(btn_confirm_db),
        .morse_code(dec_morse_code),
        .morse_len(dec_morse_len),
        .decode_valid(decode_valid)
    );
    
    // Mode 1: Morse decoder
    morse_decoder u_decoder (
        .morse_code(dec_morse_code),
        .morse_len(dec_morse_len),
        .ascii_out(decoded_ascii)
    );
    
    // Mode selection for display
    assign display_char = mode_sw ? decoded_ascii : keypad_ascii;
    assign display_valid = mode_sw ? decode_valid : keypad_valid;
    
    // Buzzer control (Mode 0 only)
    assign buzzer_start = (~mode_sw) & keypad_valid & (~buzzer_busy);
    assign buzzer_morse = enc_morse_code;
    assign buzzer_len = enc_morse_len;
    
    // Buzzer driver
    buzzer_driver u_buzzer (
        .clk(clk),
        .clk_5hz(clk_5hz),
        .rst(rst),
        .start(buzzer_start),
        .morse_code(buzzer_morse),
        .morse_len(buzzer_len),
        .buzzer_out(buzzer),
        .busy(buzzer_busy)
    );
    
    // 7-segment controller
    seg7_controller u_seg7 (
        .clk_500hz(clk_500hz),
        .rst(rst),
        .char_in(display_char),
        .char_valid(display_valid),
        .clear(rst),
        .seg(seg),
        .digit_sel(digit_sel)
    );

endmodule
