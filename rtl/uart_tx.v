// =============================================================
// Module      : uart_tx
// Description : UART Transmitter.
//               Frame format: 1 start bit (0) + 8 data bits (LSB
//               first) + 1 even parity bit + 1 stop bit (1).
//               Runs off the 16x baud tick from baud_gen — counts
//               16 ticks per bit period.
// =============================================================

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire        baud_tick_16x,
    input  wire        tx_start,       // pulse to begin a new transmission
    input  wire [7:0]  tx_data,        // byte to send
    output reg          tx_serial,      // serial output line (idles high)
    output reg          tx_busy         // high while a frame is in progress
);

    // FSM states
    localparam IDLE   = 3'd0,
               START   = 3'd1,
               DATA    = 3'd2,
               PARITY  = 3'd3,
               STOP    = 3'd4;

    reg [2:0] state;
    reg [3:0] tick_cnt;   // counts 0-15 within each bit period
    reg [2:0] bit_idx;    // which data bit (0-7) is being sent
    reg [7:0] data_reg;
    reg       parity_bit;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            tx_serial  <= 1'b1;   // idle = high
            tx_busy    <= 1'b0;
            tick_cnt   <= 0;
            bit_idx    <= 0;
            data_reg   <= 8'h00;
            parity_bit <= 1'b0;
        end else begin
            case (state)

                IDLE: begin
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                    tick_cnt  <= 0;
                    bit_idx   <= 0;
                    if (tx_start) begin
                        data_reg   <= tx_data;
                        parity_bit <= ^tx_data;  // even parity = XOR of all data bits
                        tx_busy    <= 1'b1;
                        state      <= START;
                    end
                end

                START: begin
                    tx_serial <= 1'b0;   // start bit
                    if (baud_tick_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= DATA;
                        end else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                DATA: begin
                    tx_serial <= data_reg[bit_idx];  // LSB first
                    if (baud_tick_16x) begin
                        if (tick_cnt == 15) begin
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
                    tx_serial <= parity_bit;
                    if (baud_tick_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            state    <= STOP;
                        end else
                            tick_cnt <= tick_cnt + 1;
                    end
                end

                STOP: begin
                    tx_serial <= 1'b1;   // stop bit
                    if (baud_tick_16x) begin
                        if (tick_cnt == 15) begin
                            tick_cnt <= 0;
                            tx_busy  <= 1'b0;
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
