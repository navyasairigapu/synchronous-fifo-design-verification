//=============================================================================
// Project      : Design and Verification of Synchronous FIFO
// File         : tb_sync_fifo.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
//
// Description  : Self-Checking Testbench for Synchronous FIFO
//
// Test Scenarios:
//   TC-01 : Reset Verification          — all flags/outputs clear after reset
//   TC-02 : Single Write                — write one word, verify wr_ack
//   TC-03 : Single Read                 — read back word, verify rd_valid & data
//   TC-04 : Empty Flag                  — empty asserts when last word read
//   TC-05 : Fill to Full                — write until full flag asserts
//   TC-06 : Full Flag                   — verify no more writes accepted when full
//   TC-07 : Drain from Full             — read all words, verify order (FIFO order)
//   TC-08 : Simultaneous Read & Write   — wr_en + rd_en at same time, count stable
//   TC-09 : Overflow Attempt            — write to full FIFO, data must not corrupt
//   TC-10 : Underflow Attempt           — read from empty FIFO, no invalid data
//   TC-11 : Consecutive Writes          — burst write sequence, verify count
//   TC-12 : Consecutive Reads           — burst read sequence, verify data order
//   TC-13 : Alternating Write/Read      — interleaved single ops
//   TC-14 : Write Enable De-asserted    — wr_en=0 should not change FIFO state
//   TC-15 : Read Enable De-asserted     — rd_en=0 should not change FIFO state
//=============================================================================

