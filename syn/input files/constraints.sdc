# File        : constraints.sdc
# Target      : uart_top (uart_top.v + uart_tx/uart_rx/baud_gen)
# Description : Timing constraints for synthesis / STA.

create_clock -name clk -period 20.000 -waveform {0 10} [get_ports clk]

set_clock_uncertainty -setup 0.150 [get_clocks clk]
set_clock_uncertainty -hold  0.080 [get_clocks clk]

set_clock_transition 0.150 [get_clocks clk]

set_false_path -from [get_ports rst_n]

set_false_path -from [get_ports rx_serial]

set_input_delay -clock clk -max 8.0 [get_ports tx_start]
set_input_delay -clock clk -min 1.0 [get_ports tx_start]

set_input_delay -clock clk -max 8.0 [get_ports {tx_data[*]}]
set_input_delay -clock clk -min 1.0 [get_ports {tx_data[*]}]

set_output_delay -clock clk -min 1.0 [get_ports tx_busy]

set_output_delay -clock clk -max 8.0 [get_ports {rx_data[*]}]
set_output_delay -clock clk -min 1.0 [get_ports {rx_data[*]}]

set_output_delay -clock clk -max 8.0 [get_ports rx_done]
set_output_delay -clock clk -min 1.0 [get_ports rx_done]

set_output_delay -clock clk -max 8.0 [get_ports parity_error]
set_output_delay -clock clk -min 1.0 [get_ports parity_error]

set_output_delay -clock clk -max 8.0 [get_ports framing_error]
set_output_delay -clock clk -min 1.0 [get_ports framing_error]

set_output_delay -clock clk -max 8.0 [get_ports tx_serial]
set_output_delay -clock clk -min 1.0 [get_ports tx_serial]

set_max_fanout 16 [current_design]
set_max_transition 0.3 [current_design]
