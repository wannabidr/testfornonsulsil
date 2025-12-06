// Piezo Buzzer Driver for Morse Code
// Dot = 1 unit, Dash = 3 units, Gap = 1 unit

module buzzer_driver (
    input  wire       clk,
    input  wire       clk_5hz,
    input  wire       rst,
    input  wire       start,
    input  wire [4:0] morse_code,   // Up to 5 symbols
    input  wire [2:0] morse_len,    // Length (1-5)
    output reg        buzzer_out,
    output reg        busy
);

    // States
    localparam IDLE     = 3'd0;
    localparam SOUND_ON = 3'd1;
    localparam SOUND_OFF= 3'd2;
    localparam GAP      = 3'd3;
    localparam DONE     = 3'd4;

    reg [2:0] state;
    reg [2:0] symbol_idx;
    reg [3:0] unit_cnt;
    reg [3:0] unit_target;
    reg       current_symbol;
    reg       clk_5hz_prev;
    wire      clk_5hz_rise;

    // Buzzer tone generation (800Hz from 1MHz)
    reg [9:0] tone_cnt;
    reg       tone_out;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tone_cnt <= 10'd0;
            tone_out <= 1'b0;
        end else begin
            if (tone_cnt >= 10'd624) begin
                tone_cnt <= 10'd0;
                tone_out <= ~tone_out;
            end else begin
                tone_cnt <= tone_cnt + 1'b1;
            end
        end
    end

    // 5Hz rising edge detect
    always @(posedge clk or posedge rst) begin
        if (rst)
            clk_5hz_prev <= 1'b0;
        else
            clk_5hz_prev <= clk_5hz;
    end
    assign clk_5hz_rise = clk_5hz & ~clk_5hz_prev;

    // FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            symbol_idx <= 3'd0;
            unit_cnt <= 4'd0;
            unit_target <= 4'd0;
            current_symbol <= 1'b0;
            busy <= 1'b0;
            buzzer_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    buzzer_out <= 1'b0;
                    if (start && morse_len > 0) begin
                        state <= SOUND_ON;
                        symbol_idx <= 3'd0;
                        unit_cnt <= 4'd0;
                        current_symbol <= morse_code[4];
                        unit_target <= morse_code[4] ? 4'd3 : 4'd1;
                        busy <= 1'b1;
                    end else begin
                        busy <= 1'b0;
                    end
                end

                SOUND_ON: begin
                    buzzer_out <= tone_out;
                    if (clk_5hz_rise) begin
                        if (unit_cnt >= unit_target - 1) begin
                            state <= GAP;
                            unit_cnt <= 4'd0;
                            buzzer_out <= 1'b0;
                        end else begin
                            unit_cnt <= unit_cnt + 1'b1;
                        end
                    end
                end

                GAP: begin
                    buzzer_out <= 1'b0;
                    if (clk_5hz_rise) begin
                        if (symbol_idx >= morse_len - 1) begin
                            state <= DONE;
                        end else begin
                            symbol_idx <= symbol_idx + 1'b1;
                            current_symbol <= morse_code[4 - symbol_idx - 1];
                            unit_target <= morse_code[4 - symbol_idx - 1] ? 4'd3 : 4'd1;
                            unit_cnt <= 4'd0;
                            state <= SOUND_ON;
                        end
                    end
                end

                DONE: begin
                    buzzer_out <= 1'b0;
                    busy <= 1'b0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
