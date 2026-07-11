// =============================================================
// Module      : uart_top_pad
// Description : 
//		Pad cell -> port mapping used (per your spec):
//                 clk                                   : pc3d01 + pc3c01
//                 rst_n, tx_start, rx_serial, tx_data[*] : pc3d01
//                 tx_serial, rx_data[*]                  : pc3o01..pc3o05
//                                                          (drive strength
//                                                          selectable per load)
//                 tx_busy, rx_done,
//                 parity_error, framing_error             : pc3o01
//                 Power/Ground                            : pvdi, pv0i,
//                                                            pvda, pv0a
//
// LIBRARY PIN NAMES — confirmed against the TSL18CIO150 datasheet :
//     Input pad          (pc3d01)  : .PAD (chip pin)  .CIN (core-side output)
//     Input pad w/ pullup(pc3d01u) : .PAD (chip pin)  .CIN (core-side output)
//     Output pad         (pc3o0x)  : .PAD (chip pin)  .I   (core-side input)
//                                    (no OEN -- these are non-tristate output
//                                     pads; OEN only exists on pc3b0x/pc3t0x)
//     Clock buffer       (pc3c01)  : .CCLK (input, from on-die net)
//                                    .CP   (output, buffered clock to core)
//                                    "core-driven" per datasheet Sec 2.58 --
//                                    it re-buffers a clock signal already
//                                    brought on-die by an input pad; it does
//                                    NOT connect directly to the chip pin.
//     Power pads (pvdi/pvda/pv0i/pv0a): no signal pins -- pure supply cells,
//                                    tied to the power/ground rings during
//                                    floorplanning, not wired as ports here.
//   rst_n uses pc3d01u (pull-up variant) rather than plain pc3d01, since an
//   active-low reset pin must not float to an undefined level before the
//   external reset source drives it.
//==============================

module uart_top_pad #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
) (
    // ---------------------------------------------------------
    // Chip-level (package) pins
    // ---------------------------------------------------------
    input  wire       CLK_PAD,
    input  wire       RST_N_PAD,

    input  wire        TX_START_PAD,
    input  wire [7:0]  TX_DATA_PAD,
    output wire        TX_BUSY_PAD,

    output wire [7:0]  RX_DATA_PAD,
    output wire        RX_DONE_PAD,
    output wire        PARITY_ERROR_PAD,
    output wire        FRAMING_ERROR_PAD,

    output wire        TX_SERIAL_PAD,
    input  wire        RX_SERIAL_PAD
);

    // ---------------------------------------------------------
    // Core-side nets (between pads and uart_top)
    // ---------------------------------------------------------
    wire clk_core;         // buffered clock into the core
    wire rst_n_core;

    wire        tx_start_core;
    wire [7:0]  tx_data_core;
    wire        tx_busy_core;

    wire [7:0]  rx_data_core;
    wire        rx_done_core;
    wire        parity_error_core;
    wire        framing_error_core;

    wire        tx_serial_core;
    wire        rx_serial_core;

    // ===========================================================
    // 1. Clock pad + core clock buffer
    // ===========================================================
    wire clk_pad_to_buf;

    pc3d01 u_pad_clk (
        .PAD (CLK_PAD),
        .CIN (clk_pad_to_buf)
    );

    pc3c01 u_clkbuf (
        .CCLK (clk_pad_to_buf),
        .CP   (clk_core)
    );

    // ===========================================================
    // 2. Standard digital input pads (pc3d01)
    // ===========================================================
    // rst_n uses the pull-up variant (pc3d01u) so the reset net does not

    pc3d01u u_pad_rst_n (
        .PAD (RST_N_PAD),
        .CIN (rst_n_core)
    );

    pc3d01 u_pad_tx_start (
        .PAD (TX_START_PAD),
        .CIN (tx_start_core)
    );

    pc3d01 u_pad_rx_serial (
        .PAD (RX_SERIAL_PAD),
        .CIN (rx_serial_core)
    );

    genvar gi;
    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_tx_data_pads
            pc3d01 u_pad_tx_data (
                .PAD (TX_DATA_PAD[gi]),
                .CIN (tx_data_core[gi])
            );
        end
    endgenerate

    // ===========================================================
    // 3. Output pads for serial-side signals (pc3o01..pc3o05,
    //    drive strength selectable — defaulted to pc3o01 here)
    // ===========================================================
    pc3o01 u_pad_tx_serial (
        .PAD (TX_SERIAL_PAD),
        .I   (tx_serial_core)
    );

    generate
        for (gi = 0; gi < 8; gi = gi + 1) begin : g_rx_data_pads
            pc3o01 u_pad_rx_data (
                .PAD (RX_DATA_PAD[gi]),
                .I   (rx_data_core[gi])
            );
        end
    endgenerate

    // ===========================================================
    // 4. Output pads for low-speed status flags (pc3o01, 1x drive)
    // ===========================================================
    pc3o01 u_pad_tx_busy (
        .PAD (TX_BUSY_PAD),
        .I   (tx_busy_core)
    );

    pc3o01 u_pad_rx_done (
        .PAD (RX_DONE_PAD),
        .I   (rx_done_core)
    );

    pc3o01 u_pad_parity_error (
        .PAD (PARITY_ERROR_PAD),
        .I   (parity_error_core)
    );

    pc3o01 u_pad_framing_error (
        .PAD (FRAMING_ERROR_PAD),
        .I   (framing_error_core)
    );

    // ===========================================================
    // 6. Core instantiation
    // ===========================================================
    uart_top #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_uart_top (
        .clk           (clk_core),
        .rst_n         (rst_n_core),

        .tx_start      (tx_start_core),
        .tx_data       (tx_data_core),
        .tx_busy       (tx_busy_core),

        .rx_data       (rx_data_core),
        .rx_done       (rx_done_core),
        .parity_error  (parity_error_core),
        .framing_error (framing_error_core),

        .tx_serial     (tx_serial_core),
        .rx_serial     (rx_serial_core)
    );

endmodule
