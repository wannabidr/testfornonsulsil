// Morse Code Translator - Top Module
// Mode 0 (mode_sw=0): Alphabet -> Morse (LCD row2 -> 2s delay -> row1 + Buzzer)
// Mode 1 (mode_sw=1): Morse -> Alphabet (LCD row1 direct)

module morse_top (
    input  wire        clk,           // 1MHz clock (B6)
    input  wire        rst,           // Reset (DIP_SW8)
    input  wire        mode_sw,       // Mode switch (DIP_SW1)
    input  wire [11:0] btn,           // 12 push buttons (KEY01-KEY12)
    output wire        lcd_rs,        // LCD RS
    output wire        lcd_rw,        // LCD RW
    output wire        lcd_en,        // LCD Enable
    output wire [7:0]  lcd_data,      // LCD Data
    output wire        buzzer         // Piezo buzzer (Y21)
);

    // Internal clocks
    wire clk_1khz, clk_500hz, clk_5hz;
    
    // Debounced buttons
    wire [11:0] btn_db;
    
    // Mode 0 signals
    wire [7:0] keypad_btn;
    wire keypad_confirm;
    wire [7:0] keypad_ascii;
    wire keypad_valid;
    wire [4:0] enc_morse_code;
    wire [2:0] enc_morse_len;
    
    // Mode 1 signals
    wire morse_dot;
    wire morse_dash;
    wire morse_confirm;
    wire [4:0] dec_morse_code;
    wire [2:0] dec_morse_len;
    wire decode_valid;
    wire [7:0] decoded_ascii;
    
    // Buzzer signals
    wire buzzer_busy;
    
    // Mode 0 buffering: 2-second delay timer
    localparam DELAY_2SEC = 21'd2000000;  // 2s at 1MHz
    reg [20:0] delay_timer;
    reg waiting_transfer;
    reg transfer_trigger;
    reg delayed_buzzer_start;
    
    // Stored morse code for delayed buzzer
    reg [4:0] stored_morse_code;
    reg [2:0] stored_morse_len;
    
    // LCD control signals
    wire [7:0] lcd_char;
    wire lcd_char_valid;
    wire lcd_char_to_row2;
    wire lcd_transfer;
    
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
    assign keypad_btn = btn_db[8:1];
    assign keypad_confirm = btn_db[11];
    
    // Button mapping for Mode 1 (Morse input)
    assign morse_dot = btn_db[9];
    assign morse_dash = btn_db[10];
    assign morse_confirm = btn_db[11];
    
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
    
    // Mode 0: 2-second delay timer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            delay_timer <= 21'd0;
            waiting_transfer <= 1'b0;
            transfer_trigger <= 1'b0;
            delayed_buzzer_start <= 1'b0;
            stored_morse_code <= 5'd0;
            stored_morse_len <= 3'd0;
        end else begin
            transfer_trigger <= 1'b0;
            delayed_buzzer_start <= 1'b0;
            
            if (~mode_sw && keypad_valid) begin
                // Mode 0: Start 2-second timer, store morse code
                delay_timer <= 21'd0;
                waiting_transfer <= 1'b1;
                stored_morse_code <= enc_morse_code;
                stored_morse_len <= enc_morse_len;
            end else if (waiting_transfer) begin
                if (delay_timer < DELAY_2SEC) begin
                    delay_timer <= delay_timer + 1;
                end else begin
                    // 2 seconds elapsed: trigger transfer and buzzer
                    transfer_trigger <= 1'b1;
                    delayed_buzzer_start <= 1'b1;
                    waiting_transfer <= 1'b0;
                    delay_timer <= 21'd0;
                end
            end
        end
    end
    
    // LCD character selection
    // Mode 0: keypad_ascii to row2, Mode 1: decoded_ascii to row1
    assign lcd_char = mode_sw ? decoded_ascii : keypad_ascii;
    assign lcd_char_valid = mode_sw ? decode_valid : keypad_valid;
    assign lcd_char_to_row2 = ~mode_sw;  // Mode 0: input to row2
    assign lcd_transfer = transfer_trigger;
    
    // Buzzer control
    // Mode 0: delayed start after 2 seconds
    // Mode 1: no buzzer
    wire buzzer_start_signal = (~mode_sw) & delayed_buzzer_start & (~buzzer_busy);
    wire [4:0] buzzer_morse = stored_morse_code;
    wire [2:0] buzzer_len = stored_morse_len;
    
    // Buzzer driver
    buzzer_driver u_buzzer (
        .clk(clk),
        .clk_5hz(clk_5hz),
        .rst(rst),
        .start(buzzer_start_signal),
        .morse_code(buzzer_morse),
        .morse_len(buzzer_len),
        .buzzer_out(buzzer),
        .busy(buzzer_busy)
    );
    
    // Text LCD controller
    text_lcd_controller u_lcd (
        .clk(clk),
        .rst(rst),
        .char_in(lcd_char),
        .char_valid(lcd_char_valid),
        .char_to_row2(lcd_char_to_row2),
        .transfer_to_row1(lcd_transfer),
        .clear(rst),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en),
        .lcd_data(lcd_data)
    );

endmodule
