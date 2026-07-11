(globals
 version = 3
 io_order = default
)
(iopad
 (bottom
  (inst name ="u_pad_clk" space = 20 place_status=fixed )
  (inst name ="u_clkbuf" space = 20 place_status=fixed )
  (inst name ="u_pad_rst_n" space = 20 place_status=fixed )
  (inst name ="u_pad_tx_start" space = 20 place_status=fixed )
  (inst name ="u_pad_rx_serial" space = 20 place_status=fixed )
  (inst name ="pvdi_VDD_CORE_1" space = 20 place_status=fixed )
  (inst name ="pv0i_VSS_CORE_1" space = 20 place_status=fixed )
  (inst name ="pvda_VDDO_CORE_1" space = 20 place_status=fixed )
  (inst name ="pv0a_VSSO_CORE_1" space = 20 place_status=fixed )
 )
 (right
  (inst name="g_tx_data_pads[0].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[1].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[2].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[3].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[4].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[5].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[6].u_pad_tx_data" space = 20 place_status=fixed )
  (inst name="g_tx_data_pads[7].u_pad_tx_data" space = 20 place_status=fixed )
 )
 (top
  (inst name="g_rx_data_pads[0].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[1].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[2].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[3].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[4].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[5].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[6].u_pad_rx_data" space = 20 place_status=fixed )
  (inst name="g_rx_data_pads[7].u_pad_rx_data" space = 20 place_status=fixed )
 )
 (left
  (inst name="u_pad_tx_busy" space = 20 place_status=fixed )
  (inst name="u_pad_rx_done" space = 20 place_status=fixed )
  (inst name="u_pad_tx_serial" space = 20 place_status=fixed )
  (inst name="u_pad_parity_error" space = 20 place_status=fixed )
  (inst name="u_pad_framing_error" space = 20 place_status=fixed )
  (inst name="pvdi_VDD_CORE_2" space = 20 place_status=fixed )
  (inst name="pv0i_VSS_CORE_2" space = 20 place_status=fixed )
  (inst name="pvda_VDDO_CORE_2" space = 20 place_status=fixed )
  (inst name="pv0a_VSSO_CORE_2" space = 20 place_status=fixed )
 )
 (topright
  (inst name="corner_3"
   cell = pfrelr
   place_status = fixed
   orientation = R90
  )
 )
 (topleft
  (inst name="corner_4"
   cell = pfrelr
   place_status = fixed
   orientation = R180
  )
 )
 (bottomright
  (inst name="corner_2"
   cell = pfrelr
   place_status = fixed
   orientation = R0
  )
 )
 (bottomleft
  (inst name="corner_1"
   cell = pfrelr
   place_status = fixed
   orientation = R270
  )
 )
)
