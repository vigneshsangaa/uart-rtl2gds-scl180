module baud_gen #(
    parameter CLK_FREQ  = 50_000_000,   // system clock frequency (Hz)
    parameter BAUD_RATE = 9600           // desired baud rate
) (
    input  wire clk,
    input  wire rst_n,        // active-low async reset
    output reg  baud_tick_16x // 1-cycle pulse at 16x baud rate
);

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
