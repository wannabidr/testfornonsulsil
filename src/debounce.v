//==============================================================================
// Button Debounce Module
// Removes mechanical chattering (~20ms debounce time)
//==============================================================================
module debounce (
    input  wire clk,        // System clock (25MHz)
    input  wire rst_n,      // Active low reset
    input  wire btn_in,     // Raw button input
    output reg  btn_out,    // Debounced output
    output reg  btn_pulse   // Single pulse on button press
);

    // 25MHz * 20ms = 500,000 cycles for debounce
    localparam DEBOUNCE_CNT = 500000 - 1;

    reg [18:0] cnt;
    reg btn_sync0, btn_sync1;
    reg btn_prev;

    // Synchronizer (metastability prevention)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync0 <= 1'b0;
            btn_sync1 <= 1'b0;
        end else begin
            btn_sync0 <= btn_in;
            btn_sync1 <= btn_sync0;
        end
    end

    // Debounce logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 19'd0;
            btn_out <= 1'b0;
        end else begin
            if (btn_sync1 != btn_out) begin
                if (cnt >= DEBOUNCE_CNT) begin
                    cnt     <= 19'd0;
                    btn_out <= btn_sync1;
                end else begin
                    cnt <= cnt + 1'b1;
                end
            end else begin
                cnt <= 19'd0;
            end
        end
    end

    // Edge detection for single pulse
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_prev  <= 1'b0;
            btn_pulse <= 1'b0;
        end else begin
            btn_prev  <= btn_out;
            btn_pulse <= btn_out & ~btn_prev;  // Rising edge detection
        end
    end

endmodule

