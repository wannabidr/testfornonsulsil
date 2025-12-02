`timescale 1ns / 1ps

module lcd_test_top(
    input wire clk,           // 100MHz 시스템 클럭
    input wire reset_btn,     // 리셋 버튼 (Active Low)
    output wire lcd_rs,       // LCD Register Select
    output wire lcd_rw,       // LCD Read/Write
    output wire lcd_e,        // LCD Enable
    output wire [7:0] lcd_data// LCD Data Bus
);

    // 리셋 신호 처리 (Active High로 변환)
    wire reset;
    assign reset = ~reset_btn;
    
    // LCD 제어 신호
    reg [127:0] line1;
    reg [127:0] line2;
    reg refresh;
    wire ready;
    
    // LCD 컨트롤러 인스턴스
    lcd_controller lcd_ctrl (
        .clk(clk),
        .reset(reset),
        .line1(line1),
        .line2(line2),
        .refresh(refresh),
        .lcd_rs(lcd_rs),
        .lcd_rw(lcd_rw),
        .lcd_e(lcd_e),
        .lcd_data(lcd_data),
        .ready(ready)
    );
    
    // 상태 머신
    localparam INIT = 2'd0;
    localparam DISPLAY = 2'd1;
    localparam DONE = 2'd2;
    
    reg [1:0] state;
    reg [31:0] counter;
    
    // 테스트 메시지 설정
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT;
            counter <= 0;
            refresh <= 0;
            // 초기 메시지 설정
            // Line 1: "Morse Translator"
            line1 <= {"M", "o", "r", "s", "e", " ", "T", "r", 
                      "a", "n", "s", "l", "a", "t", "o", "r"};
            // Line 2: "  LCD Test OK  "
            line2 <= {" ", " ", "L", "C", "D", " ", "T", "e",
                      "s", "t", " ", "O", "K", " ", " ", " "};
        end else begin
            case (state)
                INIT: begin
                    if (ready) begin
                        state <= DISPLAY;
                        refresh <= 1;
                        counter <= 0;
                    end
                end
                
                DISPLAY: begin
                    refresh <= 0;
                    if (counter < 100_000_000) begin // 1초 대기
                        counter <= counter + 1;
                    end else begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    // LCD에 메시지 표시 완료
                end
            endcase
        end
    end

endmodule
