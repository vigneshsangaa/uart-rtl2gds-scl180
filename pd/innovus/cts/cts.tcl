#=================================================================
# Script      : innovus_cts.tcl
# Stage       : Clock Tree Synthesis (Innovus / CCOpt)
# Design      : uart_top
#=================================================================
# CTS target derivation (recorded for report):
#   Clock period          = 20 ns   (50 MHz, fixed by design spec)
#   Max skew target       = 1.0 ns  (~5% of period -- protects hold
#                            margin on a small, low-fanout tree;
#                            63 sequential cells, single domain)
#   Max transition target = 0.45 ns
#       REVISED from an initial 0.25ns target. First ccopt_design
#       run failed with IMPCCOPT-1209 / IMPCCOPT-1013: 0.25ns is
#       below the physical drive-strength floor of this gpdk180
#       clock buffer/inverter library -- even the strongest cell
#       (CLKBUFX40M / CLKINVX40M) cannot drive another large clock
#       cell that fast. Innovus reported the computed minimum
#       achievable target as 0.411-0.423ns (varies slightly by
#       corner/edge). 0.45ns is set just above that floor, keeping
#       slew reasonably tight while leaving margin instead of
#       running at the literal minimum the library can do.
#
# Differences from generic multi-clock (e.g. FIFO write/read_clk)
# reference flows:
#   - uart_top has ONE clock domain (clk) -> one skew group, not two
#   - No source_driver pin override needed: with a single clock and
#     a single top-level clk port, Innovus infers the tree source
#     automatically. Forcing a library-specific pin (as in dual-
#     clock FIFO flows) is unnecessary here and would be guessing
#     at a pin name we have not verified against gpdk180.
#=================================================================

set CORNER       "ss"      ;# active corner for this CTS run; matches Genus/Innovus convention
set init_top_cell "uart_top"

set OUT_DIR "innovus_out_${CORNER}"
set CTS_DIR "${OUT_DIR}/ClockTreeSynthesis"
file mkdir $CTS_DIR

# ---------------------------------------------------------------
# 0. Reporting format (carried over from reference -- useful for
#    readable timing reports throughout, not CTS-specific)
# ---------------------------------------------------------------
set_global report_timing_format {instance arc net cell slew delay arrival required}

# ---------------------------------------------------------------
# 1. Clock tree spec
#    NOTE: create_ccopt_clock_tree_spec was REMOVED here.
#    On this design, Innovus already had an implicit/trivial clock
#    tree object for "clk" in the database the moment placement
#    completed (0 bufs/invs, just a flat net to all 63 sinks --
#    confirmed via report_ccopt_clock_trees -summary). Calling
#    create_ccopt_clock_tree_spec on top of that throws
#    IMPCCOPT-2048 ("clock trees are already defined"), since the
#    command is only meant for a design with NO clock tree object
#    yet. We skip spec generation and go straight to setting
#    properties on the existing tree, which ccopt_design then
#    builds out with real buffering.
# ---------------------------------------------------------------

# Open Clock Tree Debugger snapshot before optimization, for
# before/after comparison in the GUI
ctd_win -id before_ccopt

# ---------------------------------------------------------------
# 2. CCOpt properties: transition + skew targets
#    Set on BOTH corners since skew affects setup (SS/max_delay)
#    and hold (FF/min_delay) checks, not hold alone.
# ---------------------------------------------------------------
set_ccopt_property -delay_corner max_delay -net_type top   target_max_trans 0.45
set_ccopt_property -delay_corner min_delay -net_type top   target_max_trans 0.45
set_ccopt_property -delay_corner max_delay -net_type trunk target_max_trans 0.45
set_ccopt_property -delay_corner min_delay -net_type trunk target_max_trans 0.45
set_ccopt_property -delay_corner max_delay -net_type leaf  target_max_trans 0.45
set_ccopt_property -delay_corner min_delay -net_type leaf  target_max_trans 0.45

# Skew target, both corners, single clock domain ("clk")
set_ccopt_property -skew_group clk/all -delay_corner max_delay target_skew 1.0
set_ccopt_property -skew_group clk/all -delay_corner min_delay target_skew 1.0

# ---------------------------------------------------------------
# 3. Run CTS in staged effort levels (cluster -> trial -> full)
#    Same staged approach as reference -- lets you inspect the
#    tree at each stage in CTD before committing to full balance.
# ---------------------------------------------------------------
set_ccopt_property balance_mode cluster
ccopt_design -cts
ctd_win -id cluster_mode

set_ccopt_property balance_mode trial
ccopt_design -cts
ctd_win -id trial_mode

set_ccopt_property balance_mode full
ccopt_design -cts
ctd_win -id full_mode

# ---------------------------------------------------------------
# 4. Reports
# ---------------------------------------------------------------
report_ccopt_clock_trees -summary -file ${CTS_DIR}/${init_top_cell}_clock_trees.rpt
report_ccopt_skew_groups -summary -file ${CTS_DIR}/${init_top_cell}_skew_group.rpt
reportCongestion -overflow -hotSpot > ${CTS_DIR}/${init_top_cell}_congestion.rpt

# ---------------------------------------------------------------
# 5. Post-CTS timing check (propagated clock, first time skew
#    shows up in real numbers instead of ideal/zero-delay)
# ---------------------------------------------------------------
redirect "${CTS_DIR}/${init_top_cell}_post_cts_timing.rpt" {
    timeDesign -postCTS
}

# ---------------------------------------------------------------
# 6. Checkpoint
# ---------------------------------------------------------------
saveDesign "${OUT_DIR}/uart_top_cts.enc"

puts "INFO: CTS stage complete."
puts "INFO: Review ${CTS_DIR}/${init_top_cell}_skew_group.rpt for achieved skew vs 1.0ns target"
puts "INFO: Review ${CTS_DIR}/${init_top_cell}_post_cts_timing.rpt for propagated-clock WNS/TNS"
puts "INFO: Next step -> routing"
