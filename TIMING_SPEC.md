# LCD 타이밍 사양

## 클럭 설정

### 시스템 클럭
- 주파수: 100MHz
- 주기: 10ns

### LCD 제어 클럭
- 주파수: 1MHz (100분주)
- 주기: 1μs
- 생성 방법: 100MHz 클럭을 100 카운트마다 enable 펄스 생성

## HD44780 LCD 타이밍 요구사항

| 파라미터 | 최소값 | 사용값 | 단위 |
|---------|--------|--------|------|
| 전원 안정화 시간 | 15ms | 15ms | ms |
| Enable 펄스 폭 (High) | 450ns | 50~5000μs | ns/μs |
| Enable 사이클 시간 | 1μs | 50~5000μs | μs |
| Setup 시간 (RS, RW → E) | 60ns | >1μs | ns |
| Hold 시간 (E → RS, RW) | 20ns | >1μs | ns |
| 데이터 Setup 시간 | 195ns | >1μs | ns |
| 데이터 Hold 시간 | 10ns | >1μs | ns |

## 명령어 실행 시간

| 명령어 | HD44780 요구시간 | 사용 시간 | 여유율 |
|--------|-----------------|----------|--------|
| Function Set | 37μs | 100μs | 2.7x |
| Display Control | 37μs | 2000μs | 54x |
| Clear Display | 1.52ms | 2000μs | 1.3x |
| Entry Mode Set | 37μs | 2000μs | 54x |
| Set DDRAM Address | 37μs | 100μs | 2.7x |
| Write Data | 37μs | 50μs | 1.35x |

## 초기화 시퀀스 타이밍

```
전원 ON
   |
   +-- 15ms 대기 (INIT_WAIT)
   |
   +-- Function Set (0x38) + 5ms 대기 (INIT_FUNC1)
   |
   +-- Function Set (0x38) + 100μs 대기 (INIT_FUNC2)
   |
   +-- Function Set (0x38) + 100μs 대기 (INIT_FUNC3)
   |
   +-- Display Control (0x0C) + 2ms 대기 (INIT_DISPLAY)
   |
   +-- Clear Display (0x01) + 2ms 대기 (INIT_CLEAR)
   |
   +-- Entry Mode Set (0x06) + 2ms 대기 (INIT_ENTRY)
   |
   +-- READY (총 약 24.2ms)
```

## 화면 업데이트 타이밍

### Line 1 쓰기
```
Set DDRAM Address (0x80) -> 100μs
Write Char[0] -> 50μs
Write Char[1] -> 50μs
...
Write Char[15] -> 50μs
총: 100μs + (16 × 50μs) = 900μs
```

### Line 2 쓰기
```
Set DDRAM Address (0xC0) -> 100μs
Write Char[0] -> 50μs
Write Char[1] -> 50μs
...
Write Char[15] -> 50μs
총: 100μs + (16 × 50μs) = 900μs
```

### 전체 화면 업데이트
```
Line 1: 900μs
Line 2: 900μs
Wait: 100μs
총: 1900μs = 1.9ms
```

## 클럭 분주기 설계

### Verilog 구현
```verilog
reg [6:0] clk_div;          // 0~99 카운트 (7비트)
reg lcd_clk_en;             // 1μs 마다 1 클럭 enable

always @(posedge clk) begin
    if (clk_div == 99) begin
        clk_div <= 0;
        lcd_clk_en <= 1;    // 100번째 클럭에서 enable
    end else begin
        clk_div <= clk_div + 1;
        lcd_clk_en <= 0;
    end
end
```

### 타이밍 다이어그램
```
clk (100MHz):     _|-|_|-|_|-|_... (x100) ..._|-|_|-|_
                   0  1  2  3            98  99  0  1

lcd_clk_en:       _____________________________|‾|_______
                                               (1μs pulse)
```

## 성능 비교

| 항목 | 1kHz 설계 | 1MHz 설계 | 개선율 |
|------|----------|-----------|--------|
| tick 주기 | 1ms | 1μs | 1000x |
| 문자당 쓰기 | 1ms | 50μs | 20x |
| 화면 업데이트 | 34ms | 1.9ms | 17.9x |
| 초기화 시간 | 24ms | 24.2ms | - |

## 주의사항

1. **Enable 펄스 폭**: 최소 450ns 필요, 현재 50μs~5ms 사용 (충분)
2. **명령 간 대기**: HD44780 내부 처리 시간 확보
3. **Clear Display**: 가장 긴 실행 시간(1.52ms) 필요
4. **타이밍 여유**: 모든 명령에 1.3배 이상 여유 확보

## 디버깅 팁

### 증상별 원인
- **화면 깜빡임**: Enable 펄스가 너무 짧음
- **글자 깨짐**: Setup/Hold 시간 부족
- **초기화 실패**: 전원 안정화 대기 부족
- **일부 글자 누락**: 문자 쓰기 간격이 너무 짧음

### 타이밍 조정 방법
1. DELAY_50US를 100US로 증가 (문자 쓰기 속도 감소)
2. DELAY_100US를 200US로 증가 (명령 실행 여유 증가)
3. 초기화 대기 시간 증가 (안정성 향상)
