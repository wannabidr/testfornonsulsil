# LCD 테스트 모듈 - HBE-Combo 2-DLD

## 프로젝트 개요
HBE-Combo 2-DLD 보드의 16x2 Text LCD를 제어하는 테스트 모듈입니다.

## 파일 구성
- `lcd_controller.v`: LCD 제어 모듈 (HD44780 호환)
- `lcd_test_top.v`: 테스트용 탑 모듈
- `lcd_test.xdc`: 핀 제약 파일 (Xilinx Spartan-7)

## 하드웨어 사양
- **보드**: HBE-Combo 2-DLD
- **FPGA**: Xilinx Spartan-7 (xc7s75fgga484-1)
- **LCD**: 16x2 Character LCD (HD44780 컨트롤러)
- **시스템 클럭**: 100MHz

## LCD 제어 방식
### 초기화 시퀀스
1. 15ms 대기 (전원 안정화)
2. Function Set (0x38): 8-bit 모드, 2-line, 5x8 폰트
3. Display Control (0x0C): 디스플레이 ON, 커서 OFF, 깜빡임 OFF
4. Clear Display (0x01): 화면 클리어
5. Entry Mode Set (0x06): 커서 증가 모드

### 인터페이스 신호
- `lcd_rs`: Register Select (0=명령어, 1=데이터)
- `lcd_rw`: Read/Write (0=쓰기, 1=읽기)
- `lcd_e`: Enable 신호 (falling edge에서 데이터 래치)
- `lcd_data[7:0]`: 8-bit 데이터 버스

## Vivado에서 빌드 방법

### 1. 프로젝트 생성
```tcl
# Vivado 2020.1 실행 후
create_project lcd_test ./lcd_test -part xc7s75fgga484-1
```

### 2. 소스 파일 추가
```tcl
add_files {lcd_controller.v lcd_test_top.v}
add_files -fileset constrs_1 lcd_test.xdc
set_property top lcd_test_top [current_fileset]
```

### 3. 합성 및 구현
```tcl
launch_runs synth_1
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
```

### 4. 비트스트림 다운로드
- Hardware Manager 실행
- Auto Connect로 보드 연결
- `lcd_test_top.bit` 파일 프로그램

## 테스트 방법

### 1. 보드 설정
- HBE-Combo 2-DLD 보드에 전원 연결
- JTAG 케이블 연결
- LCD 백라이트 ON

### 2. 비트스트림 다운로드 후 확인사항
- **Line 1**: "Morse Translator" 표시
- **Line 2**: "  LCD Test OK  " 표시

### 3. 리셋 테스트
- 리셋 버튼을 눌러 화면이 다시 초기화되는지 확인

## 타이밍 사양
- LCD 클럭: 1MHz (100MHz 시스템 클럭을 50분주)
- Enable 펄스 폭: 최소 450ns (약 500ns 사용)
- 명령어 실행 시간: 50μs
- Clear Display 시간: 2ms
- 초기화 대기 시간: 15ms

## 모듈 인터페이스

### lcd_controller
```verilog
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
```

### 사용 예시
```verilog
// 2줄에 표시할 메시지 설정 (각 16글자)
reg [127:0] line1, line2;
reg refresh;

// Line 1에 "Hello World     " 표시
line1 = {"H","e","l","l","o"," ","W","o","r","l","d"," "," "," "," "," "};

// Line 2에 "  LCD Test OK  " 표시
line2 = {" "," ","L","C","D"," ","T","e","s","t"," ","O","K"," "," "," "};

// LCD 준비 완료 시 refresh 신호 활성화
if (ready) begin
    refresh <= 1;
end
```

## 주의사항
1. LCD는 초기화에 약 20ms 소요됨
2. 빠른 업데이트는 LCD 손상의 원인이 될 수 있음
3. 리셋 버튼은 Active Low 방식 사용
4. 핀 배치는 HBE-Combo 2-DLD 보드 매뉴얼 참조

## 다음 단계
이 LCD 모듈은 양방향 모스부호 번역기 프로젝트의 기본 출력 모듈로 사용됩니다.
- [ ] Keypad 입력 모듈 통합
- [ ] Morse 코드 변환 로직 추가
- [ ] Piezo Buzzer 출력 모듈 추가
- [ ] 전체 시스템 통합

## 문제 해결

### LCD에 아무것도 표시되지 않는 경우
- 백라이트 전원 확인
- 대비 조절 포텐셔미터 조정
- 핀 배치 재확인 (XDC 파일과 보드 매뉴얼 대조)

### 깨진 문자가 표시되는 경우
- 클럭 주파수 확인
- Enable 펄스 타이밍 확인
- 데이터 setup/hold 시간 확인
