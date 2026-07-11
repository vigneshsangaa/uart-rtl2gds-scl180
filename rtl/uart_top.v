// =============================================================
// Module      : uart_top
// Description : Top-level UART. Integrates baud generator,
//               transmitter, and receiver.
//
//               System interface (parallel side):
//                 tx_start / tx_data  -> initiate a send
//                 tx_busy             -> transmitter status
//                 rx_data / rx_done   -> received byte + valid pulse
//                 parity_error / framing_error -> RX error flags
//
//               Pin interface (serial side):
//                 tx_serial -> drives external RX pin
//                 rx_serial -> driven by external TX pin (ASYNC)
// =============================================================

module uart_top #(
    parameter CLK_FREQ  = 50_000_000,
    parameter BAUD_RATE = 9600
) (
    input  wire       clk,
    input  wire       rst_n,

    // Parallel / system-side interface
    input  wire        tx_start,
    input  wire [7:0]  tx_data,
    output wire        tx_busy,

    output wire [7:0]  rx_data,
    output wire        rx_done,
    output wire        parity_error,
    output wire        framing_error,

    // Serial / pin-side interface
    output wire        tx_serial,
    input  wire        rx_serial   // async external input
);

    wire baud_tick_16x;

    baud_gen #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) u_baud_gen (
        .clk           (clk),
        .rst_n         (rst_n),
        .baud_tick_16x (baud_tick_16x)
    );

    uart_tx u_uart_tx (
        .clk           (clk),
        .rst_n         (rst_n),
        .baud_tick_16x (baud_tick_16x),
        .tx_start      (tx_start),
        .tx_data       (tx_data),
        .tx_serial     (tx_serial),
        .tx_busy       (tx_busy)
    );

    uart_rx u_uart_rx (
        .clk           (clk),
        .rst_n         (rst_n),
        .baud_tick_16x (baud_tick_16x),
        .rx_serial     (rx_serial),
        .rx_data       (rx_data),
        .rx_done       (rx_done),
        .parity_error  (parity_error),
        .framing_error (framing_error)
    );

endmodule
