`timescale 1ns / 1ps

module lcd_controller(
    input wire clk,           // 100MHz 시스템 클럭
    input wire reset,         // 리셋 신호
    input wire [127:0] line1, // LCD 첫 번째 줄 (16글자 x 8비트)
    input wire [127:0] line2, // LCD 두 번째 줄 (16글자 x 8비트)
    input wire refresh,       // LCD 새로고침 신호
    output reg lcd_rs,        // LCD Register Select
    output reg lcd_rw,        // LCD Read/Write
    output reg lcd_e,         // LCD Enable
    output reg [7:0] lcd_data,// LCD Data Bus
    output reg ready          // LCD 준비 완료 신호
);

    // 상태 정의
    localparam IDLE         = 4'd0;
    localparam INIT_WAIT    = 4'd1;
    localparam INIT_FUNC1   = 4'd2;
    localparam INIT_FUNC2   = 4'd3;
    localparam INIT_FUNC3   = 4'd4;
    localparam INIT_DISPLAY = 4'd5;
    localparam INIT_CLEAR   = 4'd6;
    localparam INIT_ENTRY   = 4'd7;
    localparam READY_STATE  = 4'd8;
    localparam SET_ADDR1    = 4'd9;
    localparam WRITE_LINE1  = 4'd10;
    localparam SET_ADDR2    = 4'd11;
    localparam WRITE_LINE2  = 4'd12;
    localparam WRITE_WAIT   = 4'd13;

    reg [3:0] state;
    reg [4:0] char_count;
    reg [31:0] delay_counter;
    reg writing_line2;
    
    // 클럭 분주기 (약 1kHz LCD 클럭 생성, 100MHz -> 1kHz)
    // 1kHz = 1ms 주기
    reg [16:0] clk_div;
    reg lcd_clk_en;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= 0;
            lcd_clk_en <= 0;
        end else begin
            if (clk_div == 99999) begin  // 100MHz / 100000 = 1kHz
                clk_div <= 0;
                lcd_clk_en <= 1;
            end else begin
                clk_div <= clk_div + 1;
                lcd_clk_en <= 0;
            end
        end
    end
    
    // 타이밍 생성 (1kHz 클럭 기준, 1 tick = 1ms)
    localparam DELAY_15MS   = 32'd15;     // 15ms
    localparam DELAY_5MS    = 32'd5;      // 5ms
    localparam DELAY_2MS    = 32'd2;      // 2ms
    localparam DELAY_1MS    = 32'd1;      // 1ms
    
    // Enable 펄스 생성 (마이크로초 단위)
    reg [7:0] enable_counter;
    
    // 메인 FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            lcd_rs <= 0;
            lcd_rw <= 0;
            lcd_e <= 0;
            lcd_data <= 8'h00;
            ready <= 0;
            delay_counter <= 0;
            char_count <= 0;
            writing_line2 <= 0;
            enable_counter <= 0;
        end else if (lcd_clk_en) begin
            // 기본값
            lcd_rw <= 0;  // 항상 쓰기 모드
            
            case (state)
                IDLE: begin
                    lcd_rs <= 0;
                    lcd_e <= 0;
                    lcd_data <= 8'h00;
                    ready <= 0;
                    delay_counter <= 0;
                    state <= INIT_WAIT;
                end
                
                INIT_WAIT: begin
                    if (delay_counter >= DELAY_15MS) begin
                        state <= INIT_FUNC1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                INIT_FUNC1: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h38;  // Function Set: 8-bit, 2-line, 5x8
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_5MS) begin
                        lcd_e <= 0;
                        state <= INIT_FUNC2;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                INIT_FUNC2: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h38;
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_1MS) begin
                        lcd_e <= 0;
                        state <= INIT_FUNC3;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                INIT_FUNC3: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h38;
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_1MS) begin
                        lcd_e <= 0;
                        state <= INIT_DISPLAY;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                INIT_DISPLAY: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h0C;  // Display ON, Cursor OFF
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_2MS) begin
                        lcd_e <= 0;
                        state <= INIT_CLEAR;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                INIT_CLEAR: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h01;  // Clear Display
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_2MS) begin
                        lcd_e <= 0;
                        state <= INIT_ENTRY;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                INIT_ENTRY: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h06;  // Entry Mode: Increment
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_2MS) begin
                        lcd_e <= 0;
                        ready <= 1;
                        state <= READY_STATE;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                READY_STATE: begin
                    lcd_e <= 0;
                    if (refresh) begin
                        state <= SET_ADDR1;
                        char_count <= 0;
                        writing_line2 <= 0;
                    end
                end
                
                SET_ADDR1: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h80;  // DDRAM 주소 0x00 (Line 1)
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_1MS) begin
                        lcd_e <= 0;
                        state <= WRITE_LINE1;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                WRITE_LINE1: begin
                    if (char_count < 16) begin
                        lcd_rs <= 1;
                        // 비트 슬라이싱: MSB부터 추출
                        lcd_data <= line1[(15-char_count)*8 +: 8];
                        lcd_e <= 1;
                        if (delay_counter >= DELAY_1MS) begin
                            lcd_e <= 0;
                            char_count <= char_count + 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin
                        state <= SET_ADDR2;
                        char_count <= 0;
                        delay_counter <= 0;
                    end
                end
                
                SET_ADDR2: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'hC0;  // DDRAM 주소 0x40 (Line 2)
                    lcd_e <= 1;
                    if (delay_counter >= DELAY_1MS) begin
                        lcd_e <= 0;
                        state <= WRITE_LINE2;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                WRITE_LINE2: begin
                    if (char_count < 16) begin
                        lcd_rs <= 1;
                        lcd_data <= line2[(15-char_count)*8 +: 8];
                        lcd_e <= 1;
                        if (delay_counter >= DELAY_1MS) begin
                            lcd_e <= 0;
                            char_count <= char_count + 1;
                            delay_counter <= 0;
                        end else begin
                            delay_counter <= delay_counter + 1;
                        end
                    end else begin
                        state <= WRITE_WAIT;
                        delay_counter <= 0;
                    end
                end
                
                WRITE_WAIT: begin
                    lcd_e <= 0;
                    if (delay_counter >= DELAY_2MS) begin
                        state <= READY_STATE;
                        delay_counter <= 0;
                    end else begin
                        delay_counter <= delay_counter + 1;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
