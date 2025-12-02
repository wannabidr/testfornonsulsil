//==============================================================================
// Button Input Module
// 12 push buttons mapped to alphabet A-L (0-11)
// Includes debouncing for all buttons
//==============================================================================
module button_input (
    input  wire        clk,          // System clock (25MHz)
    input  wire        rst_n,        // Active low reset
    input  wire [11:0] btn,          // 12 button inputs (active high)
    output reg  [4:0]  key_code,     // Key code (0-11 for A-L)
    output reg         key_valid     // Key press detected pulse
);

    // Debounce time: ~20ms at 25MHz = 500,000 cycles
    localparam DEBOUNCE_CNT = 500000 - 1;

    // Synchronized and debounced button signals
    reg [11:0] btn_sync0, btn_sync1;
    reg [11:0] btn_debounced;
    reg [11:0] btn_prev;
    reg [18:0] cnt [11:0];

    integer i;

    // 2-stage synchronizer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync0 <= 12'd0;
            btn_sync1 <= 12'd0;
        end else begin
            btn_sync0 <= btn;
            btn_sync1 <= btn_sync0;
        end
    end

    // Debounce logic for each button
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_debounced <= 12'd0;
            for (i = 0; i < 12; i = i + 1) begin
                cnt[i] <= 19'd0;
            end
        end else begin
            for (i = 0; i < 12; i = i + 1) begin
                if (btn_sync1[i] != btn_debounced[i]) begin
                    if (cnt[i] >= DEBOUNCE_CNT) begin
                        cnt[i] <= 19'd0;
                        btn_debounced[i] <= btn_sync1[i];
                    end else begin
                        cnt[i] <= cnt[i] + 1'b1;
                    end
                end else begin
                    cnt[i] <= 19'd0;
                end
            end
        end
    end

    // Edge detection and priority encoder
    reg [11:0] btn_rising;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_prev <= 12'd0;
        end else begin
            btn_prev <= btn_debounced;
        end
    end

    // Detect rising edges
    always @(*) begin
        btn_rising = btn_debounced & ~btn_prev;
    end

    // Priority encoder: output key code for first pressed button
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_code  <= 5'd0;
            key_valid <= 1'b0;
        end else begin
            key_valid <= 1'b0;
            
            // Priority encoder (button 0 has highest priority)
            if (btn_rising[0])       begin key_code <= 5'd0;  key_valid <= 1'b1; end  // A
            else if (btn_rising[1])  begin key_code <= 5'd1;  key_valid <= 1'b1; end  // B
            else if (btn_rising[2])  begin key_code <= 5'd2;  key_valid <= 1'b1; end  // C
            else if (btn_rising[3])  begin key_code <= 5'd3;  key_valid <= 1'b1; end  // D
            else if (btn_rising[4])  begin key_code <= 5'd4;  key_valid <= 1'b1; end  // E
            else if (btn_rising[5])  begin key_code <= 5'd5;  key_valid <= 1'b1; end  // F
            else if (btn_rising[6])  begin key_code <= 5'd6;  key_valid <= 1'b1; end  // G
            else if (btn_rising[7])  begin key_code <= 5'd7;  key_valid <= 1'b1; end  // H
            else if (btn_rising[8])  begin key_code <= 5'd8;  key_valid <= 1'b1; end  // I
            else if (btn_rising[9])  begin key_code <= 5'd9;  key_valid <= 1'b1; end  // J
            else if (btn_rising[10]) begin key_code <= 5'd10; key_valid <= 1'b1; end  // K
            else if (btn_rising[11]) begin key_code <= 5'd11; key_valid <= 1'b1; end  // L
        end
    end

endmodule

