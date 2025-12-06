# 양방향 모스부호 번역기 개발 진행 상황

## 프로젝트 개요
- **과목**: 논리회로 설계 및 실험
- **주제**: 양방향 모스부호 번역기 (Bidirectional Morse Code Translator)
- **FPGA**: Xilinx Spartan-7 (xc7s75fgga484-1)
- **보드**: HBE-Combo 2-DLD
- **클럭**: 1MHz

---

## 구현된 모듈

### 1. 기본 인프라
| 파일 | 설명 |
|------|------|
| `clk_divider.v` | 클럭 분주기 (1kHz, 500Hz, 5Hz) |
| `debounce.v` | 버튼 디바운서 (20ms) |

### 2. 입력 처리
| 파일 | 설명 |
|------|------|
| `keypad_decoder.v` | Phone keypad 스타일 알파벳 입력 (Mode 0) |
| `morse_input_fsm.v` | Dot/Dash 버튼 입력 FSM (Mode 1) |

### 3. 변환 로직
| 파일 | 설명 |
|------|------|
| `morse_encoder.v` | 알파벳 → 모스부호 LUT |
| `morse_decoder.v` | 모스부호 → 알파벳 LUT |

### 4. 출력
| 파일 | 설명 |
|------|------|
| `buzzer_driver.v` | 피에조 버저 드라이버 |
| `seg7_controller.v` | 8자리 7-segment 컨트롤러 |

### 5. 통합
| 파일 | 설명 |
|------|------|
| `morse_top.v` | 최상위 모듈 |
| `morse_translator.xdc` | 핀 할당 파일 |

---

## 핀 매핑

### 입력
| 신호 | 핀 | 설명 |
|------|-----|------|
| clk | B6 | 1MHz 클럭 |
| rst | U4 | DIP_SW8 (리셋) |
| mode_sw | Y1 | DIP_SW1 (모드 전환) |
| btn[0] | K4 | KEY01 |
| btn[1] | N8 | KEY02 |
| btn[2] | N4 | KEY03 |
| btn[3] | N1 | KEY04 |
| btn[4] | P6 | KEY05 |
| btn[5] | N6 | KEY06 |
| btn[6] | L5 | KEY07 |
| btn[7] | J2 | KEY08 |
| btn[8] | K2 | KEY09 |
| btn[9] | L7 | KEY10 |
| btn[10] | L1 | KEY11 |
| btn[11] | K6 | KEY12 |

### 출력
| 신호 | 핀 |
|------|-----|
| seg[0] (a) | F1 |
| seg[1] (b) | F5 |
| seg[2] (c) | E2 |
| seg[3] (d) | E4 |
| seg[4] (e) | J1 |
| seg[5] (f) | J3 |
| seg[6] (g) | J7 |
| seg[7] (dp) | H2 |
| digit_sel[0] | H4 |
| digit_sel[1] | H6 |
| digit_sel[2] | G1 |
| digit_sel[3] | G3 |
| digit_sel[4] | L6 |
| digit_sel[5] | K1 |
| digit_sel[6] | K3 |
| digit_sel[7] | K5 |
| buzzer | Y21 |

---

## 버튼 매핑

### Mode 0 (알파벳 → 모스부호)
Phone Keypad 방식:
- KEY02-KEY09 (btn[1]-btn[8]): 숫자 2-9 (ABC, DEF, GHI, JKL, MNO, PQRS, TUV, WXYZ)
- KEY12 (btn[11]): # (Confirm)

### Mode 1 (모스부호 → 알파벳)
- KEY10 (btn[9]): Dot (.)
- KEY11 (btn[10]): Dash (-)
- KEY12 (btn[11]): Confirm

---

## 테스트 결과

### Mode 0 (알파벳 → 모스부호): ✅ 정상 동작
- Phone keypad 입력 정상
- 버저 출력 정상
- 7-segment 표시 정상

### Mode 1 (모스부호 → 알파벳): ❌ 문제 있음

---

## 발견된 문제점 및 수정 시도

### 문제 1: char_valid 펄스 감지 실패
**원인**: 
- `decode_valid`가 1MHz에서 1클럭 펄스 (1μs)
- `seg7_controller`가 500Hz 클럭으로 동작하여 펄스 놓침

**시도한 해결책**:
- `seg7_controller`에 1MHz 클럭 추가
- `char_valid` 감지를 1MHz 도메인에서 처리

### 문제 2: 모스코드 비트 순서 불일치
**원인**:
- `morse_input_fsm`: LSB 방향으로 shift
- `morse_decoder`: MSB부터 읽음

**시도한 해결책**:
- `morse_input_fsm`을 MSB-first 방식으로 수정
- 첫 입력 → bit[4], 두 번째 → bit[3], ...

### 문제 3: 7-segment 디스플레이 이상 동작
**증상**:
1. 첫 번째 입력 시 첫 번째 자리는 비고 나머지 7자리에 출력
2. 두 번째 입력 시 8자리 모두에 덮어쓰기
3. 계속 입력 시 해당 자리가 점점 밝아짐

**시도한 해결책**:
- 버퍼 관리 방식을 right-shift로 변경
- 새 문자 입력 시 기존 문자 오른쪽 shift, 새 문자는 왼쪽에 추가
- 초기화 시 0x00 (빈칸)으로 설정

**현재 상태**: 아직 해결되지 않음

---

## 다음 단계
1. 7-segment 디스플레이 문제 근본 원인 분석
2. 신호 흐름 디버깅 (LED 등 활용)
3. 하드웨어 핀 연결 확인

---

## 파일 구조
```
src/
├── morse_top.v
├── clk_divider.v
├── debounce.v
├── keypad_decoder.v
├── morse_encoder.v
├── morse_input_fsm.v
├── morse_decoder.v
├── buzzer_driver.v
├── seg7_controller.v
└── morse_translator.xdc
```
