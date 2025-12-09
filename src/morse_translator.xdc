## Morse Translator XDC - HBE-Combo 2-DLD (Spartan-7)
## Pin assignments for xc7s75fgga484-1

## Clock (1MHz)
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 1000.000 -name sys_clk -waveform {0.000 500.000} [get_ports clk]

## Reset (DIP_SW8)
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports rst]

## Mode Switch (DIP_SW1)
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD LVCMOS33} [get_ports mode_sw]

## Push Buttons [11:0] - KEY01 to KEY12
set_property -dict {PACKAGE_PIN K4 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN N8 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN N4 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]
set_property -dict {PACKAGE_PIN P6 IOSTANDARD LVCMOS33} [get_ports {btn[4]}]
set_property -dict {PACKAGE_PIN N6 IOSTANDARD LVCMOS33} [get_ports {btn[5]}]
set_property -dict {PACKAGE_PIN L5 IOSTANDARD LVCMOS33} [get_ports {btn[6]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {btn[7]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {btn[8]}]
set_property -dict {PACKAGE_PIN L7 IOSTANDARD LVCMOS33} [get_ports {btn[9]}]
set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports {btn[10]}]
set_property -dict {PACKAGE_PIN K6 IOSTANDARD LVCMOS33} [get_ports {btn[11]}]

## Text LCD
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {lcd_data[0]}]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports {lcd_data[1]}]
set_property -dict {PACKAGE_PIN C3 IOSTANDARD LVCMOS33} [get_ports {lcd_data[2]}]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports {lcd_data[3]}]
set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS33} [get_ports {lcd_data[4]}]
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {lcd_data[5]}]
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVCMOS33} [get_ports {lcd_data[6]}]
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports {lcd_data[7]}]
set_property -dict {PACKAGE_PIN A6 IOSTANDARD LVCMOS33} [get_ports lcd_en]
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports lcd_rs]
set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS33} [get_ports lcd_rw]

## Piezo Buzzer
set_property -dict {PACKAGE_PIN Y21 IOSTANDARD LVCMOS33} [get_ports buzzer]
