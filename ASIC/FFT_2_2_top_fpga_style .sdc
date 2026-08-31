#===========================================================================
# FFT_2_2_top.sdc  -- FPGA-style fixed I/O delay constraints
#===========================================================================

# ---- Clock ----
create_clock -name clk -period 40 [get_ports clk]

set_clock_uncertainty 0.25 [get_clocks clk]
set_clock_transition  0.15 [get_clocks clk]
set_propagated_clock  [get_clocks clk]

# ---- Reset (async, excluded from setup/hold timing graph) ----
set_false_path -from [get_ports {rst_n}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {rst_n}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {rst_n}]

# ---- Data inputs: fixed 2ns/1ns, independent of CLOCK_PERIOD ----
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_in[*]}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_in[*]}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_start}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_start}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_valid}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_valid}]
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {x_done}]
set_input_delay -clock [get_clocks clk] -min 1.000 [get_ports {x_done}]

# ---- Data outputs: fixed 2ns/1ns ----
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_out[*]}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_out[*]}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_start}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_start}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_valid}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_valid}]
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {y_done}]
set_output_delay -clock [get_clocks clk] -min 1.000 [get_ports {y_done}]

# ---- ASIC-specific: driving cell / output load ----
# (not applicable on FPGA, but required here so unconstrained
#  input/output pins get realistic first/last-stage delay in STA)
# NOTE: listed explicitly instead of using remove_from_collection,
# which is unsupported in this OpenLane STA stage's Tcl interpreter.
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 -pin Y \
    [get_ports {rst_n x_in[*] x_start x_valid x_done}]

set_load 33.0 [all_outputs]

# ---- Design-wide limits ----
set_max_fanout     20   [current_design]
set_max_transition 0.75 [current_design]

# ---- Timing derate (accounts for sky130 lib/RCX modeling uncertainty) ----
set_timing_derate -early 0.95
set_timing_derate -late  1.05
