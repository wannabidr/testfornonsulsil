# 빠른 해결 방법

## 리셋은 동작하는데 LCD에 아무것도 안 나올 때

### 즉시 시도해볼 것들 (순서대로)

## 1. 대비 조절 (가장 흔한 원인!)

LCD 뒷면 또는 옆면의 파란색 포텐셔미터(가변저항)를 찾으세요.

**방법**:
1. 작은 드라이버로 천천히 시계방향으로 돌리기
2. 아무것도 안 보이면 반대 방향으로 끝까지 돌리기
3. **중간 어딘가에서 문자가 보여야 합니다**

```
어두움 ←────[최적점]────→ 밝음
         (문자 보임)
```

**증상별**:
- LCD가 전체가 하얗게: 대비를 낮추세요 (반시계방향)
- LCD가 전체가 검게: 대비를 높이세요 (시계방향)

---

## 2. 디버그 코드 사용

### 빠른 테스트 순서

```bash
1. 프로젝트에서 lcd_test_top.v 제거
2. lcd_debug_top.v를 top 모듈로 설정
3. lcd_debug.xdc를 제약 파일로 사용
4. 합성 및 다운로드
5. LED 패턴 관찰
```

### LED 패턴 의미

```
LED[3:0] = 0001 → 초기화 시작
LED[3:0] = 0010 → Function Set 1
LED[3:0] = 0011 → Function Set 2
LED[3:0] = 0100 → Function Set 3
LED[3:0] = 0101 → Display ON
LED[3:0] = 0110 → Clear Display
LED[3:0] = 0111 → Entry Mode
LED[3:0] = 1000 → 문자 'A' 쓰기
LED[3:0] = 1111 → 완료! (이때 LCD에 'A'가 보여야 함)
```

**LED가 1111인데 LCD에 아무것도 없으면**: 대비 조절!

---

## 3. 타이밍 느리게 수정

`lcd_controller.v`의 타이밍을 10배 느리게:

### 수정 전
```verilog
localparam DELAY_15MS   = 32'd15000;  // 15ms
localparam DELAY_5MS    = 32'd5000;   // 5ms
localparam DELAY_2MS    = 32'd2000;   // 2ms
localparam DELAY_1MS    = 32'd1000;   // 1ms
localparam DELAY_100US  = 32'd100;    // 100us
localparam DELAY_50US   = 32'd50;     // 50us
```

### 수정 후
```verilog
localparam DELAY_15MS   = 32'd150000;  // 150ms
localparam DELAY_5MS    = 32'd50000;   // 50ms
localparam DELAY_2MS    = 32'd20000;   // 20ms
localparam DELAY_1MS    = 32'd10000;   // 10ms
localparam DELAY_100US  = 32'd1000;    // 1ms
localparam DELAY_50US   = 32'd500;     // 500us
```

---

## 4. 핀 연결 확인

### 오실로스코프 없이 확인하는 방법

#### Enable 신호 LED로 확인

`lcd_test_top.v` 또는 `lcd_debug_top.v`에 추가:

```verilog
// 포트에 추가
output wire test_led

// 모듈 내부에 추가
assign test_led = lcd_e;
```

XDC 파일에 추가:
```tcl
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports test_led]
```

**LED가 깜빡이면**: Enable 신호는 정상!

---

## 5. 최소 테스트 코드

완전히 단순화된 버전으로 테스트:

```verilog
module lcd_simple_test(
    input wire clk,
    input wire reset_btn,
    output reg lcd_rs,
    output wire lcd_rw,
    output reg lcd_e,
    output reg [7:0] lcd_data
);

    wire reset = ~reset_btn;
    assign lcd_rw = 0;
    
    reg [31:0] counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 0;
            lcd_rs <= 0;
            lcd_e <= 0;
            lcd_data <= 8'h38;
        end else begin
            counter <= counter + 1;
            
            // 100ms 주기로 Enable 토글
            if (counter == 10_000_000) begin
                lcd_e <= ~lcd_e;
                counter <= 0;
            end
        end
    end

endmodule
```

