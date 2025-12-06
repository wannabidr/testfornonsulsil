## Morse Translator XDC - HBE-Combo 2-DLD (Spartan-7)
## NOTE: Update pin locations according to your board's pin map

## Clock (1MHz)
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -period 1000.000 -name sys_clk -waveform {0.000 500.000} [get_ports clk]

## Reset Button
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS33} [get_ports rst]

## Mode Switch
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS33} [get_ports mode_sw]

## Push Buttons [7:0] - Keypad input (Mode 0)
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN W17 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]
set_property -dict {PACKAGE_PIN W2 IOSTANDARD LVCMOS33} [get_ports {btn[4]}]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD LVCMOS33} [get_ports {btn[5]}]
set_property -dict {PACKAGE_PIN T1 IOSTANDARD LVCMOS33} [get_ports {btn[6]}]
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {btn[7]}]

## Confirm/Enter Button
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports btn_confirm]

## Dot Button (Mode 1)
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports btn_dot]

## Dash Button (Mode 1)
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports btn_dash]

## 7-Segment Display - Segments [7:0] = {dp, g, f, e, d, c, b, a}
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports {seg[7]}]

## 7-Segment Digit Select [7:0]
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {digit_sel[0]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports {digit_sel[1]}]
set_property -dict {PACKAGE_PIN V4 IOSTANDARD LVCMOS33} [get_ports {digit_sel[2]}]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {digit_sel[3]}]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {digit_sel[4]}]
set_property -dict {PACKAGE_PIN U3 IOSTANDARD LVCMOS33} [get_ports {digit_sel[5]}]
set_property -dict {PACKAGE_PIN V3 IOSTANDARD LVCMOS33} [get_ports {digit_sel[6]}]
set_property -dict {PACKAGE_PIN W3 IOSTANDARD LVCMOS33} [get_ports {digit_sel[7]}]

## Piezo Buzzer
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports buzzer]
