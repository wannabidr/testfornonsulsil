//==============================================================================
// Piezo Buzzer Driver Module
// Plays morse code pattern through buzzer with proper timing
// Dot: 200ms, Dash: 600ms, Gap: 200ms
//==============================================================================
module buzzer_driver (
    input  wire       clk,           // System clock (25MHz)
    input  wire       rst_n,         // Active low reset
    input  wire       clk_800hz,     // 800Hz tone clock
    input  wire       start,         // Start playing morse code
    input  wire [2:0] morse_len,     // Number of symbols
    input  wire [4:0] morse_pattern, // Morse pattern (LSB first)
    output reg        buzzer_out,    // Buzzer PWM output
    output reg        busy           // Playing in progress
);

    // Timing constants at 25MHz
    // Dot: 200ms = 5,000,000 cycles
    // Dash: 600ms = 15,000,000 cycles
    // Gap: 200ms = 5,000,000 cycles
    localparam DOT_TIME  = 5000000 - 1;
    localparam DASH_TIME = 15000000 - 1;
    localparam GAP_TIME  = 5000000 - 1;

    // FSM states
    localparam S_IDLE       = 3'd0;
    localparam S_LOAD       = 3'd1;
    localparam S_PLAY       = 3'd2;
    localparam S_GAP        = 3'd3;
    localparam S_NEXT       = 3'd4;
    localparam S_DONE       = 3'd5;

    reg [2:0]  state;
    reg [23:0] timer;
    reg [2:0]  symbol_cnt;
    reg [4:0]  pattern_reg;
    reg [2:0]  len_reg;
    reg        current_symbol;
    reg        tone_enable;

    // Buzzer output: PWM tone when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            buzzer_out <= 1'b0;
        else
            buzzer_out <= tone_enable & clk_800hz;
    end

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            timer        <= 24'd0;
            symbol_cnt   <= 3'd0;
            pattern_reg  <= 5'd0;
            len_reg      <= 3'd0;
            current_symbol <= 1'b0;
            tone_enable  <= 1'b0;
            busy         <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    tone_enable <= 1'b0;
                    busy        <= 1'b0;
                    if (start) begin
                        state <= S_LOAD;
                    end
                end

                S_LOAD: begin
                    pattern_reg  <= morse_pattern;
                    len_reg      <= morse_len;
                    symbol_cnt   <= 3'd0;
                    busy         <= 1'b1;
                    state        <= S_PLAY;
                    timer        <= 24'd0;
                    current_symbol <= morse_pattern[0];
                    tone_enable  <= 1'b1;
                end

                S_PLAY: begin
                    tone_enable <= 1'b1;
                    // Determine timing based on dot(0) or dash(1)
                    if (current_symbol == 1'b0) begin
                        // Dot timing
                        if (timer >= DOT_TIME) begin
                            timer       <= 24'd0;
                            tone_enable <= 1'b0;
                            state       <= S_GAP;
                        end else begin
                            timer <= timer + 1'b1;
                        end
                    end else begin
                        // Dash timing
                        if (timer >= DASH_TIME) begin
                            timer       <= 24'd0;
                            tone_enable <= 1'b0;
                            state       <= S_GAP;
                        end else begin
                            timer <= timer + 1'b1;
                        end
                    end
                end

                S_GAP: begin
                    tone_enable <= 1'b0;
                    if (timer >= GAP_TIME) begin
                        timer <= 24'd0;
                        state <= S_NEXT;
                    end else begin
                        timer <= timer + 1'b1;
                    end
                end

                S_NEXT: begin
                    symbol_cnt <= symbol_cnt + 1'b1;
                    if (symbol_cnt + 1'b1 >= len_reg) begin
                        state <= S_DONE;
                    end else begin
                        // Shift to next symbol
                        pattern_reg    <= pattern_reg >> 1;
                        current_symbol <= pattern_reg[1];
                        tone_enable    <= 1'b1;
                        state          <= S_PLAY;
                    end
                end

                S_DONE: begin
                    tone_enable <= 1'b0;
                    busy        <= 1'b0;
                    state       <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

