# LCD 문제 해결 가이드

## 현재 증상: 리셋은 동작하는데 LCD에 아무것도 안 나옴

### 1단계: 하드웨어 기본 확인

#### LCD 백라이트 확인
- [ ] LCD 백라이트가 켜지는가?
  - **켜짐**: LCD 전원은 정상, 신호 문제
  - **안 켜짐**: 전원 문제
    - VDD (5V) 연결 확인
    - GND 연결 확인
    - 백라이트 전원 핀(A, K) 확인

#### LCD 대비 조절
- [ ] 포텐셔미터(VO 핀)를 천천히 돌려보기
  - 시계방향으로 끝까지
  - 반시계방향으로 끝까지
  - 중간 지점에서 문자가 보이는지 확인

### 2단계: 디버그 코드 테스트

기존 `lcd_test_top.v` 대신 `lcd_debug_top.v`를 사용하여 테스트하세요.

#### 디버그 코드 특징
- 매우 느린 타이밍 (눈으로 확인 가능)
- LED로 초기화 단계 표시
- 단순화된 시퀀스

#### LED 상태 의미

| LED 패턴 | 상태 | 의미 |
|----------|------|------|
| 0001 | POWER_ON / WAIT_15MS | 전원 안정화 대기 중 |
| 0010 | FUNC_SET1 / WAIT_5MS | Function Set 1단계 |
| 0011 | FUNC_SET2 / WAIT_1MS | Function Set 2단계 |
| 0100 | FUNC_SET3 | Function Set 3단계 |
| 0101 | DISP_ON | Display ON 명령 |
| 0110 | CLR_DISP | Clear Display |
| 0111 | ENTRY_MODE | Entry Mode 설정 |
| 1000 | WRITE_DATA | 문자 'A' 쓰기 |
| 1111 | DONE | 완료 (성공!) |

#### 빌드 및 테스트
```bash
# Vivado에서
1. lcd_debug_top.v를 top 모듈로 설정
2. lcd_debug.xdc를 제약 파일로 추가
3. 합성 및 다운로드
4. LED 패턴 관찰
```

### 3단계: LED 패턴 분석

#### 케이스 1: LED가 0001에서 멈춤
- **원인**: 클럭이 동작하지 않거나 카운터 문제
- **해결**:
  1. XDC 파일에서 클럭 핀 확인 (N11)
  2. 클럭 제약 확인
  3. 보드의 클럭 소스 확인

#### 케이스 2: LED가 순차적으로 변하지만 LCD에 아무것도 없음
- **원인**: LCD 신호 연결 문제
- **해결**:
  1. Enable 신호 (lcd_e) 핀 확인
  2. RS 신호 (lcd_rs) 핀 확인
  3. 데이터 버스 (lcd_data[7:0]) 연결 확인
  4. RW 신호를 GND에 연결했는지 확인

#### 케이스 3: LED가 1111 (완료)인데 LCD에 'A'가 안 보임
- **원인**: 
  - 대비 조절 문제
  - LCD 불량
  - 타이밍 문제
- **해결**:
  1. 대비 포텐셔미터를 천천히 돌려보기
  2. 다른 LCD로 교체 테스트
  3. 초기화 시간 증가

### 4단계: 오실로스코프 측정 (가능한 경우)

#### Enable 신호 (lcd_e) 측정
- 정상: 주기적인 펄스 발생
- 펄스 폭: 약 10μs 이상
- 펄스 간격: 약 100μs~2ms

#### 데이터 버스 측정
- 초기화 중: 0x38 반복 (00111000)
- Display ON: 0x0C (00001100)
- Clear Display: 0x01 (00000001)

### 5단계: 타이밍 조정

#### 문제: 타이밍이 너무 빠름
`lcd_controller.v`의 타이밍을 더 느리게 조정:

```verilog
// 현재
localparam DELAY_15MS   = 32'd15000;  // 15ms

// 수정 (10배 느리게)
localparam DELAY_15MS   = 32'd150000;  // 150ms
```

