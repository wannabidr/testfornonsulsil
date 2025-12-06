// Keypad Decoder - Phone style input
// BTN 0-7 maps to keys 2-9 (ABC, DEF, GHI, JKL, MNO, PQRS, TUV, WXYZ)
// Same button press cycles through characters
// Confirm button finalizes character

module keypad_decoder (
    input  wire       clk,
    input  wire       clk_5hz,
    input  wire       rst,
    input  wire [7:0] btn,          // 8 buttons
    input  wire       btn_confirm,  // Confirm current character
    output reg  [7:0] ascii_out,
    output reg        char_valid
);

    // Character tables
    reg [7:0] char_table [0:7][0:3];  // [button][cycle]
    reg [2:0] char_count [0:7];        // chars per button
    
    reg [7:0] btn_prev;
    reg [2:0] current_btn;
    reg [1:0] cycle_idx;
    reg       btn_active;
    reg [3:0] timeout_cnt;
    reg       clk_5hz_prev;
    wire      clk_5hz_rise;
    reg       confirm_prev;
    wire      confirm_rise;

    integer i;

    // Initialize character tables
    initial begin
        // Button 0 -> 2: ABC
        char_table[0][0] = 8'h41; char_table[0][1] = 8'h42;
        char_table[0][2] = 8'h43; char_table[0][3] = 8'h00;
        char_count[0] = 3'd3;
        // Button 1 -> 3: DEF
        char_table[1][0] = 8'h44; char_table[1][1] = 8'h45;
        char_table[1][2] = 8'h46; char_table[1][3] = 8'h00;
        char_count[1] = 3'd3;
        // Button 2 -> 4: GHI
        char_table[2][0] = 8'h47; char_table[2][1] = 8'h48;
        char_table[2][2] = 8'h49; char_table[2][3] = 8'h00;
        char_count[2] = 3'd3;
        // Button 3 -> 5: JKL
        char_table[3][0] = 8'h4A; char_table[3][1] = 8'h4B;
        char_table[3][2] = 8'h4C; char_table[3][3] = 8'h00;
        char_count[3] = 3'd3;
        // Button 4 -> 6: MNO
        char_table[4][0] = 8'h4D; char_table[4][1] = 8'h4E;
        char_table[4][2] = 8'h4F; char_table[4][3] = 8'h00;
        char_count[4] = 3'd3;
        // Button 5 -> 7: PQRS
        char_table[5][0] = 8'h50; char_table[5][1] = 8'h51;
        char_table[5][2] = 8'h52; char_table[5][3] = 8'h53;
        char_count[5] = 3'd4;
        // Button 6 -> 8: TUV
        char_table[6][0] = 8'h54; char_table[6][1] = 8'h55;
        char_table[6][2] = 8'h56; char_table[6][3] = 8'h00;
        char_count[6] = 3'd3;
        // Button 7 -> 9: WXYZ
        char_table[7][0] = 8'h57; char_table[7][1] = 8'h58;
        char_table[7][2] = 8'h59; char_table[7][3] = 8'h5A;
        char_count[7] = 3'd4;
    end

    // Edge detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_prev <= 8'd0;
            clk_5hz_prev <= 1'b0;
            confirm_prev <= 1'b0;
        end else begin
            btn_prev <= btn;
            clk_5hz_prev <= clk_5hz;
            confirm_prev <= btn_confirm;
        end
    end
    
    assign clk_5hz_rise = clk_5hz & ~clk_5hz_prev;
    assign confirm_rise = btn_confirm & ~confirm_prev;

    // Find which button pressed (priority encoder)
    function [2:0] get_btn_idx;
        input [7:0] buttons;
        begin
            casez (buttons)
                8'b???????1: get_btn_idx = 3'd0;
                8'b??????10: get_btn_idx = 3'd1;
                8'b?????100: get_btn_idx = 3'd2;
                8'b????1000: get_btn_idx = 3'd3;
                8'b???10000: get_btn_idx = 3'd4;
                8'b??100000: get_btn_idx = 3'd5;
                8'b?1000000: get_btn_idx = 3'd6;
                8'b10000000: get_btn_idx = 3'd7;
                default: get_btn_idx = 3'd0;
            endcase
        end
    endfunction

    // Main logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ascii_out <= 8'h00;
            char_valid <= 1'b0;
            current_btn <= 3'd0;
            cycle_idx <= 2'd0;
            btn_active <= 1'b0;
            timeout_cnt <= 4'd0;
        end else begin
            char_valid <= 1'b0;
            
            // Button press detection
            if (btn != 8'd0 && btn_prev == 8'd0) begin
                if (!btn_active) begin
                    // New button
                    current_btn <= get_btn_idx(btn);
                    cycle_idx <= 2'd0;
                    btn_active <= 1'b1;
                    timeout_cnt <= 4'd0;
                    ascii_out <= char_table[get_btn_idx(btn)][0];
                end else if (get_btn_idx(btn) == current_btn) begin
                    // Same button - cycle
                    if (cycle_idx < char_count[current_btn] - 1)
                        cycle_idx <= cycle_idx + 1'b1;
                    else
                        cycle_idx <= 2'd0;
                    ascii_out <= char_table[current_btn][cycle_idx + 1];
                    timeout_cnt <= 4'd0;
                end else begin
                    // Different button - confirm previous, start new
                    char_valid <= 1'b1;
                    current_btn <= get_btn_idx(btn);
                    cycle_idx <= 2'd0;
                    ascii_out <= char_table[get_btn_idx(btn)][0];
                    timeout_cnt <= 4'd0;
                end
            end
            
            // Confirm button
            if (confirm_rise && btn_active) begin
                char_valid <= 1'b1;
                btn_active <= 1'b0;
                timeout_cnt <= 4'd0;
            end
            
            // Timeout (auto-confirm after ~2 seconds)
            if (btn_active && clk_5hz_rise) begin
                if (timeout_cnt >= 4'd10) begin
                    char_valid <= 1'b1;
                    btn_active <= 1'b0;
                    timeout_cnt <= 4'd0;
                end else begin
                    timeout_cnt <= timeout_cnt + 1'b1;
                end
            end
        end
    end

endmodule
