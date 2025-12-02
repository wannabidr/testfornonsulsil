//==============================================================================
// 4x4 Keypad Scanner Module
// Scans matrix keypad and outputs ASCII alphabet code
//==============================================================================
module keypad_scanner (
    input  wire       clk,          // System clock (25MHz)
    input  wire       rst_n,        // Active low reset
    input  wire [3:0] col,          // Column input (directly active, directly active)
    output reg  [3:0] row,          // Row scan output (directly active)
    output reg  [4:0] key_code,     // ASCII code of pressed key (0-25 for A-Z)
    output reg        key_valid     // Key press detected pulse
);

    // Scan timing: ~1ms per row at 25MHz -> 25000 cycles
    localparam SCAN_CNT = 25000 - 1;

    // States
    localparam S_ROW0 = 2'd0;
    localparam S_ROW1 = 2'd1;
    localparam S_ROW2 = 2'd2;
    localparam S_ROW3 = 2'd3;

    reg [1:0]  state;
    reg [14:0] scan_cnt;
    reg [3:0]  col_sync0, col_sync1;
    reg [3:0]  detected_key;
    reg        key_pressed;
    reg        key_pressed_prev;

    // Keypad layout mapping to alphabet (A-Z, mapped to 16 keys)
    // Row0: A, B, C, D
    // Row1: E, F, G, H
    // Row2: I, J, K, L
    // Row3: M, N, O, P
    // Additional keys can be mapped for more letters

    // Column synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            col_sync0 <= 4'b1111;
            col_sync1 <= 4'b1111;
        end else begin
            col_sync0 <= col;
            col_sync1 <= col_sync0;
        end
    end

    // Row scanning FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= S_ROW0;
            row      <= 4'b0001;
            scan_cnt <= 15'd0;
        end else begin
            if (scan_cnt >= SCAN_CNT) begin
                scan_cnt <= 15'd0;
                case (state)
                    S_ROW0: begin state <= S_ROW1; row <= 4'b0010; end
                    S_ROW1: begin state <= S_ROW2; row <= 4'b0100; end
                    S_ROW2: begin state <= S_ROW3; row <= 4'b1000; end
                    S_ROW3: begin state <= S_ROW0; row <= 4'b0001; end
                endcase
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end
        end
    end

    // Key detection and decoding
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detected_key <= 4'd0;
            key_pressed  <= 1'b0;
        end else begin
            // Check after settling time (half of scan period)
            if (scan_cnt == SCAN_CNT[14:1]) begin
                key_pressed <= 1'b0;
                case (state)
                    S_ROW0: begin
                        if (col_sync1[0]) begin detected_key <= 4'd0;  key_pressed <= 1'b1; end  // A
                        else if (col_sync1[1]) begin detected_key <= 4'd1;  key_pressed <= 1'b1; end  // B
                        else if (col_sync1[2]) begin detected_key <= 4'd2;  key_pressed <= 1'b1; end  // C
                        else if (col_sync1[3]) begin detected_key <= 4'd3;  key_pressed <= 1'b1; end  // D
                    end
                    S_ROW1: begin
                        if (col_sync1[0]) begin detected_key <= 4'd4;  key_pressed <= 1'b1; end  // E
                        else if (col_sync1[1]) begin detected_key <= 4'd5;  key_pressed <= 1'b1; end  // F
                        else if (col_sync1[2]) begin detected_key <= 4'd6;  key_pressed <= 1'b1; end  // G
                        else if (col_sync1[3]) begin detected_key <= 4'd7;  key_pressed <= 1'b1; end  // H
                    end
                    S_ROW2: begin
                        if (col_sync1[0]) begin detected_key <= 4'd8;  key_pressed <= 1'b1; end  // I
                        else if (col_sync1[1]) begin detected_key <= 4'd9;  key_pressed <= 1'b1; end  // J
                        else if (col_sync1[2]) begin detected_key <= 4'd10; key_pressed <= 1'b1; end  // K
                        else if (col_sync1[3]) begin detected_key <= 4'd11; key_pressed <= 1'b1; end  // L
                    end
                    S_ROW3: begin
                        if (col_sync1[0]) begin detected_key <= 4'd12; key_pressed <= 1'b1; end  // M
                        else if (col_sync1[1]) begin detected_key <= 4'd13; key_pressed <= 1'b1; end  // N
                        else if (col_sync1[2]) begin detected_key <= 4'd14; key_pressed <= 1'b1; end  // O
                        else if (col_sync1[3]) begin detected_key <= 4'd15; key_pressed <= 1'b1; end  // P
                    end
                endcase
            end
        end
    end

    // Output key code and valid pulse (edge detection)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_code        <= 5'd0;
            key_valid       <= 1'b0;
            key_pressed_prev <= 1'b0;
        end else begin
            key_pressed_prev <= key_pressed;
            // Rising edge of key_pressed
            if (key_pressed && !key_pressed_prev) begin
                key_code  <= {1'b0, detected_key};
                key_valid <= 1'b1;
            end else begin
                key_valid <= 1'b0;
            end
        end
    end

endmodule

