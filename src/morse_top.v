// Morse Code Translator - Top Module
// Mode 0 (mode_sw=0): Alphabet -> Morse (Buzzer output)
// Mode 1 (mode_sw=1): Morse -> Alphabet (7-segment output)

module morse_top (
    input  wire        clk,           // 1MHz clock (B6)
    input  wire        rst,           // Reset (DIP_SW8)
    input  wire        mode_sw,       // Mode switch (DIP_SW1)
    input  wire [11:0] btn,           // 12 push buttons (KEY01-KEY12)
    output wire [7:0]  seg,           // 7-segment segments
    output wire [7:0]  digit_sel,     // 7-segment digit select
    output wire        buzzer         // Piezo buzzer (Y21)
);

    // Button mapping:
    // Mode 0 (Alphabet->Morse): Phone Keypad
    //   btn[0]=KEY01(1), btn[1]=KEY02(2:ABC), btn[2]=KEY03(3:DEF)
    //   btn[3]=KEY04(4:GHI), btn[4]=KEY05(5:JKL), btn[5]=KEY06(6:MNO)
    //   btn[6]=KEY07(7:PQRS), btn[7]=KEY08(8:TUV), btn[8]=KEY09(9:WXYZ)
    //   btn[9]=KEY10(*), btn[10]=KEY11(0:Space), btn[11]=KEY12(#:Confirm)
    //
    // Mode 1 (Morse->Alphabet):
    //   btn[0]=KEY01(Dot), btn[1]=KEY02(Dash), btn[2]=KEY03(Confirm)

    // Internal clocks
    wire clk_1khz, clk_500hz, clk_5hz;
    
    // Debounced buttons
    wire [11:0] btn_db;
    
    // Mode 0 signals
    wire [7:0] keypad_btn;      // Buttons for keypad (KEY02-KEY09)
    wire keypad_confirm;         // Confirm for keypad (KEY12)
    wire [7:0] keypad_ascii;
    wire keypad_valid;
    wire [4:0] enc_morse_code;
    wire [2:0] enc_morse_len;
    
    // Mode 1 signals
    wire morse_dot;              // Dot button (KEY01)
    wire morse_dash;             // Dash button (KEY02)
    wire morse_confirm;          // Confirm button (KEY03)
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
    
    // Debounce for all 12 buttons
    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : btn_debounce
            debounce u_db (
                .clk_1khz(clk_1khz),
                .rst(rst),
                .btn_in(btn[i]),
                .btn_out(btn_db[i])
            );
        end
    endgenerate
    
    // Button mapping for Mode 0 (Keypad)
    // KEY02-KEY09 (btn[1]-btn[8]) -> keypad buttons for 2-9
    assign keypad_btn = btn_db[8:1];
    assign keypad_confirm = btn_db[11];  // KEY12 (#)
    
    // Button mapping for Mode 1 (Morse input)
    assign morse_dot = btn_db[0];      // KEY01
    assign morse_dash = btn_db[1];     // KEY02
    assign morse_confirm = btn_db[2];  // KEY03
    
    // Mode 0: Keypad decoder
    keypad_decoder u_keypad (
        .clk(clk),
        .clk_5hz(clk_5hz),
        .rst(rst),
        .btn(keypad_btn),
        .btn_confirm(keypad_confirm),
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
        .btn_dot(morse_dot),
        .btn_dash(morse_dash),
        .btn_enter(morse_confirm),
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