모든 DELAY 값을 10배로 증가:
- DELAY_15MS: 15000 → 150000
- DELAY_5MS: 5000 → 50000
- DELAY_2MS: 2000 → 20000
- DELAY_100US: 100 → 1000
- DELAY_50US: 50 → 500

### 6단계: 핀 할당 재확인

#### HBE-Combo 2-DLD 보드 매뉴얼 참조

보드 매뉴얼과 XDC 파일의 핀 번호를 대조 확인:

```
LCD_RS  : M4 핀이 맞는지?
LCD_RW  : M3 핀이 맞는지?
LCD_E   : L3 핀이 맞는지?
LCD_D7  : K3 핀이 맞는지?
LCD_D6  : J4 핀이 맞는지?
LCD_D5  : J3 핀이 맞는지?
LCD_D4  : H4 핀이 맞는지?
LCD_D3  : H3 핀이 맞는지?
LCD_D2  : H2 핀이 맞는지?
LCD_D1  : G3 핀이 맞는지?
LCD_D0  : G2 핀이 맞는지?
```

**주의**: 보드마다 핀 배치가 다를 수 있습니다!

### 7단계: LCD 초기화 방법 변경

#### 4-bit 모드로 변경 테스트

일부 LCD는 8-bit 모드 초기화에 문제가 있을 수 있습니다.
4-bit 모드로 테스트해보세요.

### 8단계: 최소 테스트 코드

완전히 단순화된 테스트:

```verilog
// 고정 신호 테스트
assign lcd_rs = 0;
assign lcd_rw = 0;
assign lcd_e = slow_clk;  // 깜빡이는 클럭
assign lcd_data = 8'h38;  // 고정 데이터
```

이 코드로도 LCD에 반응이 없으면 하드웨어 문제입니다.

### 9단계: 일반적인 문제들

#### 문제 1: RW 핀 처리
- LCD_RW 핀을 GND에 연결 (항상 쓰기 모드)
- 또는 코드에서 `assign lcd_rw = 0;`

#### 문제 2: 전원 순서
1. LCD 전원 OFF
2. FPGA 프로그래밍
3. LCD 전원 ON
4. 리셋 버튼 누르기

#### 문제 3: LCD 컨트롤러 종류
- HD44780 호환 확인
- ST7066, KS0066 등도 호환됨
- 1602A, 1602 LCD 확인

#### 문제 4: 전압 레벨
- FPGA: 3.3V 로직
- LCD: 5V 로직 (일반적)
- 레벨 시프터 필요할 수 있음

### 10단계: 체크리스트

최종 확인:

- [ ] 백라이트 켜짐
- [ ] 대비 조절 시도 (포텐셔미터)
- [ ] 디버그 코드 LED 패턴 확인
- [ ] XDC 핀 할당 재확인
- [ ] RW 핀 GND 연결 확인
- [ ] 클럭 동작 확인 (LED로)
- [ ] 타이밍 10배 증가 테스트
- [ ] 다른 LCD로 교체 테스트
- [ ] 전원 전압 측정 (5V)
- [ ] GND 공통 연결 확인

## 추가 도움

### Vivado ILA로 신호 모니터링

```tcl
# ILA 추가
create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets lcd_e]
# lcd_rs, lcd_data 등도 추가
```

### 시뮬레이션

`lcd_controller_tb.v` 테스트벤치로 타이밍 확인

## 성공 사례

정상 동작 시:
1. LED가 0001 → 0010 → ... → 1111로 순차 변화
2. 각 단계마다 약 수 밀리초 소요
3. LED가 1111일 때 LCD에 'A' 표시
4. 백라이트가 켜지고 대비 조절 시 문자 명확히 보임

## 여전히 안 되면

1. **보드 매뉴얼 확인**: HBE-Combo 2-DLD 공식 문서
2. **실습 조교/교수님 문의**: 하드웨어 문제일 수 있음
3. **다른 조의 보드와 비교**: 같은 코드로 테스트
4. **LCD 교체**: 불량 LCD일 가능성
