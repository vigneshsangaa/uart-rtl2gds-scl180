// =============================================================
// Module      : uart_rx
// Description : UART Receiver.
//               rx_serial is asynchronous to clk (it comes from an
//               external device) -- this is the genuine CDC hazard
//               in a UART design. We pass it through a 2-flop
//               synchronizer before any logic touches it, to avoid
//               metastability.
//               After sync, we use 16x oversampling to find the
//               middle of each bit (tick count == 7 or 8) for a
//               reliable, noise-tolerant sample point.
// =============================================================

module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire        baud_tick_16x,
    input  wire        rx_serial,       // ASYNC input from external line
    output reg  [7:0]  rx_data,
    output reg          rx_done,         // 1-cycle pulse: valid byte on rx_data
    output reg          parity_error,    // 1-cycle pulse: parity mismatch
    output reg          framing_error    // 1-cycle pulse: stop bit not seen as 1
);

    // ---------------------------------------------------------
    // CDC: 2-flop synchronizer for the async serial input
    // ---------------------------------------------------------
    reg rx_sync_ff1, rx_sync_ff2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync_ff1 <= 1'b1;
            rx_sync_ff2 <= 1'b1;
        end else begin
            rx_sync_ff1 <= rx_serial;   // 1st flop: may go metastable
            rx_sync_ff2 <= rx_sync_ff1; // 2nd flop: resolved, safe to use
        end
    end

    wire rx_sync = rx_sync_ff2;   // synchronized, glitch-free RX line

    // ---------------------------------------------------------
    // RX FSM
    // ---------------------------------------------------------
    localparam IDLE   = 3'd0,
               START   = 3'd1,
               DATA    = 3'd2,
               PARITY  = 3'd3,
               STOP    = 3'd4;

    reg [2:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_idx;
    reg [7:0] data_reg;
    reg       parity_calc;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            tick_cnt      <= 0;
            bit_idx       <= 0;
            data_reg      <= 8'h00;
            rx_data       <= 8'h00;
            rx_done       <= 1'b0;
            parity_error  <= 1'b0;
            framing_error <= 1'b0;
            parity_calc   <= 1'b0;
        end else begin

            rx_done       <= 1'b0;   // default: 1-cycle pulses
            parity_error  <= 1'b0;
            framing_error <= 1'b0;

            case (state)

                IDLE: begin
                    tick_cnt <= 0;
                    bit_idx  <= 0;
                    if (rx_sync == 1'b0) begin
                        // possible start bit detected, begin verifying
                        state <= START;
                    end
                end

                START: begin
                    if (baud_tick_16x) begin
                        if (tick_cnt == 7) begin
                            // sample at mid-bit: confirm it's really a start bit
                            if (rx_sync == 1'b0) begin
                                tick_cnt <= tick_cnt + 1;
                            end else begin
                                state    <= IDLE;   // false start (glitch), abort
                                tick_cnt <= 0;
                            end
                        end else if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= DATA;
                        end else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                DATA: begin
                    if (baud_tick_16x) begin
                        if (tick_cnt == 7) begin
                            // mid-bit sample point
                            data_reg[bit_idx] <= rx_sync;
                            tick_cnt <= tick_cnt + 1;
                        end else if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            if (bit_idx == 7) begin
                                bit_idx <= 0;
                                state   <= PARITY;
                            end else
                                bit_idx <= bit_idx + 1;
                        end else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                PARITY: begin
                    if (baud_tick_16x) begin
                        if (tick_cnt == 7) begin
                            parity_calc <= rx_sync;  // received parity bit
                            tick_cnt <= tick_cnt + 1;
                        end else if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= STOP;
                        end else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                STOP: begin
                    if (baud_tick_16x) begin
                        if (tick_cnt == 7) begin
                            // mid-bit sample of stop bit -- should be 1
                            if (rx_sync != 1'b1)
                                framing_error <= 1'b1;

                            if ((^data_reg) != parity_calc)
                                parity_error <= 1'b1;

                            rx_data <= data_reg;
                            rx_done <= 1'b1;
                            tick_cnt <= tick_cnt + 1;
                        end else if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= IDLE;
                        end else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
