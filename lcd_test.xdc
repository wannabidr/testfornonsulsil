# ============================================================================
# XDC Constraint File for LCD Test on HBE-Combo 2-DLD
# Target Device: Xilinx Spartan-7 (xc7s75fgga484-1)
# ============================================================================

# Clock Constraint (50MHz)
create_clock -period 20.000 -name clk [get_ports clk]

# Clock Input
set_property PACKAGE_PIN <CLK_PIN> [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset Button (Active Low)
set_property PACKAGE_PIN <RST_PIN> [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]
set_property PULLUP true [get_ports rst_n]

# Test Start Signal (Optional - can use a switch or button)
set_property PACKAGE_PIN <TEST_START_PIN> [get_ports test_start]
set_property IOSTANDARD LVCMOS33 [get_ports test_start]
set_property PULLUP true [get_ports test_start]

# LCD Interface (4-bit mode)
# Note: HBE-Combo 2-DLD 보드의 실제 핀 번호를 확인하여 수정 필요
# 아래는 일반적인 핀 할당 예시입니다.

# LCD Register Select (RS)
set_property PACKAGE_PIN <LCD_RS_PIN> [get_ports lcd_rs]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_rs]

# LCD Enable (E)
set_property PACKAGE_PIN <LCD_E_PIN> [get_ports lcd_e]
set_property IOSTANDARD LVCMOS33 [get_ports lcd_e]

# LCD Data Bus (D7-D4) - 4-bit mode
set_property PACKAGE_PIN <LCD_D7_PIN> [get_ports {lcd_db[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_db[3]}]

set_property PACKAGE_PIN <LCD_D6_PIN> [get_ports {lcd_db[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_db[2]}]

set_property PACKAGE_PIN <LCD_D5_PIN> [get_ports {lcd_db[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_db[1]}]

set_property PACKAGE_PIN <LCD_D4_PIN> [get_ports {lcd_db[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {lcd_db[0]}]

# ============================================================================
# Timing Constraints
# ============================================================================
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk]

# ============================================================================
# 주의사항:
# 1. <CLK_PIN>, <RST_PIN>, <TEST_START_PIN> 등의 실제 핀 번호를 
#    HBE-Combo 2-DLD 보드 매뉴얼에서 확인하여 수정해야 합니다.
# 2. LCD 핀 할당도 보드 매뉴얼을 참조하여 정확한 핀 번호로 수정해야 합니다.
# 3. 일반적으로 HBE-Combo 2-DLD 보드의 Text LCD는 다음과 같이 연결됩니다:
#    - RS: GPIO 핀
#    - E: GPIO 핀
#    - D7-D4: GPIO 핀 (4-bit mode)
#    - VCC, GND, V0 (Contrast)는 보드에서 자동 연결됨
# ============================================================================
