// Morse Input FSM
// Captures dot/dash button inputs and builds morse sequence

module morse_input_fsm (
    input  wire       clk,
    input  wire       rst,
    input  wire       btn_dot,
    input  wire       btn_dash,
    input  wire       btn_enter,
    output reg  [4:0] morse_code,
    output reg  [2:0] morse_len,
    output reg        decode_valid
);

    reg btn_dot_prev, btn_dash_prev, btn_enter_prev;
    wire dot_rise, dash_rise, enter_rise;

    // Edge detection
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_dot_prev <= 1'b0;
            btn_dash_prev <= 1'b0;
            btn_enter_prev <= 1'b0;
        end else begin
            btn_dot_prev <= btn_dot;
            btn_dash_prev <= btn_dash;
            btn_enter_prev <= btn_enter;
        end
    end

    assign dot_rise = btn_dot & ~btn_dot_prev;
    assign dash_rise = btn_dash & ~btn_dash_prev;
    assign enter_rise = btn_enter & ~btn_enter_prev;

    // Input capture
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            morse_code <= 5'b00000;
            morse_len <= 3'd0;
            decode_valid <= 1'b0;
        end else begin
            decode_valid <= 1'b0;
            
            if (dot_rise && morse_len < 3'd5) begin
                morse_code <= {morse_code[3:0], 1'b0};
                morse_len <= morse_len + 1'b1;
            end else if (dash_rise && morse_len < 3'd5) begin
                morse_code <= {morse_code[3:0], 1'b1};
                morse_len <= morse_len + 1'b1;
            end else if (enter_rise && morse_len > 0) begin
                decode_valid <= 1'b1;
            end
            
            // Clear after decode
            if (decode_valid) begin
                morse_code <= 5'b00000;
                morse_len <= 3'd0;
            end
        end
    end

endmodule
