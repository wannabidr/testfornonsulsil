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
            
            // Line 1: "Morse Translator"
            line1[127:120] <= 8'h4D;  // M
            line1[119:112] <= 8'h6F;  // o
            line1[111:104] <= 8'h72;  // r
            line1[103:96]  <= 8'h73;  // s
            line1[95:88]   <= 8'h65;  // e
            line1[87:80]   <= 8'h20;  // space
            line1[79:72]   <= 8'h54;  // T
            line1[71:64]   <= 8'h72;  // r
            line1[63:56]   <= 8'h61;  // a
            line1[55:48]   <= 8'h6E;  // n
            line1[47:40]   <= 8'h73;  // s
            line1[39:32]   <= 8'h6C;  // l
            line1[31:24]   <= 8'h61;  // a
            line1[23:16]   <= 8'h74;  // t
            line1[15:8]    <= 8'h6F;  // o
            line1[7:0]     <= 8'h72;  // r
            
            // Line 2: "  LCD Test OK  "
            line2[127:120] <= 8'h20;  // space
            line2[119:112] <= 8'h20;  // space
            line2[111:104] <= 8'h4C;  // L
            line2[103:96]  <= 8'h43;  // C
            line2[95:88]   <= 8'h44;  // D
            line2[87:80]   <= 8'h20;  // space
            line2[79:72]   <= 8'h54;  // T
            line2[71:64]   <= 8'h65;  // e
            line2[63:56]   <= 8'h73;  // s
            line2[55:48]   <= 8'h74;  // t
            line2[47:40]   <= 8'h20;  // space
            line2[39:32]   <= 8'h4F;  // O
            line2[31:24]   <= 8'h4B;  // K
            line2[23:16]   <= 8'h20;  // space
            line2[15:8]    <= 8'h20;  // space
            line2[7:0]     <= 8'h20;  // space
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
                    if (counter < 10) begin
                        counter <= counter + 1;
                        refresh <= 1;
                    end else begin
                        refresh <= 0;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    refresh <= 0;
                end
                
                default: begin
                    state <= INIT;
                end
            endcase
        end
    end

endmodule