이 코드로도 LCD에 변화가 없으면 **하드웨어 연결 문제**입니다.

---

## 6. 보드별 핀 확인

**중요**: HBE-Combo 2-DLD 보드의 버전에 따라 핀이 다를 수 있습니다!

### 보드 매뉴얼 확인 방법
1. 보드에 적힌 모델명 확인
2. 제조사 웹사이트에서 매뉴얼 다운로드
3. LCD 섹션의 핀 배치도 확인
4. XDC 파일 수정

### 일반적인 LCD 핀 순서
```
LCD 모듈 핀:
1. VSS (GND)
2. VDD (5V)
3. VO (대비 조절)
4. RS (Register Select)
5. RW (Read/Write)
6. E (Enable)
7. DB0 (Data Bit 0)
8. DB1
9. DB2
10. DB3
11. DB4
12. DB5
13. DB6
14. DB7 (Data Bit 7)
15. A (백라이트 +)
16. K (백라이트 -)
```

---

## 7. RW 핀 처리

**중요**: RW 핀을 올바르게 처리해야 합니다.

### 방법 1: GND에 연결 (권장)
LCD의 RW 핀을 물리적으로 GND에 연결 (항상 쓰기 모드)

### 방법 2: FPGA에서 제어
```verilog
assign lcd_rw = 0;  // 항상 0 (쓰기 모드)
```

---

## 8. 전원 확인

### 체크리스트
- [ ] LCD VDD에 5V 공급
- [ ] LCD VSS가 GND에 연결
- [ ] FPGA GND와 LCD GND 공통 연결
- [ ] 백라이트 전원 연결 (A, K 핀)

### 멀티미터로 측정
- VDD: 4.5V ~ 5.5V
- VO: 0V ~ 5V (조절 가능)
- 백라이트: 3V ~ 5V

---

## 9. 백라이트 vs 문자

### 케이스 1: 백라이트만 켜짐
- 문자는 안 보이고 뒷불만 켜짐
- **해결**: 대비 조절!

### 케이스 2: 백라이트도 안 켜짐
- LCD 전원 문제
- VDD, GND, 백라이트 핀 확인

### 케이스 3: 검은 사각형만 보임
- LCD는 동작하지만 초기화 실패
- **해결**: 타이밍 느리게, 초기화 시퀀스 확인

---

## 10. 긴급 체크리스트

한 번에 모두 확인:

```
[ ] 1. 백라이트 켜지는가?
[ ] 2. 대비 조절 시도했는가?
[ ] 3. 디버그 코드 LED는 1111까지 가는가?
[ ] 4. RW 핀이 GND 또는 0으로 설정되었는가?
[ ] 5. Enable 신호가 토글되는가? (LED로 확인)
[ ] 6. XDC 파일 핀 번호가 매뉴얼과 일치하는가?
[ ] 7. VDD에 5V가 공급되는가?
[ ] 8. FPGA GND와 LCD GND가 연결되었는가?
[ ] 9. 타이밍을 10배 느리게 해봤는가?
[ ] 10. 다른 LCD로 교체해봤는가?
```

---

## 가장 빠른 해결책

**90% 확률로 이것만 하면 됩니다**:

### 1단계: 대비 조절
포텐셔미터를 천천히 양쪽 끝까지 돌려보기

### 2단계: 디버그 코드 사용
`lcd_debug_top.v` 사용, LED가 1111까지 가는지 확인

### 3단계: 타이밍 느리게
DELAY 값들을 10배로 증가

**이 3가지로 대부분의 문제가 해결됩니다!**

---

## 여전히 안 되면?

1. `TROUBLESHOOTING.md` 참조
2. 실습 조교님께 하드웨어 확인 요청
3. 오실로스코프로 신호 파형 측정
4. 다른 조의 정상 동작하는 보드와 비교
