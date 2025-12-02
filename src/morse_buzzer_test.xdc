##==============================================================================
## Morse Buzzer Test - Pin Constraints for HBE-Combo 2-DLD Board
## Target: Xilinx Spartan-7 (xc7s75fgga484-1)
## NOTE: Modify pin locations according to your board's actual pinout
##==============================================================================

## Clock signal (25MHz)
set_property -dict { PACKAGE_PIN Y18  IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -period 40.000 -name sys_clk [get_ports { clk }]

## Reset button (active low)
set_property -dict { PACKAGE_PIN V17  IOSTANDARD LVCMOS33 } [get_ports { rst_n }]

##==============================================================================
## 12 Push Buttons for alphabet input (A-L)
## Button mapping: btn[0]=A, btn[1]=B, ..., btn[11]=L
## Active high (directly active when pressed)
##==============================================================================
set_property -dict { PACKAGE_PIN W16  IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]
set_property -dict { PACKAGE_PIN W15  IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]
set_property -dict { PACKAGE_PIN V15  IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]
set_property -dict { PACKAGE_PIN U15  IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]
set_property -dict { PACKAGE_PIN U14  IOSTANDARD LVCMOS33 } [get_ports { btn[4] }]
set_property -dict { PACKAGE_PIN T14  IOSTANDARD LVCMOS33 } [get_ports { btn[5] }]
set_property -dict { PACKAGE_PIN R14  IOSTANDARD LVCMOS33 } [get_ports { btn[6] }]
set_property -dict { PACKAGE_PIN P14  IOSTANDARD LVCMOS33 } [get_ports { btn[7] }]
set_property -dict { PACKAGE_PIN N14  IOSTANDARD LVCMOS33 } [get_ports { btn[8] }]
set_property -dict { PACKAGE_PIN M14  IOSTANDARD LVCMOS33 } [get_ports { btn[9] }]
set_property -dict { PACKAGE_PIN M15  IOSTANDARD LVCMOS33 } [get_ports { btn[10] }]
set_property -dict { PACKAGE_PIN L14  IOSTANDARD LVCMOS33 } [get_ports { btn[11] }]

##==============================================================================
## Piezo Buzzer Output
##==============================================================================
set_property -dict { PACKAGE_PIN L15  IOSTANDARD LVCMOS33 } [get_ports { buzzer }]

##==============================================================================
## Debug LEDs [7:0]
##==============================================================================
set_property -dict { PACKAGE_PIN K14  IOSTANDARD LVCMOS33 } [get_ports { led_debug[0] }]
set_property -dict { PACKAGE_PIN K15  IOSTANDARD LVCMOS33 } [get_ports { led_debug[1] }]
set_property -dict { PACKAGE_PIN J14  IOSTANDARD LVCMOS33 } [get_ports { led_debug[2] }]
set_property -dict { PACKAGE_PIN J15  IOSTANDARD LVCMOS33 } [get_ports { led_debug[3] }]
set_property -dict { PACKAGE_PIN H14  IOSTANDARD LVCMOS33 } [get_ports { led_debug[4] }]
set_property -dict { PACKAGE_PIN H15  IOSTANDARD LVCMOS33 } [get_ports { led_debug[5] }]
set_property -dict { PACKAGE_PIN G14  IOSTANDARD LVCMOS33 } [get_ports { led_debug[6] }]
set_property -dict { PACKAGE_PIN G15  IOSTANDARD LVCMOS33 } [get_ports { led_debug[7] }]

##==============================================================================
## Configuration and Bitstream Settings
##==============================================================================
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
