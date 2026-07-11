// =============================================================
// Module      : uart_tb
// Description : Self-checking testbench for uart_top.
//               Loopback test: tx_serial is wired directly to
//               rx_serial, so every byte sent through TX should
//               appear correctly on rx_data via RX.
//               Checks data correctness, parity_error, and
//               framing_error for every transaction.
// =============================================================

`timescale 1ns/1ps

module uart_tb;

    // ---------------------------------------------------------
    // Parameters (match DUT)
    // ---------------------------------------------------------
    localparam CLK_FREQ  = 50_000_000;
    localparam BAUD_RATE = 9600;
    localparam CLK_PERIOD = 20; // ns, for 50MHz

    // ---------------------------------------------------------
    // DUT signals
    // ---------------------------------------------------------
    reg        clk;
    reg        rst_n;
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_busy;

    wire [7:0] rx_data;
    wire       rx_done;
    wire       parity_error;
    wire       framing_error;

    wire       tx_serial;
    wire       rx_serial;

    // Loopback: TX output directly feeds RX input
    assign rx_serial = tx_serial;

    // ---------------------------------------------------------
    // Scoreboard / bookkeeping
    // ---------------------------------------------------------
    integer pass_count;
    integer fail_count;
    reg [7:0] expected_data;
    reg       expect_pending;

    // rx_done is a single-cycle pulse that can occur BEFORE tx_busy
    // falls (RX finishes its STOP bit slightly before TX deasserts
    // busy). A blocking `wait(rx_done==1)` issued after waiting on
    // tx_busy can therefore miss the pulse entirely and hang forever.
    // Fix: latch every rx_done pulse into a sticky flag + captured
    // data, using an edge-triggered always block, so the task can
    // safely check it later without racing the pulse.
    reg       rx_done_latched;
    reg [7:0] rx_data_latched;
    reg       parity_error_latched;
    reg       framing_error_latched;

    always @(posedge clk) begin
        if (!rst_n) begin
            rx_done_latched       <= 1'b0;
        end else if (rx_done) begin
            rx_done_latched       <= 1'b1;
            rx_data_latched       <= rx_data;
            parity_error_latched  <= parity_error;
            framing_error_latched <= framing_error;
        end
    end

    // ---------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------
    uart_top #(
        .CLK_FREQ  (CLK_FREQ),
        .BAUD_RATE (BAUD_RATE)
    ) dut (
        .clk           (clk),
        .rst_n         (rst_n),
        .tx_start      (tx_start),
        .tx_data       (tx_data),
        .tx_busy       (tx_busy),
        .rx_data       (rx_data),
        .rx_done       (rx_done),
        .parity_error  (parity_error),
        .framing_error (framing_error),
        .tx_serial     (tx_serial),
        .rx_serial     (rx_serial)
    );

    // ---------------------------------------------------------
    // Clock generation
    // ---------------------------------------------------------
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------------------------------------------------
    // Task: send one byte and check it comes back correctly
    // ---------------------------------------------------------
    task send_byte(input [7:0] data);
        begin
            expected_data   = data;
            expect_pending  = 1'b1;
            rx_done_latched = 1'b0;   // clear latch before starting new frame

            @(negedge clk);
            tx_data  = data;
            tx_start = 1'b1;
            @(negedge clk);
            tx_start = 1'b0;

            // Wait for tx_busy to clear (full frame transmitted).
            // rx_done may latch at any point during or even before
            // this -- that's fine, we check the latch afterward
            // instead of racing a live pulse.
            wait (tx_busy == 1'b0);

            // Now safely wait for the latched flag (sticky, can't
            // be missed) instead of the raw pulse.
            wait (rx_done_latched == 1'b1);
            @(negedge clk); // let outputs settle before sampling

            if (parity_error_latched)
                $display("[%0t] FAIL: parity_error asserted for data=0x%02h", $time, data);
            else if (framing_error_latched)
                $display("[%0t] FAIL: framing_error asserted for data=0x%02h", $time, data);
            else if (rx_data_latched !== expected_data) begin
                $display("[%0t] FAIL: sent=0x%02h received=0x%02h", $time, expected_data, rx_data_latched);
                fail_count = fail_count + 1;
            end else begin
                $display("[%0t] PASS: sent=0x%02h received=0x%02h", $time, expected_data, rx_data_latched);
                pass_count = pass_count + 1;
            end

            expect_pending = 1'b0;
        end
    endtask

    // ---------------------------------------------------------
    // Main stimulus
    // ---------------------------------------------------------
    integer i;
    reg [7:0] rand_byte;

    initial begin
        clk      = 1'b0;
        rst_n    = 1'b0;
        tx_start = 1'b0;
        tx_data  = 8'h00;
        pass_count = 0;
        fail_count = 0;
        expect_pending = 1'b0;

        // Hold reset for a few clocks
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
        repeat (5) @(negedge clk);

        $display("=========================================");
        $display(" UART Loopback Testbench Starting");
        $display("=========================================");

        // --- Directed tests: edge cases ---
        send_byte(8'h00);   // all zeros
        send_byte(8'hFF);   // all ones
        send_byte(8'hA5);   // alternating pattern
        send_byte(8'h5A);   // alternating pattern (inverted)
        send_byte(8'h01);   // single bit set (LSB)
        send_byte(8'h80);   // single bit set (MSB)

        // --- Back-to-back bytes (no gap between frames) ---
        send_byte(8'h3C);
        send_byte(8'hC3);

        // --- Random data tests ---
        for (i = 0; i < 10; i = i + 1) begin
            rand_byte = $random;
            send_byte(rand_byte);
        end

        // --- Summary ---
        $display("=========================================");
        $display(" TEST SUMMARY: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count == 0)
            $display(" RESULT: ALL TESTS PASSED");
        else
            $display(" RESULT: SOME TESTS FAILED");
        $display("=========================================");

        $finish;
    end

    // ---------------------------------------------------------
    // Safety timeout (in case a test hangs)
    // ---------------------------------------------------------
    initial begin
        #30_000_000; // 30 ms simulated time -- generous margin for ~21 bytes at ~1.15ms each
        $display("[%0t] ERROR: Testbench timeout -- simulation hung", $time);
        $finish;
    end

    // ---------------------------------------------------------
    // Waveform dump for SimVision
    // ---------------------------------------------------------
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule
