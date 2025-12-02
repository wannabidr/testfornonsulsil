## 시스템 클럭 (100MHz)
set_property -dict {PACKAGE_PIN N11 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

## 리셋 버튼 (Active Low)
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports reset_btn]

## LCD 인터페이스
# RS (Register Select)
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports lcd_rs]

# RW (Read/Write)
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports lcd_rw]

# E (Enable)
set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS33} [get_ports lcd_e]

# Data Bus [7:0]
set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports {lcd_data[7]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {lcd_data[6]}]
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {lcd_data[5]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {lcd_data[4]}]
set_property -dict {PACKAGE_PIN H3 IOSTANDARD LVCMOS33} [get_ports {lcd_data[3]}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {lcd_data[2]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {lcd_data[1]}]
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {lcd_data[0]}]

## 디버그용 LED (상태 표시)
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
