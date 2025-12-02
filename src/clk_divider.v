//==============================================================================
// Clock Divider Module
// 25MHz -> 1kHz (timing control), 800Hz (buzzer tone)
//==============================================================================
module clk_divider (
    input  wire clk,        // 25MHz input clock
    input  wire rst_n,      // Active low reset
    output reg  clk_1khz,   // 1kHz output for timing
    output reg  clk_800hz   // 800Hz output for buzzer tone
);

    // 25MHz / 1kHz = 25000, half period = 12500
    // 25MHz / 800Hz = 31250, half period = 15625
    localparam DIV_1KHZ  = 12500 - 1;
    localparam DIV_800HZ = 15625 - 1;

    reg [13:0] cnt_1khz;
    reg [14:0] cnt_800hz;

    // 1kHz clock generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_1khz <= 14'd0;
            clk_1khz <= 1'b0;
        end else begin
            if (cnt_1khz >= DIV_1KHZ) begin
                cnt_1khz <= 14'd0;
                clk_1khz <= ~clk_1khz;
            end else begin
                cnt_1khz <= cnt_1khz + 1'b1;
            end
        end
    end

    // 800Hz clock generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_800hz <= 15'd0;
            clk_800hz <= 1'b0;
        end else begin
            if (cnt_800hz >= DIV_800HZ) begin
                cnt_800hz <= 15'd0;
                clk_800hz <= ~clk_800hz;
            end else begin
                cnt_800hz <= cnt_800hz + 1'b1;
            end
        end
    end

endmodule

