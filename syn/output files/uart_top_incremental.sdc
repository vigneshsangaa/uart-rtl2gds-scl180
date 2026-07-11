# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Tue Jul 07 15:34:57 IST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design uart_top

create_clock -name "clk" -period 20.0 -waveform {0.0 10.0} [get_ports clk]
set_clock_transition 0.15 [get_clocks clk]
set_false_path -from [list \
  [get_ports rst_n]  \
  [get_ports rx_serial] ]
set_clock_gating_check -setup 0.0 
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports tx_start]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports tx_start]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {tx_data[0]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[7]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[6]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[5]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[4]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[3]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[2]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[1]}]
set_input_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {tx_data[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports tx_busy]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports tx_busy]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports {rx_data[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[7]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[6]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[5]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[4]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[3]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[2]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[1]}]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports {rx_data[0]}]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports rx_done]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports rx_done]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports parity_error]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports parity_error]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports framing_error]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports framing_error]
set_output_delay -clock [get_clocks clk] -add_delay -max 8.0 [get_ports tx_serial]
set_output_delay -clock [get_clocks clk] -add_delay -min 1.0 [get_ports tx_serial]
set_max_fanout 16.000 [current_design]
set_max_transition 0.3 [current_design]
set_wire_load_mode "enclosed"
set_dont_use true [get_lib_cells tsl18fs120_scl_ss/slbhb2]
set_dont_use true [get_lib_cells tsl18fs120_scl_ss/slbhb1]
set_dont_use true [get_lib_cells tsl18fs120_scl_ss/slbhb4]
set_clock_uncertainty -setup 0.15 [get_clocks clk]
set_clock_uncertainty -hold 0.08 [get_clocks clk]
