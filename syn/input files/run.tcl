###############################################################################
set DESIGN uart_top_pad
set GEN_EFF medium
set MAP_OPT_EFF high
set clockname clk
set DATE [clock format [clock seconds] -format "%b%d-%T"]
set _OUTPUTS_PATH output_files
set _REPORTS_PATH report_files
set _LOG_PATH logs_${DATE}

set_db / .init_lib_search_path { \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/liberty \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/iolib }

set_db / .script_search_path {. ./Scripts}

set_db auto_ungroup none

##Uncomment and specify machine names to enable super-threading.
##set_db / .super_thread_servers {<machine names>}
##For design size of 1.5M - 5M gates, use 8 to 16 CPUs. For designs > 5M gates, use 16 to 32 CPUs
##set_db / .max_cpus_per_server 8

##Default undriven/unconnected setting is 'none'.
##set_db / .hdl_unconnected_value 0 | 1 | x | none

set_db / .information_level 7

###############################################################
## Library setup
###############################################################

set_db / .library { \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/liberty/tsl18fs120_scl_ss.lib \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/iolib/tsl18cio150_max.lib \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/liberty/tsl18fs120_scl_ff.lib \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/iolib/tsl18cio150_min.lib }

#set_db / .lef_library {../lef/tsl18fs120_scl.lef}

read_libs -max_libs { \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/liberty/tsl18fs120_scl_ss.lib \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/iolib/tsl18cio150_max.lib } \
    -min_libs { \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/liberty/tsl18fs120_scl_ff.lib \
    /home/msdlab/Desktop/Intern_Vignesh/03_UART_SYNTHESIS/iolib/tsl18cio150_min.lib }

####################################################################
## Load Design
####################################################################

puts "load RTL"
set FILE_LIST {baud_gen.v uart_tx.v uart_rx.v uart_top.v uart_top_pad.v}
read_hdl $FILE_LIST

puts "elaborate design"
elaborate $DESIGN
puts "Runtime & Memory after 'read_hdl'"
time_info Elaboration
check_design -unresolved

####################################################################
## Constraints Setup
####################################################################
read_sdc constraints.sdc
path_adjust -from [all_inputs] -to [all_outputs] -delay -1300 -name PA_I2O
path_adjust -from [all_inputs] -to [all_register] -delay -1500 -name PA_I2C
path_adjust -from [all_register] -to [all_outputs] -delay -1500 -name PA_C2O
path_adjust -from [all_register] -to [all_register] -delay -1500 -name PA_C2C

report_timing -lint -verbose

puts "The number of exceptions is [llength [vfind "design:$DESIGN" -exception *]]"

if {![file exists ${_OUTPUTS_PATH}]} {
    file mkdir ${_OUTPUTS_PATH}
    puts "Creating directory ${_OUTPUTS_PATH}"
    }

if {![file exists ${_REPORTS_PATH}]} {
    file mkdir ${_REPORTS_PATH}
    puts "Creating directory ${_REPORTS_PATH}"
    }

set_db lp_power_analysis_effort high

##################################################################################
## Synthesizing to generic
##################################################################################

set_db / .syn_generic_effort $GEN_EFF
syn_generic
puts "Runtime & Memory after 'syn_generic'"
time_info GENERIC
report_dp > $_REPORTS_PATH/generic/${DESIGN}_datapath.rpt
write_snapshot -outdir $_REPORTS_PATH -tag generic
report_summary -directory $_REPORTS_PATH
write_hdl > ${_OUTPUTS_PATH}/${DESIGN}_generic.v
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}_generic.sdc
#break

##################################################################################
## Synthesizing to gates
##################################################################################
set_db / .syn_map_effort $MAP_OPT_EFF
syn_map
puts "Runtime & Memory after 'syn_map'"
time_info MAPPED
write_snapshot -outdir $_REPORTS_PATH -tag map
report_summary -directory $_REPORTS_PATH
report_dp > $_REPORTS_PATH/map/${DESIGN}_datapath.rpt
write_hdl > ${_OUTPUTS_PATH}/${DESIGN}_map.v
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}_map.sdc

write_do_lec -revised_design fv_map -logfile ${_LOG_PATH}/rtl2intermediate.lec.log > ${_OUTPUTS_PATH}/rtl2intermediate.lec.do

##################################################################################
## Optimize Netlist
##################################################################################

set_db / .syn_opt_effort $MAP_OPT_EFF
syn_opt
write_snapshot -outdir $_REPORTS_PATH -tag syn_opt
report_summary -directory $_REPORTS_PATH

puts "Runtime & Memory after 'syn_opt'"
time_info OPT

write_snapshot -outdir $_REPORTS_PATH -tag final
report_summary -directory $_REPORTS_PATH
write_hdl > ${_OUTPUTS_PATH}/${DESIGN}_incremental.v
## write_script > ${_OUTPUTS_PATH}/${DESIGN}_m.script
write_sdc > ${_OUTPUTS_PATH}/${DESIGN}_incremental.sdc

###### SDF file Generation ############
write_sdf -version 2.1 -recrem split -setuphold merge_when_paired -edges check_edge > ${_OUTPUTS_PATH}/uart_top_pad_synth.sdf

#################################
### write_do_lec
#################################
write_do_lec -golden_design fv_map -revised_design ${_OUTPUTS_PATH}/${DESIGN}_incremental.v -logfile ${_LOG_PATH}/intermediate2final.lec.log > ${_OUTPUTS_PATH}/intermediate2final.lec.do

##Uncomment if the RTL is to be compared with the final netlist..
#write_do_lec -revised_design fv_map -logfile ${_LOG_PATH}/rtl2intermediate.lec.log > ${_OUTPUTS_PATH}/rtl2intermediate.lec.do

puts "Final Runtime & Memory."
time_info FINAL
puts "============================"

puts "Synthesis Finished ........."
puts "============================"
