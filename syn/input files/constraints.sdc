#==============================================================
# File        : constraints.sdc
# Target      : uart_top (uart_top.v + uart_tx/uart_rx/baud_gen)
# Description : Timing constraints for synthesis / STA.
#
# Design facts this file is based on:
#   - Single system clock 'clk', used by every module (uart_top,
#     baud_gen, uart_tx, uart_rx). CLK_FREQ parameter = 50 MHz.
#   - 'baud_tick_16x' is NOT an independent clock. It is a 1-cycle
#     enable pulse generated inside baud_gen from 'clk' (divide-by
#     325 counter). It must stay a regular data/enable signal in
#     STA, not a generated/derived clock, otherwise the tool will
#     try to balance clock skew on it and report bogus violations.
#   - 'rx_serial' is the ONLY truly asynchronous input -- it comes
#     from an external TX device with no fixed phase relationship
#     to 'clk'. uart_rx.v already hardens it with a 2-flop
#     synchronizer (rx_sync_ff1/ff2) before any logic uses it.
#     Because of that synchronizer, the path into the first flop
#     is fundamentally asynchronous and must be excluded from
#     normal setup/hold checking (false path), not given a tight
#     input delay as if it were a synchronous interface signal.
#   - 'rst_n' is asynchronous active-low reset (used in
#     `posedge clk or negedge rst_n` in every module) -> also a
#     false path / reset-recovery-removal exception, not a normal
#     data path.
#   - All other top-level ports (tx_start, tx_data, tx_busy,
#     rx_data, rx_done, parity_error, framing_error, tx_serial)
#     ARE synchronous to clk, so they get conventional
#     input/output delay constraints.
#==============================================================

#--------------------------------------------------------------
# 1. Primary clock
#--------------------------------------------------------------
# CLK_FREQ = 50_000_000 Hz  -> period = 20.000 ns
# Using 50% duty cycle (rise@0, fall@10).
create_clock -name clk -period 20.000 -waveform {0 10} [get_ports clk]

# Typical on-chip variation guardbands. Adjust to your PD flow.
set_clock_uncertainty -setup 0.150 [get_clocks clk]
set_clock_uncertainty -hold  0.080 [get_clocks clk]

# Clock transition (slew) target, helps synthesis size the clock tree
set_clock_transition 0.150 [get_clocks clk]

#--------------------------------------------------------------
# 2. Explicitly NOT declaring baud_tick_16x as a clock.
#--------------------------------------------------------------
# It's an internal net (output of baud_gen), driven by clk, and every
# module that consumes it (uart_tx, uart_rx) samples it as ordinary
# synchronous data on the clk domain. No constraint needed/wanted here.

#--------------------------------------------------------------
# 3. Asynchronous reset: false path
#--------------------------------------------------------------
# rst_n is asserted/released asynchronously w.r.t. clk in every
# `always @(posedge clk or negedge rst_n)` block. Treat the reset
# network as a false path for setup/hold; reset recovery/removal
# is checked separately if your tool supports set_clock_groups /
# reset_synchronizer assertions -- at minimum, exclude it from the
# normal functional timing graph.
set_false_path -from [get_ports rst_n]

#--------------------------------------------------------------
# 4. Asynchronous serial RX input: false path into the synchronizer
#--------------------------------------------------------------
# rx_serial has no fixed timing relationship to clk (external TX
# device, independent or absent clock). uart_rx.v's first
# synchronizer flop (rx_sync_ff1) is the metastability boundary.
# The whole input path is therefore excluded from normal STA --
# do NOT give it a tight input_delay as if synchronous.
set_false_path -from [get_ports rx_serial]

# (Optional, recommended in real flows) constrain max delay on the
# 2-flop synchronizer chain itself so CDC tools/STA flag a 3rd-flop
# accidentally inserted, and so backend tools know to keep these
# two flops physically close together for low MTBF:
#   set_max_delay <small_value> -from [get_pins u_uart_rx/rx_sync_ff1/Q] \
#                                -to   [get_pins u_uart_rx/rx_sync_ff2/D]
# Left commented because exact pin/instance names depend on your
# synthesis tool's naming and hierarchy flattening.

#--------------------------------------------------------------
# 5. Synchronous input constraints (system/parallel side)
#--------------------------------------------------------------
# tx_start, tx_data: driven by whatever logic issues the "send a
# byte" request, synchronous to clk. Assume a conservative 40% of
# the clock period is consumed by the driving logic + board/IO
# delay before it reaches this chip's input pins.
set_input_delay -clock clk -max 8.0 [get_ports tx_start]
set_input_delay -clock clk -min 1.0 [get_ports tx_start]

set_input_delay -clock clk -max 8.0 [get_ports {tx_data[*]}]
set_input_delay -clock clk -min 1.0 [get_ports {tx_data[*]}]

#--------------------------------------------------------------
# 6. Synchronous output constraints (system/parallel side)
#--------------------------------------------------------------
# tx_busy, rx_data, rx_done, parity_error, framing_error all come
# directly out of clk-synchronous registers in uart_tx.v/uart_rx.v.
# Give the downstream receiving logic a reasonable capture window.
set_output_delay -clock clk -max 8.0 [get_ports tx_busy]
set_output_delay -clock clk -min 1.0 [get_ports tx_busy]

set_output_delay -clock clk -max 8.0 [get_ports {rx_data[*]}]
set_output_delay -clock clk -min 1.0 [get_ports {rx_data[*]}]

set_output_delay -clock clk -max 8.0 [get_ports rx_done]
set_output_delay -clock clk -min 1.0 [get_ports rx_done]

set_output_delay -clock clk -max 8.0 [get_ports parity_error]
set_output_delay -clock clk -min 1.0 [get_ports parity_error]

set_output_delay -clock clk -max 8.0 [get_ports framing_error]
set_output_delay -clock clk -min 1.0 [get_ports framing_error]

#--------------------------------------------------------------
# 7. Serial TX output (tx_serial)
#--------------------------------------------------------------
# tx_serial is registered in uart_tx.v (clk-synchronous) and drives
# an external pin that will be sampled by a remote, unrelated clock
# domain (the receiving device's own UART). There's no real setup/
# hold relationship to enforce against an unknown remote clock, so
# this is commonly false-pathed at the output too, OR given a loose
# output delay if your flow requires every port to be constrained.
# Loose/conservative choice shown here (uncomment the false_path
# instead if your sign-off flow disallows unconstrained outputs):
set_output_delay -clock clk -max 8.0 [get_ports tx_serial]
set_output_delay -clock clk -min 1.0 [get_ports tx_serial]
# set_false_path -to [get_ports tx_serial]

#--------------------------------------------------------------
# 8. Design rule / environment constraints (typical defaults)
#--------------------------------------------------------------
set_max_fanout 16 [current_design]
set_max_transition 0.3 [current_design]
