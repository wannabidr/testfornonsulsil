// Button Debouncer Module
// 20ms debounce with 1kHz clock

module debounce (
    input  wire clk_1khz,
    input  wire rst,
    input  wire btn_in,
    output reg  btn_out
);

    parameter DEBOUNCE_COUNT = 20;
    
    reg [4:0] counter;
    reg btn_sync1, btn_sync2;

    // Synchronizer
    always @(posedge clk_1khz or posedge rst) begin
        if (rst) begin
            btn_sync1 <= 1'b0;
            btn_sync2 <= 1'b0;
        end else begin
            btn_sync1 <= btn_in;
            btn_sync2 <= btn_sync1;
        end
    end

    // Debounce logic
    always @(posedge clk_1khz or posedge rst) begin
        if (rst) begin
            counter <= 5'd0;
            btn_out <= 1'b0;
        end else begin
            if (btn_sync2 != btn_out) begin
                if (counter >= DEBOUNCE_COUNT - 1) begin
                    btn_out <= btn_sync2;
                    counter <= 5'd0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end else begin
                counter <= 5'd0;
            end
        end
    end

endmodule
