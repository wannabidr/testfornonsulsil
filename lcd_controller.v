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
    localparam WRITE_LINE1  = 4'd9;
    localparam WRITE_LINE2  = 4'd10;
    localparam WRITE_CHAR   = 4'd11;
    localparam WAIT_DONE    = 4'd12;

    reg [3:0] state, next_state;
    reg [3:0] char_count;
    reg [7:0] current_char;
    reg [31:0] delay_counter;
    reg [31:0] delay_target;
    
    // 클럭 분주기 (1MHz LCD 클럭 생성, 100MHz -> 1MHz)
    reg [6:0] clk_div;
    reg lcd_clk;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= 0;
            lcd_clk <= 0;
        end else begin
            if (clk_div == 49) begin
                clk_div <= 0;
                lcd_clk <= ~lcd_clk;
            end else begin
                clk_div <= clk_div + 1;
            end
        end
    end
    
    // 타이밍 생성 (1MHz 클럭 기준)
    localparam DELAY_15MS   = 32'd15000;  // 15ms
    localparam DELAY_5MS    = 32'd5000;   // 5ms
    localparam DELAY_2MS    = 32'd2000;   // 2ms
    localparam DELAY_100US  = 32'd100;    // 100us
    localparam DELAY_50US   = 32'd50;     // 50us
    
    // 상태 전이
    always @(posedge lcd_clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Enable 신호 생성 (4클럭 사이클)
    reg [2:0] enable_count;
    reg enable_pulse;
    
    always @(posedge lcd_clk or posedge reset) begin
        if (reset) begin
            enable_count <= 0;
            enable_pulse <= 0;
        end else begin
            if (state == WRITE_CHAR) begin
                if (enable_count < 7) begin
                    enable_count <= enable_count + 1;
                    if (enable_count >= 1 && enable_count <= 4)
                        enable_pulse <= 1;
                    else
                        enable_pulse <= 0;
                end else begin
                    enable_count <= 0;
                    enable_pulse <= 0;
                end
            end else begin
                enable_count <= 0;
                enable_pulse <= 0;
            end
        end
    end
    
    // FSM 로직
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                next_state = INIT_WAIT;
            end
            
            INIT_WAIT: begin
                if (delay_counter >= delay_target)
                    next_state = INIT_FUNC1;
            end
            
            INIT_FUNC1: begin
                if (delay_counter >= delay_target)
                    next_state = INIT_FUNC2;
            end
            
            INIT_FUNC2: begin
                if (delay_counter >= delay_target)
                    next_state = INIT_FUNC3;
            end
            
            INIT_FUNC3: begin
                if (delay_counter >= delay_target)
                    next_state = INIT_DISPLAY;
            end
            
            INIT_DISPLAY: begin
                if (delay_counter >= delay_target)
                    next_state = INIT_CLEAR;
            end
            
            INIT_CLEAR: begin
                if (delay_counter >= delay_target)
                    next_state = INIT_ENTRY;
            end
            
            INIT_ENTRY: begin
                if (delay_counter >= delay_target)
                    next_state = READY_STATE;
            end
            
            READY_STATE: begin
                if (refresh)
                    next_state = WRITE_LINE1;
            end
            
            WRITE_LINE1: begin
                if (char_count < 16)
                    next_state = WRITE_CHAR;
                else
                    next_state = WRITE_LINE2;
            end
            
            WRITE_LINE2: begin
                if (char_count < 16)
                    next_state = WRITE_CHAR;
                else
                    next_state = READY_STATE;
            end
            
            WRITE_CHAR: begin
                if (enable_count >= 7)
                    next_state = WAIT_DONE;
            end
            
            WAIT_DONE: begin
                if (delay_counter >= delay_target) begin
                    if (state == WRITE_LINE1)
                        next_state = WRITE_LINE1;
                    else if (state == WRITE_LINE2)
                        next_state = WRITE_LINE2;
                end
            end
        endcase
    end
    
    // 출력 로직
    always @(posedge lcd_clk or posedge reset) begin
        if (reset) begin
            lcd_rs <= 0;
            lcd_rw <= 0;
            lcd_e <= 0;
            lcd_data <= 8'h00;
            ready <= 0;
            delay_counter <= 0;
            delay_target <= 0;
            char_count <= 0;
            current_char <= 0;
        end else begin
            lcd_e <= enable_pulse;
            lcd_rw <= 0; // 항상 쓰기 모드
            
            case (state)
                IDLE: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h00;
                    ready <= 0;
                    delay_counter <= 0;
                    delay_target <= DELAY_15MS;
                end
                
                INIT_WAIT: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h00;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
                
                INIT_FUNC1: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h38; // Function Set: 8-bit, 2-line, 5x8 font
                    delay_target <= DELAY_5MS;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
                
                INIT_FUNC2: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h38;
                    delay_target <= DELAY_100US;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
                
                INIT_FUNC3: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h38;
                    delay_target <= DELAY_100US;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
                
                INIT_DISPLAY: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h0C; // Display ON, Cursor OFF, Blink OFF
                    delay_target <= DELAY_2MS;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
                
                INIT_CLEAR: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h01; // Clear Display
                    delay_target <= DELAY_2MS;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
                
                INIT_ENTRY: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h06; // Entry Mode: Increment, No Shift
                    delay_target <= DELAY_2MS;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else begin
                        delay_counter <= 0;
                        ready <= 1;
                    end
                end
                
                READY_STATE: begin
                    lcd_rs <= 0;
                    lcd_data <= 8'h00;
                    char_count <= 0;
                end
                
                WRITE_LINE1: begin
                    if (char_count == 0) begin
                        lcd_rs <= 0;
                        lcd_data <= 8'h80; // DDRAM 주소 0x00 (첫 번째 줄)
                        char_count <= char_count + 1;
                    end else if (char_count <= 16) begin
                        lcd_rs <= 1;
                        lcd_data <= line1[127 - (char_count-1)*8 -: 8];
                        char_count <= char_count + 1;
                    end
                end
                
                WRITE_LINE2: begin
                    if (char_count == 0) begin
                        lcd_rs <= 0;
                        lcd_data <= 8'hC0; // DDRAM 주소 0x40 (두 번째 줄)
                        char_count <= char_count + 1;
                    end else if (char_count <= 16) begin
                        lcd_rs <= 1;
                        lcd_data <= line2[127 - (char_count-1)*8 -: 8];
                        char_count <= char_count + 1;
                    end
                end
                
                WRITE_CHAR: begin
                    // Enable 펄스 생성
                end
                
                WAIT_DONE: begin
                    delay_target <= DELAY_50US;
                    if (delay_counter < delay_target)
                        delay_counter <= delay_counter + 1;
                    else
                        delay_counter <= 0;
                end
            endcase
        end
    end

endmodule
