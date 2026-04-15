## ================= CLOCK =================
set_property PACKAGE_PIN E3 [get_ports CLK100MHZ]
set_property IOSTANDARD LVCMOS33 [get_ports CLK100MHZ]
create_clock -add -name sys_clk_pin -period 10.000 [get_ports CLK100MHZ]


## ================= BUTTONS =================
set_property PACKAGE_PIN D9 [get_ports {btn[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]

set_property PACKAGE_PIN C9 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]


## ================= SWITCHES =================
set_property PACKAGE_PIN A8  [get_ports {sw[0]}]
set_property PACKAGE_PIN C11 [get_ports {sw[1]}]
set_property PACKAGE_PIN C10 [get_ports {sw[2]}]
set_property PACKAGE_PIN A10 [get_ports {sw[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {sw[*]}]


## ================= LEDS =================
set_property PACKAGE_PIN H5  [get_ports {LED[0]}]
set_property PACKAGE_PIN J5  [get_ports {LED[1]}]
set_property PACKAGE_PIN T9  [get_ports {LED[2]}]
set_property PACKAGE_PIN T10 [get_ports {LED[3]}]
set_property PACKAGE_PIN H6  [get_ports {LED[4]}]
set_property PACKAGE_PIN J2  [get_ports {LED[5]}]
set_property PACKAGE_PIN J4  [get_ports {LED[6]}]
set_property PACKAGE_PIN F6  [get_ports {LED[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]
