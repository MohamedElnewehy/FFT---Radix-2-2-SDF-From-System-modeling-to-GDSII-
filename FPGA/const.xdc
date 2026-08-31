# ----------------------------------------------------------------------------
# Clock Source - Bank 13
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN Y9 [get_ports {clk}];  # "GCLK"

# ----------------------------------------------------------------------------
# User LEDs - Bank 33
# ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN T22 [get_ports {y_start}];  # "LD0"
set_property PACKAGE_PIN T21 [get_ports {y_valid}];  # "LD1"
set_property PACKAGE_PIN U22 [get_ports {y_done}];  # "LD2"

## ----------------------------------------------------------------------------
## User DIP Switches - Bank 35
## ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN F22 [get_ports {rst_n}];  # "SW0"

## ----------------------------------------------------------------------------
## FMC Expansion Connector - Bank 34
## ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN M19 [get_ports {y_out[0]}];  # "FMC-LA00_CC_P"
set_property PACKAGE_PIN N20 [get_ports {y_out[1]}];  # "FMC-LA01_CC_N"
set_property PACKAGE_PIN N19 [get_ports {y_out[2]}];  # "FMC-LA01_CC_P"
set_property PACKAGE_PIN P18 [get_ports {y_out[3]}];  # "FMC-LA02_N"
set_property PACKAGE_PIN P17 [get_ports {y_out[4]}];  # "FMC-LA02_P"
set_property PACKAGE_PIN P22 [get_ports {y_out[5]}];  # "FMC-LA03_N"
set_property PACKAGE_PIN N22 [get_ports {y_out[6]}];  # "FMC-LA03_P"
set_property PACKAGE_PIN M22 [get_ports {y_out[7]}];  # "FMC-LA04_N"
set_property PACKAGE_PIN M21 [get_ports {y_out[8]}];  # "FMC-LA04_P"
set_property PACKAGE_PIN K18 [get_ports {y_out[9]}];  # "FMC-LA05_N"
set_property PACKAGE_PIN J18 [get_ports {y_out[10]}]; # "FMC-LA05_P"
set_property PACKAGE_PIN L22 [get_ports {y_out[11]}]; # "FMC-LA06_N"
set_property PACKAGE_PIN L21 [get_ports {y_out[12]}]; # "FMC-LA06_P"
set_property PACKAGE_PIN T17 [get_ports {y_out[13]}]; # "FMC-LA07_N"
set_property PACKAGE_PIN T16 [get_ports {y_out[14]}]; # "FMC-LA07_P"
set_property PACKAGE_PIN J22 [get_ports {y_out[15]}]; # "FMC-LA08_N"
set_property PACKAGE_PIN J21 [get_ports {y_out[16]}]; # "FMC-LA08_P"
set_property PACKAGE_PIN R21 [get_ports {y_out[17]}]; # "FMC-LA09_N"
set_property PACKAGE_PIN R20 [get_ports {y_out[18]}]; # "FMC-LA09_P"
set_property PACKAGE_PIN T19 [get_ports {y_out[19]}]; # "FMC-LA10_N"
set_property PACKAGE_PIN R19 [get_ports {y_out[20]}]; # "FMC-LA10_P"
set_property PACKAGE_PIN N18 [get_ports {y_out[21]}]; # "FMC-LA11_N"
set_property PACKAGE_PIN N17 [get_ports {y_out[22]}]; # "FMC-LA11_P"
set_property PACKAGE_PIN P21 [get_ports {y_out[23]}]; # "FMC-LA12_N"
set_property PACKAGE_PIN P20 [get_ports {y_out[24]}]; # "FMC-LA12_P"
set_property PACKAGE_PIN M17 [get_ports {y_out[25]}]; # "FMC-LA13_N"
set_property PACKAGE_PIN L17 [get_ports {y_out[26]}]; # "FMC-LA13_P"
set_property PACKAGE_PIN K20 [get_ports {y_out[27]}]; # "FMC-LA14_N"

