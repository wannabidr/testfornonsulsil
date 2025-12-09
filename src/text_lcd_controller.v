// Text LCD Controller for Morse Translator
// 1MHz clock version with dynamic character input
// 16x2 LCD, supports dual row display with individual transfer

module text_lcd_controller (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] char_in,
    input  wire       char_valid,
    input  wire       char_to_row2,
    input  wire       transfer_to_row1,
    input  wire [7:0] transfer_char,
    input  wire       clear,
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
    parameter S_SET_ROW1    = 4'd4;
    parameter S_WRITE_ROW1  = 4'd5;
    parameter S_SET_ROW2    = 4'd6;
    parameter S_WRITE_ROW2  = 4'd7;
    parameter S_WAIT_INPUT  = 4'd8;
    parameter S_REFRESH     = 4'd9;

    reg [3:0] state;
    reg [4:0] lcd_col_cnt;
    
    localparam DELAY_CYCLES = 14'd2000;
    reg [13:0] delay_cnt;
    
    // Character buffers
    reg [7:0] row1_buf [0:15];
    reg [7:0] row2_buf [0:15];
    reg [3:0] row1_count;
    reg [3:0] row2_count;
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
    
    // Edge detection for transfer
    reg transfer_prev;
    wire transfer_rise;
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            transfer_prev <= 1'b0;
        else
            transfer_prev <= transfer_to_row1;
    end
    assign transfer_rise = transfer_to_row1 & ~transfer_prev;
    
    // Edge detection for clear
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
            for (i = 0; i < 16; i = i + 1) begin
                row1_buf[i] <= 8'h20;
                row2_buf[i] <= 8'h20;
            end
            row1_count <= 4'd0;
            row2_count <= 4'd0;
            buffer_updated <= 1'b1;
        end else if (transfer_rise) begin
            // Add transfer_char to row1 (append)
            if (row1_count < 16) begin
                row1_buf[row1_count] <= transfer_char;
                row1_count <= row1_count + 1;
            end else begin
                // Row1 full: shift left
                for (i = 0; i < 15; i = i + 1)
                    row1_buf[i] <= row1_buf[i + 1];
                row1_buf[15] <= transfer_char;
            end
            
            // Remove first char from row2 (shift left)
            if (row2_count > 0) begin
                for (i = 0; i < 15; i = i + 1)
                    row2_buf[i] <= row2_buf[i + 1];
                row2_buf[15] <= 8'h20;
                row2_count <= row2_count - 1;
            end
            
            buffer_updated <= 1'b1;
        end else if (char_valid_rise) begin
            if (char_to_row2) begin
                // Input to row2
                if (row2_count < 16) begin
                    row2_buf[row2_count] <= char_in;
                    row2_count <= row2_count + 1;
                end else begin
                    for (i = 0; i < 15; i = i + 1)
                        row2_buf[i] <= row2_buf[i + 1];
                    row2_buf[15] <= char_in;
                end
            end else begin
                // Input to row1
                if (row1_count < 16) begin
                    row1_buf[row1_count] <= char_in;
                    row1_count <= row1_count + 1;
                end else begin
                    for (i = 0; i < 15; i = i + 1)
                        row1_buf[i] <= row1_buf[i + 1];
                    row1_buf[15] <= char_in;
                end
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
                            lcd_data <= 8'h38;
                            state <= S_INIT_1;
                        end
                        
                        S_INIT_1: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h0C;
                            state <= S_INIT_2;
                        end
                        
                        S_INIT_2: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h01;
                            state <= S_INIT_3;
                        end
                        
                        S_INIT_3: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h06;
                            state <= S_SET_ROW1;
                        end
                        
                        S_SET_ROW1: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'h80;
                            lcd_col_cnt <= 5'd0;
                            state <= S_WRITE_ROW1;
                        end
                        
                        S_WRITE_ROW1: begin
                            if (lcd_col_cnt < 16) begin
                                lcd_rs <= 1'b1;
                                lcd_data <= row1_buf[lcd_col_cnt];
                                lcd_col_cnt <= lcd_col_cnt + 1;
                            end else begin
                                state <= S_SET_ROW2;
                            end
                        end
                        
                        S_SET_ROW2: begin
                            lcd_rs <= 1'b0;
                            lcd_data <= 8'hC0;
                            lcd_col_cnt <= 5'd0;
                            state <= S_WRITE_ROW2;
                        end
                        
                        S_WRITE_ROW2: begin
                            if (lcd_col_cnt < 16) begin
                                lcd_rs <= 1'b1;
                                lcd_data <= row2_buf[lcd_col_cnt];
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
                            lcd_data <= 8'h80;
                            lcd_col_cnt <= 5'd0;
                            state <= S_WRITE_ROW1;
                        end
                    endcase
                end
            end else begin
                lcd_en <= 1'b0;
                if (buffer_updated) begin
                    state <= S_REFRESH;
                    delay_cnt <= 14'd0;
                end
            end
        end
    end

endmodule
