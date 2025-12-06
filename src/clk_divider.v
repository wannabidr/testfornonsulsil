// Clock Divider Module
// Input: 1MHz clock
// Outputs: Various divided clocks

module clk_divider (
    input  wire clk,
    input  wire rst,
    output reg  clk_1khz,
    output reg  clk_500hz,
    output reg  clk_5hz
);

    reg [9:0]  cnt_1khz;
    reg [10:0] cnt_500hz;
    reg [16:0] cnt_5hz;

    // 1kHz generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_1khz <= 10'd0;
            clk_1khz <= 1'b0;
        end else begin
            if (cnt_1khz >= 10'd499) begin
                cnt_1khz <= 10'd0;
                clk_1khz <= ~clk_1khz;
            end else begin
                cnt_1khz <= cnt_1khz + 1'b1;
            end
        end
    end

    // 500Hz generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_500hz <= 11'd0;
            clk_500hz <= 1'b0;
        end else begin
            if (cnt_500hz >= 11'd999) begin
                cnt_500hz <= 11'd0;
                clk_500hz <= ~clk_500hz;
            end else begin
                cnt_500hz <= cnt_500hz + 1'b1;
            end
        end
    end

    // 5Hz generation (200ms unit for morse)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt_5hz <= 17'd0;
            clk_5hz <= 1'b0;
        end else begin
            if (cnt_5hz >= 17'd99999) begin
                cnt_5hz <= 17'd0;
                clk_5hz <= ~clk_5hz;
            end else begin
                cnt_5hz <= cnt_5hz + 1'b1;
            end
        end
    end

endmodule