## ----------------------------------------------------------------------------
## FMC Expansion Connector - Bank 35 (35-bit Input Signal)
## ---------------------------------------------------------------------------- 
set_property PACKAGE_PIN C19 [get_ports {x_in[0]}];  # "FMC-CLK1_N"
set_property PACKAGE_PIN D18 [get_ports {x_in[1]}];  # "FMC-CLK1_P"
set_property PACKAGE_PIN B20 [get_ports {x_in[2]}];  # "FMC-LA17_CC_N"
set_property PACKAGE_PIN B19 [get_ports {x_in[3]}];  # "FMC-LA17_CC_P"
set_property PACKAGE_PIN C20 [get_ports {x_in[4]}];  # "FMC-LA18_CC_N"
set_property PACKAGE_PIN D20 [get_ports {x_in[5]}];  # "FMC-LA18_CC_P"
set_property PACKAGE_PIN G16 [get_ports {x_in[6]}];  # "FMC-LA19_N"
set_property PACKAGE_PIN G15 [get_ports {x_in[7]}];  # "FMC-LA19_P"
set_property PACKAGE_PIN G21 [get_ports {x_in[8]}];  # "FMC-LA20_N"
set_property PACKAGE_PIN G20 [get_ports {x_in[9]}];  # "FMC-LA20_P"
set_property PACKAGE_PIN E20 [get_ports {x_in[10]}]; # "FMC-LA21_N"
set_property PACKAGE_PIN E19 [get_ports {x_in[11]}]; # "FMC-LA21_P"
set_property PACKAGE_PIN F19 [get_ports {x_in[12]}]; # "FMC-LA22_N"
set_property PACKAGE_PIN G19 [get_ports {x_in[13]}]; # "FMC-LA22_P"
set_property PACKAGE_PIN D15 [get_ports {x_in[14]}]; # "FMC-LA23_N"
set_property PACKAGE_PIN E15 [get_ports {x_in[15]}]; # "FMC-LA23_P"
set_property PACKAGE_PIN A19 [get_ports {x_in[16]}]; # "FMC-LA24_N"
set_property PACKAGE_PIN A18 [get_ports {x_in[17]}]; # "FMC-LA24_P"
set_property PACKAGE_PIN C22 [get_ports {x_in[18]}]; # "FMC-LA25_N"
set_property PACKAGE_PIN D22 [get_ports {x_in[19]}]; # "FMC-LA25_P"
set_property PACKAGE_PIN E18 [get_ports {x_in[20]}]; # "FMC-LA26_N"
set_property PACKAGE_PIN F18 [get_ports {x_in[21]}]; # "FMC-LA26_P"
set_property PACKAGE_PIN D21 [get_ports {x_valid}]; # "FMC-LA27_N"
set_property PACKAGE_PIN E21 [get_ports {x_start}]; # "FMC-LA27_P"
set_property PACKAGE_PIN A17 [get_ports {x_done}]; # "FMC-LA28_N"

## ----------------------------------------------------------------------------

# Note that the bank voltage for IO Bank 33 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 33]];

# Set the bank voltage for IO Bank 34 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 34]];

# Set the bank voltage for IO Bank 35 to 1.8V by default.
set_property IOSTANDARD LVCMOS18 [get_ports -of_objects [get_iobanks 35]];

# Note that the bank voltage for IO Bank 13 is fixed to 3.3V on ZedBoard. 
set_property IOSTANDARD LVCMOS33 [get_ports -of_objects [get_iobanks 13]];

# ---------------------------------------------------------------------------- 
# Timing constraints
# ---------------------------------------------------------------------------- 
create_clock -name clk -period 25 [get_ports clk] 

set_false_path -from [get_ports {rst_n}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {rst_n}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {rst_n}]

set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_in[*]}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_in[*]}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_start}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_start}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_valid}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_valid}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_done}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_done}]

set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_out[*]}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_out[*]}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_start}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_start}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_valid}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_valid}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_done}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_done}]