`timescale 1ns / 1ps

module tb_sync_fifo;

    //=========================================================================
    // Parameters (must match DUT)
    //=========================================================================
    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;
    localparam ADDR_WIDTH = 4;
    localparam CLK_PERIOD = 10;     // 100 MHz

    //=========================================================================
    // DUT Signal Declarations
    //=========================================================================
    reg                  clk;
    reg                  rst_n;
    reg                  wr_en;
    reg                  rd_en;
    reg  [DATA_WIDTH-1:0] data_in;

    wire [DATA_WIDTH-1:0] data_out;
    wire                  full;
    wire                  empty;
    wire                  wr_ack;
    wire                  rd_valid;

    //=========================================================================
    // Scoreboard
    //=========================================================================
    integer pass_cnt = 0;
    integer fail_cnt = 0;
    integer tc       = 0;

    //=========================================================================
    // Reference Model — simple queue using array
    //=========================================================================
    reg [DATA_WIDTH-1:0] ref_queue [0:DEPTH-1];
    integer ref_head = 0;   // Read pointer
    integer ref_tail = 0;   // Write pointer
    integer ref_cnt  = 0;   // Occupancy

    //=========================================================================
    // DUT Instantiation
    //=========================================================================
    sync_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .DEPTH      (DEPTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) DUT (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .data_in  (data_in),
        .rd_en    (rd_en),
        .data_out (data_out),
        .full     (full),
        .empty    (empty),
        .wr_ack   (wr_ack),
        .rd_valid (rd_valid)
    );

    //=========================================================================
    // Clock Generation — 100 MHz
    //=========================================================================
    initial clk = 1'b0;
    always  #(CLK_PERIOD/2) clk = ~clk;

    //=========================================================================
    // VCD Dump
    //=========================================================================
    initial begin
        $dumpfile("sim/sync_fifo_waves.vcd");
        $dumpvars(0, tb_sync_fifo);
    end

    //=========================================================================
    // TASK: apply_reset
    //=========================================================================
    task apply_reset;
        begin
            rst_n   = 1'b0;
            wr_en   = 1'b0;
            rd_en   = 1'b0;
            data_in = {DATA_WIDTH{1'b0}};
            ref_head = 0; ref_tail = 0; ref_cnt = 0;
            repeat(4) @(posedge clk);
            #1;
            rst_n = 1'b1;
            @(posedge clk); #1;
        end
    endtask

    //=========================================================================
    // TASK: fifo_write
    //=========================================================================
    task fifo_write;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            wr_en   = 1'b1;
            data_in = data;
            @(posedge clk); #1;
            if (wr_ack) begin
                // Update reference model
                ref_queue[ref_tail] = data;
                ref_tail = (ref_tail + 1) % DEPTH;
                ref_cnt  = ref_cnt + 1;
            end
            wr_en   = 1'b0;
            data_in = {DATA_WIDTH{1'b0}};
        end
    endtask

    //=========================================================================
    // TASK: fifo_read
    //=========================================================================
    task fifo_read;
        output [DATA_WIDTH-1:0] got;
        begin
            @(negedge clk);
            rd_en = 1'b1;
            @(posedge clk); #1;
            got   = data_out;
            rd_en = 1'b0;
        end
    endtask

    //=========================================================================
    // TASK: check_data
    //=========================================================================
    task check_data;
        input [DATA_WIDTH-1:0] expected;
        input [DATA_WIDTH-1:0] actual;
        input [63:0]           test_id;
        begin
            if (expected === actual) begin
                $display("[PASS] TC-%02d | Expected=0x%02h  Got=0x%02h", test_id, expected, actual);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] TC-%02d | Expected=0x%02h  Got=0x%02h  *** MISMATCH ***", test_id, expected, actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    //=========================================================================
    // TASK: check_flag
    //=========================================================================
    task check_flag;
        input        expected;
        input        actual;
        input [79:0] flag_name;
        input [63:0] test_id;
        begin
            if (expected === actual) begin
                $display("[PASS] TC-%02d | %s = %b (correct)", test_id, flag_name, actual);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("[FAIL] TC-%02d | %s Expected=%b Got=%b *** ERROR ***", test_id, flag_name, expected, actual);
                fail_cnt = fail_cnt + 1;
            end
        end
    endtask

    //=========================================================================
    // MAIN TEST SEQUENCE
    //=========================================================================
    reg [DATA_WIDTH-1:0] rd_data;
    integer i;

    initial begin
        $display("\n================================================================");
        $display("  Synchronous FIFO — Functional Verification Suite");
        $display("  Depth=%0d  Width=%0d  Clock=100MHz", DEPTH, DATA_WIDTH);
        $display("================================================================\n");

        //----------------------------------------------------------------------
        // TC-01: Reset Verification
        //----------------------------------------------------------------------
        $display("--- TC-01: Reset Verification ---");
        apply_reset;
        check_flag(1'b1, empty,   "empty  ", 1);
        check_flag(1'b0, full,    "full   ", 1);
        check_flag(1'b0, wr_ack,  "wr_ack ", 1);
        check_flag(1'b0, rd_valid,"rd_valid",1);

        //----------------------------------------------------------------------
        // TC-02: Single Write
        //----------------------------------------------------------------------
        $display("\n--- TC-02: Single Write [data=0xA5] ---");
        fifo_write(8'hA5);
        check_flag(1'b1, wr_ack, "wr_ack ", 2);
        check_flag(1'b0, empty,  "empty  ", 2);
        check_flag(1'b0, full,   "full   ", 2);

        //----------------------------------------------------------------------
        // TC-03: Single Read
        //----------------------------------------------------------------------
        $display("\n--- TC-03: Single Read [expect=0xA5] ---");
        fifo_read(rd_data);
        check_flag(1'b1, rd_valid, "rd_valid", 3);
        check_data(8'hA5, rd_data, 3);
        check_flag(1'b1, empty, "empty  ", 3);

        //----------------------------------------------------------------------
        // TC-04: Empty Flag after full drain
        //----------------------------------------------------------------------
        $display("\n--- TC-04: Empty Flag Verification ---");
        check_flag(1'b1, empty, "empty  ", 4);

        //----------------------------------------------------------------------
        // TC-05: Fill FIFO to Full
        //----------------------------------------------------------------------
        $display("\n--- TC-05: Fill FIFO to Full [write %0d words] ---", DEPTH);
        for (i = 1; i <= DEPTH; i = i + 1) begin
            fifo_write(i[7:0]);
        end
        check_flag(1'b1, full,  "full   ", 5);
        check_flag(1'b0, empty, "empty  ", 5);

        //----------------------------------------------------------------------
        // TC-06: Overflow Attempt (write to full FIFO)
        //----------------------------------------------------------------------
        $display("\n--- TC-06: Overflow Attempt [write when full] ---");
        @(negedge clk);
        wr_en   = 1'b1;
        data_in = 8'hFF;
        @(posedge clk); #1;
        check_flag(1'b0, wr_ack, "wr_ack ", 6);  // Must NOT acknowledge
        check_flag(1'b1, full,   "full   ", 6);   // Must stay full
        wr_en = 1'b0;

        //----------------------------------------------------------------------
        // TC-07: Drain FIFO — verify FIFO (in-order) read
        //----------------------------------------------------------------------
        $display("\n--- TC-07: Drain FIFO and Verify FIFO Order ---");
        for (i = 1; i <= DEPTH; i = i + 1) begin
            fifo_read(rd_data);
            check_data(i[7:0], rd_data, 7);
        end
        check_flag(1'b1, empty, "empty  ", 7);

        //----------------------------------------------------------------------
        // TC-08: Simultaneous Read and Write
        //----------------------------------------------------------------------
        $display("\n--- TC-08: Simultaneous Read & Write ---");
        fifo_write(8'hBB);  // Pre-load one entry
        @(negedge clk);
        wr_en   = 1'b1;
        rd_en   = 1'b1;
        data_in = 8'hCC;
        @(posedge clk); #1;
        check_flag(1'b1, wr_ack,   "wr_ack ", 8);
        check_flag(1'b1, rd_valid, "rd_valid",8);
        check_data(8'hBB, data_out, 8);  // BB should come out (FIFO order)
        wr_en = 1'b0;
        rd_en = 1'b0;
        // Drain the CC that was written
        fifo_read(rd_data);
        check_data(8'hCC, rd_data, 8);

        //----------------------------------------------------------------------
        // TC-09: Underflow Attempt (read from empty FIFO)
        //----------------------------------------------------------------------
        $display("\n--- TC-09: Underflow Attempt [read when empty] ---");
        check_flag(1'b1, empty, "empty  ", 9);
        @(negedge clk);
        rd_en = 1'b1;
        @(posedge clk); #1;
        check_flag(1'b0, rd_valid, "rd_valid", 9);  // Must NOT be valid
        check_flag(1'b1, empty,    "empty  ",  9);   // Must stay empty
        rd_en = 1'b0;

        //----------------------------------------------------------------------
        // TC-10: Burst Write then Burst Read — data integrity check
        //----------------------------------------------------------------------
        $display("\n--- TC-10: Burst Write + Burst Read [8 words] ---");
        for (i = 0; i < 8; i = i + 1)
            fifo_write(8'h10 + i[7:0]);
        for (i = 0; i < 8; i = i + 1) begin
            fifo_read(rd_data);
            check_data(8'h10 + i[7:0], rd_data, 10);
        end

        //----------------------------------------------------------------------
        // TC-11: Alternating Write / Read
        //----------------------------------------------------------------------
        $display("\n--- TC-11: Alternating Write/Read [4 cycles] ---");
        for (i = 0; i < 4; i = i + 1) begin
            fifo_write(8'hD0 + i[7:0]);
            fifo_read(rd_data);
            check_data(8'hD0 + i[7:0], rd_data, 11);
        end

        //----------------------------------------------------------------------
        // TC-12: Write Enable Deasserted — FIFO state unchanged
        //----------------------------------------------------------------------
        $display("\n--- TC-12: wr_en=0, no write should occur ---");
        fifo_write(8'h42);   // Write one known value
        @(negedge clk);
        wr_en   = 1'b0;      // Deassert write enable
        data_in = 8'hFF;     // Different data presented
        @(posedge clk); #1;
        check_flag(1'b0, wr_ack, "wr_ack ", 12);
        // Read back — should get 0x42, not 0xFF
        fifo_read(rd_data);
        check_data(8'h42, rd_data, 12);

        //----------------------------------------------------------------------
        // TC-13: Read Enable Deasserted — output unchanged
        //----------------------------------------------------------------------
        $display("\n--- TC-13: rd_en=0, no read should occur ---");
        fifo_write(8'hAB);
        @(negedge clk);
        rd_en = 1'b0;
        @(posedge clk); #1;
        check_flag(1'b0, rd_valid, "rd_valid", 13);
        check_flag(1'b0, empty,    "empty  ",  13);  // Data still in FIFO
        // Clean up
        fifo_read(rd_data);

        //----------------------------------------------------------------------
        // TC-14: Back-to-back writes across wrap (pointer rollover)
        //----------------------------------------------------------------------
        $display("\n--- TC-14: Pointer Wrap-Around Test ---");
        // Fill 16, drain 8, fill 8 more — forces pointer wrap
        for (i = 0; i < 8; i = i + 1) fifo_write(8'hE0 + i[7:0]);
        for (i = 0; i < 8; i = i + 1) fifo_read(rd_data);
        for (i = 0; i < 8; i = i + 1) fifo_write(8'hF0 + i[7:0]);
        for (i = 0; i < 8; i = i + 1) begin
            fifo_read(rd_data);
            check_data(8'hF0 + i[7:0], rd_data, 14);
        end
        check_flag(1'b1, empty, "empty  ", 14);

        //----------------------------------------------------------------------
        // TC-15: All-zeros and All-ones Data Patterns
        //----------------------------------------------------------------------
        $display("\n--- TC-15: Data Pattern Test [0x00 and 0xFF] ---");
        fifo_write(8'h00);
        fifo_read(rd_data);
        check_data(8'h00, rd_data, 15);
        fifo_write(8'hFF);
        fifo_read(rd_data);
        check_data(8'hFF, rd_data, 15);

        //----------------------------------------------------------------------
        // FINAL SUMMARY
        //----------------------------------------------------------------------
        repeat(5) @(posedge clk);
        $display("\n================================================================");
        $display("  VERIFICATION COMPLETE");
        $display("  Total Checks : %0d", pass_cnt + fail_cnt);
        $display("  PASSED       : %0d", pass_cnt);
        $display("  FAILED       : %0d", fail_cnt);
        if (fail_cnt == 0)
            $display("  STATUS       : *** ALL TESTS PASSED — DESIGN VERIFIED ***");
        else
            $display("  STATUS       : *** %0d FAILURE(S) — REVIEW REQUIRED ***", fail_cnt);
        $display("================================================================\n");
        $finish;
    end

    //=========================================================================
    // Timeout Watchdog
    //=========================================================================
    initial begin
        #2_000_000;
        $display("[TIMEOUT] Simulation exceeded time limit. Forcing stop.");
        $finish;
    end

endmodule
