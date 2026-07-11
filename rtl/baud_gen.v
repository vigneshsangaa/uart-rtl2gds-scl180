// =============================================================
// Module      : baud_gen
// Description : Generates a baud tick pulse at 16x the baud rate.
//               16x oversampling is standard in UART design — it
//               lets the RX module sample the middle of each bit
//               for reliable detection instead of sampling right
//               at the edge.
// =============================================================

module baud_gen #(
    parameter CLK_FREQ  = 50_000_000,   // system clock frequency (Hz)
    parameter BAUD_RATE = 9600           // desired baud rate
) (
    input  wire clk,
    input  wire rst_n,        // active-low async reset
    output reg  baud_tick_16x // 1-cycle pulse at 16x baud rate
);

    // Divisor for 16x oversampling clock
    localparam integer DIVISOR = CLK_FREQ / (BAUD_RATE * 16);

    reg [$clog2(DIVISOR)-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count          <= 0;
            baud_tick_16x  <= 1'b0;
        end else if (count == DIVISOR - 1) begin
            count          <= 0;
            baud_tick_16x  <= 1'b1;   // pulse high for exactly 1 clk cycle
        end else begin
            count          <= count + 1;
            baud_tick_16x  <= 1'b0;
        end
    end

endmodule
