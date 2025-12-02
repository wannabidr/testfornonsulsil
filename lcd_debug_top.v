`timescale 1ns / 1ps

module lcd_debug_top(
    input wire clk,           // 100MHz 시스템 클럭
    input wire reset_btn,     // 리셋 버튼 (Active Low)
    output wire lcd_rs,       // LCD Register Select
    output wire lcd_rw,       // LCD Read/Write
    output wire lcd_e,        // LCD Enable
    output wire [7:0] lcd_data,// LCD Data Bus
    output wire [3:0] led     // 디버그용 LED
);

    // 리셋 신호 처리 (Active High로 변환)
    wire reset;
    assign reset = ~reset_btn;
    
    // 상태 정의 - 단순화된 초기화 시퀀스
    localparam POWER_ON     = 4'd0;
    localparam WAIT_15MS    = 4'd1;
    localparam FUNC_SET1    = 4'd2;
    localparam WAIT_5MS     = 4'd3;
    localparam FUNC_SET2    = 4'd4;
    localparam WAIT_1MS     = 4'd5;
    localparam FUNC_SET3    = 4'd6;
    localparam DISP_ON      = 4'd7;
    localparam CLR_DISP     = 4'd8;
    localparam ENTRY_MODE   = 4'd9;
    localparam WRITE_DATA   = 4'd10;
    localparam DONE         = 4'd11;
    
    reg [3:0] state;
    reg [31:0] delay_cnt;
    reg [3:0] led_reg;
    
    // LCD 신호
    reg lcd_rs_reg;
    reg lcd_e_reg;
    reg [7:0] lcd_data_reg;
    
    assign lcd_rs = lcd_rs_reg;
    assign lcd_rw = 0;  // 항상 쓰기 모드
    assign lcd_e = lcd_e_reg;
    assign lcd_data = lcd_data_reg;
    assign led = led_reg;
    
    // 매우 느린 클럭 생성 (약 10Hz, 100ms 주기)
    reg [22:0] slow_clk_cnt;
    reg slow_clk;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            slow_clk_cnt <= 0;
            slow_clk <= 0;
        end else begin
            if (slow_clk_cnt >= 5_000_000) begin  // 50ms
                slow_clk_cnt <= 0;
                slow_clk <= ~slow_clk;
            end else begin
                slow_clk_cnt <= slow_clk_cnt + 1;
            end
        end
    end
    
    // 메인 FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= POWER_ON;
            delay_cnt <= 0;
            lcd_rs_reg <= 0;
            lcd_e_reg <= 0;
            lcd_data_reg <= 8'h00;
            led_reg <= 4'b0000;
        end else begin
            case (state)
                POWER_ON: begin
                    lcd_rs_reg <= 0;
                    lcd_e_reg <= 0;
                    lcd_data_reg <= 8'h00;
                    led_reg <= 4'b0001;
                    delay_cnt <= 0;
                    state <= WAIT_15MS;
                end
                
                WAIT_15MS: begin
                    led_reg <= 4'b0001;
                    if (delay_cnt >= 32'd1_500_000) begin  // 15ms
                        delay_cnt <= 0;
                        state <= FUNC_SET1;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                FUNC_SET1: begin
                    led_reg <= 4'b0010;
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'h38;  // 8-bit, 2-line, 5x8
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd2000) begin
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= WAIT_5MS;
                    end
                end
                
                WAIT_5MS: begin
                    led_reg <= 4'b0010;
                    lcd_e_reg <= 0;
                    if (delay_cnt >= 32'd500_000) begin  // 5ms
                        delay_cnt <= 0;
                        state <= FUNC_SET2;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                FUNC_SET2: begin
                    led_reg <= 4'b0011;
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'h38;
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd2000) begin
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= WAIT_1MS;
                    end
                end
                
                WAIT_1MS: begin
                    led_reg <= 4'b0011;
                    lcd_e_reg <= 0;
                    if (delay_cnt >= 32'd100_000) begin  // 1ms
                        delay_cnt <= 0;
                        state <= FUNC_SET3;
                    end else begin
                        delay_cnt <= delay_cnt + 1;
                    end
                end
                
                FUNC_SET3: begin
                    led_reg <= 4'b0100;
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'h38;
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd2000) begin
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= DISP_ON;
                    end
                end
                
                DISP_ON: begin
                    led_reg <= 4'b0101;
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'h0C;  // Display ON, Cursor OFF
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd200_000) begin  // 2ms
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= CLR_DISP;
                    end
                end
                
                CLR_DISP: begin
                    led_reg <= 4'b0110;
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'h01;  // Clear Display
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd200_000) begin  // 2ms
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= ENTRY_MODE;
                    end
                end
                
                ENTRY_MODE: begin
                    led_reg <= 4'b0111;
                    lcd_rs_reg <= 0;
                    lcd_data_reg <= 8'h06;  // Entry Mode
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd200_000) begin  // 2ms
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    led_reg <= 4'b1000;
                    lcd_rs_reg <= 1;  // 데이터 모드
                    lcd_data_reg <= 8'h41;  // 'A'
                    
                    if (delay_cnt < 32'd1000) begin
                        lcd_e_reg <= 1;
                        delay_cnt <= delay_cnt + 1;
                    end else if (delay_cnt < 32'd100_000) begin
                        lcd_e_reg <= 0;
                        delay_cnt <= delay_cnt + 1;
                    end else begin
                        delay_cnt <= 0;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    led_reg <= 4'b1111;  // 모든 LED ON = 성공
                    lcd_e_reg <= 0;
                end
                
                default: begin
                    state <= POWER_ON;
                end
            endcase
        end
    end

endmodule
