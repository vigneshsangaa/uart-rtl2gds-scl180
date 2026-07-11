# ####################################################################

#  Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Thu Jul 09 10:38:44 IST 2026

# ####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design uart_top_pad

set_clock_gating_check -setup 0.0 
set_max_fanout 16.000 [current_design]
set_max_transition 0.3 [current_design]
set_wire_load_mode "enclosed"
set_dont_use true [get_lib_cells tsl18fs120_scl_ss/slbhb2]
set_dont_use true [get_lib_cells tsl18fs120_scl_ss/slbhb1]
set_dont_use true [get_lib_cells tsl18fs120_scl_ss/slbhb4]
