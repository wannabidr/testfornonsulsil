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
    
    // Character queue for Mode 0 (max 16 entries)
    localparam DELAY_2SEC = 21'd2000000;  // 2s at 1MHz
    
    reg [7:0]  queue_char [0:15];
    reg [4:0]  queue_morse [0:15];
    reg [2:0]  queue_len [0:15];
    reg [20:0] queue_timer [0:15];
    reg [3:0]  queue_head;  // Next to process
    reg [3:0]  queue_tail;  // Next write position
    reg queue_empty;
    
    // Processing state
    reg transfer_trigger;
    reg buzzer_trigger;
    reg [7:0] transfer_char;
    reg [4:0] transfer_morse;
    reg [2:0] transfer_len;
    
    // LCD control signals
    wire [7:0] lcd_char;
    wire lcd_char_valid;
    wire lcd_char_to_row2;
    wire lcd_transfer;
    wire [7:0] lcd_transfer_char;
    
    integer i;
    
    // Clock divider
    clk_divider u_clk_div (
        .clk(clk),
        .rst(rst),
        .clk_1khz(clk_1khz),
        .clk_500hz(clk_500hz),
        .clk_5hz(clk_5hz)
    );
    
    // Debounce for all 12 buttons
    genvar gi;
    generate
        for (gi = 0; gi < 12; gi = gi + 1) begin : btn_debounce
            debounce u_db (
                .clk_1khz(clk_1khz),
                .rst(rst),
                .btn_in(btn[gi]),
                .btn_out(btn_db[gi])
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
    
    // Queue management and timer logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            queue_head <= 4'd0;
            queue_tail <= 4'd0;
            queue_empty <= 1'b1;
            transfer_trigger <= 1'b0;
            buzzer_trigger <= 1'b0;
            transfer_char <= 8'd0;
            transfer_morse <= 5'd0;
            transfer_len <= 3'd0;
            for (i = 0; i < 16; i = i + 1) begin
                queue_char[i] <= 8'd0;
                queue_morse[i] <= 5'd0;
                queue_len[i] <= 3'd0;
                queue_timer[i] <= 21'd0;
            end
        end else begin
            transfer_trigger <= 1'b0;
            buzzer_trigger <= 1'b0;
            
            // Add new character to queue (Mode 0 only)
            if (~mode_sw && keypad_valid) begin
                queue_char[queue_tail] <= keypad_ascii;
                queue_morse[queue_tail] <= enc_morse_code;
                queue_len[queue_tail] <= enc_morse_len;
                queue_timer[queue_tail] <= 21'd0;
                queue_tail <= queue_tail + 1;
                queue_empty <= 1'b0;
            end
            
            // Increment timers for all queued items
            if (!queue_empty) begin
                for (i = 0; i < 16; i = i + 1) begin
                    // Check if this slot is in active range
                    if ((queue_head <= queue_tail && i >= queue_head && i < queue_tail) ||
                        (queue_head > queue_tail && (i >= queue_head || i < queue_tail))) begin
                        if (queue_timer[i] < DELAY_2SEC) begin
                            queue_timer[i] <= queue_timer[i] + 1;
                        end
                    end
                end
            end
            
            // Check if head item is ready (2 seconds elapsed) and buzzer is free
            if (!queue_empty && !buzzer_busy && queue_timer[queue_head] >= DELAY_2SEC) begin
                // Transfer this character
                transfer_char <= queue_char[queue_head];
                transfer_morse <= queue_morse[queue_head];
                transfer_len <= queue_len[queue_head];
                transfer_trigger <= 1'b1;
                buzzer_trigger <= 1'b1;
                
                // Advance head
                queue_head <= queue_head + 1;
                
                // Check if queue becomes empty
                if (queue_head + 1 == queue_tail) begin
                    queue_empty <= 1'b1;
                end
            end
        end
    end
    
    // LCD character selection
    // Mode 0: keypad_ascii to row2
    // Mode 1: decoded_ascii to row1
    assign lcd_char = mode_sw ? decoded_ascii : keypad_ascii;
    assign lcd_char_valid = mode_sw ? decode_valid : keypad_valid;
    assign lcd_char_to_row2 = ~mode_sw;
    assign lcd_transfer = transfer_trigger;
    assign lcd_transfer_char = transfer_char;
    
    // Buzzer control
    wire buzzer_start_signal = (~mode_sw) & buzzer_trigger & (~buzzer_busy);
    wire [4:0] buzzer_morse = transfer_morse;
    wire [2:0] buzzer_len_out = transfer_len;
    
    // Buzzer driver
    buzzer_driver u_buzzer (
        .clk(clk),
        .clk_5hz(clk_5hz),
        .rst(rst),
        .start(buzzer_start_signal),
        .morse_code(buzzer_morse),
        .morse_len(buzzer_len_out),
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
        .transfer_char(lcd_transfer_char),
        .clear(rst),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_en(lcd_en),
        .lcd_data(lcd_data)
    );

endmodule
