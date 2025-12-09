// Text LCD Controller for Morse Translator
// 1MHz clock version with dynamic character input
// 16x2 LCD, Row 1: Input characters (left to right)

module text_lcd_controller (
    input  wire       clk,         // 1MHz
    input  wire       rst,
    input  wire [7:0] char_in,     // Input character (ASCII)
    input  wire       char_valid,  // Character valid pulse
    input  wire       clear,       // Clear buffer
    output reg        lcd_rs,
    output reg        lcd_rw,
    output reg        lcd_en,
    output reg  [7:0] lcd_data
);

    // FSM states
    parameter S_INIT_0      = 4'd0;
    parameter S_INIT_1      = 4'd1;
    parameter S_INIT_2      = 4'd2;
    parameter S_INIT_3      = 4'd3;
    parameter S_SET_ADDR    = 4'd4;
    parameter S_WRITE_DATA  = 4'd5;
    parameter S_WAIT_INPUT  = 4'd6;
    parameter S_REFRESH     = 4'd7;

    reg [3:0] state;
    reg [4:0] lcd_col_cnt;
    
    // 1MHz: 2ms delay = 2000 cycles
    localparam DELAY_CYCLES = 14'd2000;
    reg [13:0] delay_cnt;
    
    // Character buffer (16 characters for row 1)
    reg [7:0] char_buf [0:15];
    reg [3:0] char_count;
    integer i;
    
    // Edge detection for char_valid
    reg char_valid_prev;
    wire char_valid_rise;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            char_valid_prev <= 1'b0;
        else
            char_valid_prev <= char_valid;
    end
    assign char_valid_rise = char_valid & ~char_valid_prev;
    
    // Clear edge detection
    reg clear_prev;
    wire clear_rise;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            clear_prev <= 1'b0;
        else
            clear_prev <= clear;
    end
    assign clear_rise = clear & ~clear_prev;
    
    // Buffer management
    reg buffer_updated;
    
    always @(posedge clk or posedge rst) begin
        if (rst || clear_rise) begin
            for (i = 0; i < 16; i = i + 1)
                char_buf[i] <= 8'h20;  // Space
            char_count <= 4'd0;
            buffer_updated <= 1'b1;
        end else if (char_valid_rise) begin
            if (char_count < 16) begin
                char_buf[char_count] <= char_in;
                char_count <= char_count + 1;
            end else begin
                // Buffer full: shift left, add new at end
                for (i = 0; i < 15; i = i + 1)
                    char_buf[i] <= char_buf[i + 1];
                char_buf[15] <= char_in;
            end
            buffer_updated <= 1'b1;
        end else if (state == S_WAIT_INPUT) begin
            buffer_updated <= 1'b0;
        end
    end

    // Main LCD FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_INIT_0;
            lcd_rs <= 1'b0;
            lcd_rw <= 1'b0;
            lcd_en <= 1'b0;
            lcd_data <= 8'h00;
            lcd_col_cnt <= 5'd0;
            delay_cnt <= 14'd0;
        end else begin
            // Enable pulse at middle of delay (1ms point, 50us width)
            if (state != S_WAIT_INPUT) begin
                if ((delay_cnt >= 14'd1000) && (delay_cnt < 14'd1050))
                    lcd_en <= 1'b1;
                else
                    lcd_en <= 1'b0;
                    
                if (delay_cnt < DELAY_CYCLES) begin
                    delay_cnt <= delay_cnt + 1;
                end else begin
                    delay_cnt <= 14'd0;
                    
                    case (state)
                        S_INIT_0: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h38;  // Function set: 8-bit, 2 lines
                            state <= S_INIT_1;
                        end
                        
                        S_INIT_1: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h0C;  // Display ON, cursor OFF
                            state <= S_INIT_2;
                        end
                        
                        S_INIT_2: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h01;  // Clear display
                            state <= S_INIT_3;
                        end
                        
                        S_INIT_3: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h06;  // Entry mode: increment
                            state <= S_SET_ADDR;
                        end
                        
                        S_SET_ADDR: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h80;  // Set DDRAM address: Row 1, Col 0
                            lcd_col_cnt <= 5'd0;
                            state <= S_WRITE_DATA;
                        end
                        
                        S_WRITE_DATA: begin
                            if (lcd_col_cnt < 16) begin
                                lcd_rs <= 1'b1;
                                lcd_data <= char_buf[lcd_col_cnt];
                                lcd_col_cnt <= lcd_col_cnt + 1;
                            end else begin
                                state <= S_WAIT_INPUT;
                            end
                        end
                        
                        S_WAIT_INPUT: begin
                            lcd_en <= 1'b0;
                        end
                        
                        S_REFRESH: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h80;  // Set DDRAM address: Row 1, Col 0
                            lcd_col_cnt <= 5'd0;
                            state <= S_WRITE_DATA;
                        end
                    endcase
                end
            end else begin
                // S_WAIT_INPUT: wait for new input
                lcd_en <= 1'b0;
                if (buffer_updated) begin
                    state <= S_REFRESH;
                    delay_cnt <= 14'd0;
                end
            end
        end
    end

endmodule
