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
    localparam INIT        = 3'd0;
    localparam TEST_HEX    = 3'd1;
    localparam TEST_ALPHA  = 3'd2;
    localparam TEST_NUM    = 3'd3;
    localparam TEST_BITS   = 3'd4;
    localparam WAIT_NEXT   = 3'd5;
    
    reg [2:0] state;
    reg [31:0] counter;
    reg [2:0] test_phase;
    
    // 1초 타이머 (100MHz 클럭 기준)
    reg [26:0] timer_1sec;
    reg tick_1sec;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer_1sec <= 0;
            tick_1sec <= 0;
        end else begin
            if (timer_1sec >= 100_000_000 - 1) begin
                timer_1sec <= 0;
                tick_1sec <= 1;
            end else begin
                timer_1sec <= timer_1sec + 1;
                tick_1sec <= 0;
            end
        end
    end
    
    // 핀 연결 테스트 시퀀스
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INIT;
            counter <= 0;
            refresh <= 0;
            test_phase <= 0;
            line1 <= 0;
            line2 <= 0;
        end else begin
            case (state)
                INIT: begin
                    if (ready) begin
                        state <= TEST_HEX;
                        test_phase <= 0;
                        counter <= 0;
                    end
                end
                
                // 테스트 1: 16진수 패턴 (데이터 비트 테스트)
                TEST_HEX: begin
                    // Line 1: "0123456789ABCDEF"
                    line1[127:120] <= 8'h30;  // 0
                    line1[119:112] <= 8'h31;  // 1
                    line1[111:104] <= 8'h32;  // 2
                    line1[103:96]  <= 8'h33;  // 3
                    line1[95:88]   <= 8'h34;  // 4
                    line1[87:80]   <= 8'h35;  // 5
                    line1[79:72]   <= 8'h36;  // 6
                    line1[71:64]   <= 8'h37;  // 7
                    line1[63:56]   <= 8'h38;  // 8
                    line1[55:48]   <= 8'h39;  // 9
                    line1[47:40]   <= 8'h41;  // A
                    line1[39:32]   <= 8'h42;  // B
                    line1[31:24]   <= 8'h43;  // C
                    line1[23:16]   <= 8'h44;  // D
                    line1[15:8]    <= 8'h45;  // E
                    line1[7:0]     <= 8'h46;  // F
                    
                    // Line 2: "Data Bit Test  "
                    line2[127:120] <= 8'h44;  // D
                    line2[119:112] <= 8'h61;  // a
                    line2[111:104] <= 8'h74;  // t
                    line2[103:96]  <= 8'h61;  // a
                    line2[95:88]   <= 8'h20;  // space
                    line2[87:80]   <= 8'h42;  // B
                    line2[79:72]   <= 8'h69;  // i
                    line2[71:64]   <= 8'h74;  // t
                    line2[63:56]   <= 8'h20;  // space
                    line2[55:48]   <= 8'h54;  // T
                    line2[47:40]   <= 8'h65;  // e
                    line2[39:32]   <= 8'h73;  // s
                    line2[31:24]   <= 8'h74;  // t
                    line2[23:16]   <= 8'h20;  // space
                    line2[15:8]    <= 8'h20;  // space
                    line2[7:0]     <= 8'h20;  // space
                    
                    refresh <= 1;
                    state <= WAIT_NEXT;
                    counter <= 0;
                end
                
                // 테스트 2: 알파벳 (문자 표시 테스트)
                TEST_ALPHA: begin
                    // Line 1: "ABCDEFGHIJKLMNOP"
                    line1[127:120] <= 8'h41;  // A
                    line1[119:112] <= 8'h42;  // B
                    line1[111:104] <= 8'h43;  // C
                    line1[103:96]  <= 8'h44;  // D
                    line1[95:88]   <= 8'h45;  // E
                    line1[87:80]   <= 8'h46;  // F
                    line1[79:72]   <= 8'h47;  // G
                    line1[71:64]   <= 8'h48;  // H
                    line1[63:56]   <= 8'h49;  // I
                    line1[55:48]   <= 8'h4A;  // J
                    line1[47:40]   <= 8'h4B;  // K
                    line1[39:32]   <= 8'h4C;  // L
                    line1[31:24]   <= 8'h4D;  // M
                    line1[23:16]   <= 8'h4E;  // N
                    line1[15:8]    <= 8'h4F;  // O
                    line1[7:0]     <= 8'h50;  // P
                    
                    // Line 2: "QRSTUVWXYZ      "
                    line2[127:120] <= 8'h51;  // Q
                    line2[119:112] <= 8'h52;  // R
                    line2[111:104] <= 8'h53;  // S
                    line2[103:96]  <= 8'h54;  // T
                    line2[95:88]   <= 8'h55;  // U
                    line2[87:80]   <= 8'h56;  // V
                    line2[79:72]   <= 8'h57;  // W
                    line2[71:64]   <= 8'h58;  // X
                    line2[63:56]   <= 8'h59;  // Y
                    line2[55:48]   <= 8'h5A;  // Z
                    line2[47:40]   <= 8'h20;  // space
                    line2[39:32]   <= 8'h20;  // space
                    line2[31:24]   <= 8'h20;  // space
                    line2[23:16]   <= 8'h20;  // space
                    line2[15:8]    <= 8'h20;  // space
                    line2[7:0]     <= 8'h20;  // space
                    
                    refresh <= 1;
                    state <= WAIT_NEXT;
                    counter <= 0;
                end
                
                // 테스트 3: 숫자 패턴 (타이밍 테스트)
                TEST_NUM: begin
                    // Line 1: "0000 1111 2222  "
                    line1[127:120] <= 8'h30;  // 0
                    line1[119:112] <= 8'h30;  // 0
                    line1[111:104] <= 8'h30;  // 0
                    line1[103:96]  <= 8'h30;  // 0
                    line1[95:88]   <= 8'h20;  // space
                    line1[87:80]   <= 8'h31;  // 1
                    line1[79:72]   <= 8'h31;  // 1
                    line1[71:64]   <= 8'h31;  // 1
                    line1[63:56]   <= 8'h31;  // 1
                    line1[55:48]   <= 8'h20;  // space
                    line1[47:40]   <= 8'h32;  // 2
                    line1[39:32]   <= 8'h32;  // 2
                    line1[31:24]   <= 8'h32;  // 2
                    line1[23:16]   <= 8'h32;  // 2
                    line1[15:8]    <= 8'h20;  // space
                    line1[7:0]     <= 8'h20;  // space
                    
                    // Line 2: "3333 4444 5555  "
                    line2[127:120] <= 8'h33;  // 3
                    line2[119:112] <= 8'h33;  // 3
                    line2[111:104] <= 8'h33;  // 3
                    line2[103:96]  <= 8'h33;  // 3
                    line2[95:88]   <= 8'h20;  // space
                    line2[87:80]   <= 8'h34;  // 4
                    line2[79:72]   <= 8'h34;  // 4
                    line2[71:64]   <= 8'h34;  // 4
                    line2[63:56]   <= 8'h34;  // 4
                    line2[55:48]   <= 8'h20;  // space
                    line2[47:40]   <= 8'h35;  // 5
                    line2[39:32]   <= 8'h35;  // 5
                    line2[31:24]   <= 8'h35;  // 5
                    line2[23:16]   <= 8'h35;  // 5
                    line2[15:8]    <= 8'h20;  // space
                    line2[7:0]     <= 8'h20;  // space
                    
                    refresh <= 1;
                    state <= WAIT_NEXT;
                    counter <= 0;
                end
                
                // 테스트 4: 비트 패턴 (각 비트 개별 테스트)
                TEST_BITS: begin
                    // Line 1: "LCD Pin Test OK!"
                    line1[127:120] <= 8'h4C;  // L
                    line1[119:112] <= 8'h43;  // C
                    line1[111:104] <= 8'h44;  // D
                    line1[103:96]  <= 8'h20;  // space
                    line1[95:88]   <= 8'h50;  // P
                    line1[87:80]   <= 8'h69;  // i
                    line1[79:72]   <= 8'h6E;  // n
                    line1[71:64]   <= 8'h20;  // space
                    line1[63:56]   <= 8'h54;  // T
                    line1[55:48]   <= 8'h65;  // e
                    line1[47:40]   <= 8'h73;  // s
                    line1[39:32]   <= 8'h74;  // t
                    line1[31:24]   <= 8'h20;  // space
                    line1[23:16]   <= 8'h4F;  // O
                    line1[15:8]    <= 8'h4B;  // K
                    line1[7:0]     <= 8'h21;  // !
                    
                    // Line 2: "All Pins Good!! "
                    line2[127:120] <= 8'h41;  // A
                    line2[119:112] <= 8'h6C;  // l
                    line2[111:104] <= 8'h6C;  // l
                    line2[103:96]  <= 8'h20;  // space
                    line2[95:88]   <= 8'h50;  // P
                    line2[87:80]   <= 8'h69;  // i
                    line2[79:72]   <= 8'h6E;  // n
                    line2[71:64]   <= 8'h73;  // s
                    line2[63:56]   <= 8'h20;  // space
                    line2[55:48]   <= 8'h47;  // G
                    line2[47:40]   <= 8'h6F;  // o
                    line2[39:32]   <= 8'h6F;  // o
                    line2[31:24]   <= 8'h64;  // d
                    line2[23:16]   <= 8'h21;  // !
                    line2[15:8]    <= 8'h21;  // !
                    line2[7:0]     <= 8'h20;  // space
                    
                    refresh <= 1;
                    state <= WAIT_NEXT;
                    counter <= 0;
                end
                
                // 대기 상태 (각 테스트 화면을 2초간 표시)
                WAIT_NEXT: begin
                    refresh <= 0;
                    
                    if (tick_1sec) begin
                        counter <= counter + 1;
                    end
                    
                    // 2초 대기 후 다음 테스트로 전환
                    if (counter >= 2) begin
                        case (test_phase)
                            0: begin
                                test_phase <= 1;
                                state <= TEST_ALPHA;
                            end
                            1: begin
                                test_phase <= 2;
                                state <= TEST_NUM;
                            end
                            2: begin
                                test_phase <= 3;
                                state <= TEST_BITS;
                            end
                            3: begin
                                test_phase <= 0;
                                state <= TEST_HEX;
                            end
                            default: begin
                                test_phase <= 0;
                                state <= TEST_HEX;
                            end
                        endcase
                        counter <= 0;
                    end
                end
                
                default: begin
                    state <= INIT;
                end
            endcase
        end
    end

endmodule
