//=============================================================================
// Project      : Design and Verification of Synchronous FIFO
// File         : sync_fifo.v
// Author       : VLSI Design Team
// Version      : 1.0
// Date         : 2025
//
// Description  : Synchronous FIFO (First In, First Out) Memory Buffer
//                - Single clock domain for read and write operations
//                - Parameterizable data width and depth
//                - Status flags: full, empty, write_en, read_en
//                - Synthesizable RTL — targets FPGA and ASIC flows
//
// Parameters   :
//   DATA_WIDTH : Width of each data word         (default: 8 bits)
//   DEPTH      : Number of storage locations      (default: 16)
//   ADDR_WIDTH : Address bits = log2(DEPTH)       (default: 4)
//
// Ports        :
//   clk        : System clock (single clock for both read and write)
//   rst_n      : Active-low synchronous reset
//   wr_en      : Write enable — high to write data into FIFO
//   rd_en      : Read enable  — high to read data from FIFO
//   data_in    : Data input bus
//   data_out   : Data output bus
//   full       : High when FIFO is full  (write should not occur)
//   empty      : High when FIFO is empty (read should not occur)
//   wr_ack     : Write acknowledge — confirms successful write
//   rd_valid   : Read valid — confirms read data is valid on data_out
//
// Working Principle:
//   Data is written to the location pointed by wr_ptr and read from
//   the location pointed by rd_ptr. Both pointers advance on valid
//   operations. FIFO is full when (wr_ptr+1 == rd_ptr) and empty
//   when (wr_ptr == rd_ptr). A count register tracks occupancy.
//=============================================================================

`timescale 1ns / 1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,           // Width of each data word
    parameter DEPTH      = 16,          // Number of FIFO locations
    parameter ADDR_WIDTH = 4            // = log2(DEPTH); must match DEPTH
)(
    //=========================================================================
    // Clock and Reset
    //=========================================================================
    input  wire                  clk,       // Single system clock
    input  wire                  rst_n,     // Active-low synchronous reset

    //=========================================================================
    // Write Port
    //=========================================================================
    input  wire                  wr_en,     // Write enable
    input  wire [DATA_WIDTH-1:0] data_in,   // Data to write into FIFO

    //=========================================================================
    // Read Port
    //=========================================================================
    input  wire                  rd_en,     // Read enable
    output reg  [DATA_WIDTH-1:0] data_out,  // Data read from FIFO

    //=========================================================================
    // Status Flags
    //=========================================================================
    output wire                  full,      // FIFO full flag
    output wire                  empty,     // FIFO empty flag
    output reg                   wr_ack,    // Write acknowledge (1-clk pulse)
    output reg                   rd_valid   // Read data valid  (1-clk pulse)
);

    //=========================================================================
    // Internal Memory Array
    //=========================================================================
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    //=========================================================================
    // Internal Pointers and Count
    //=========================================================================
    reg [ADDR_WIDTH-1:0] wr_ptr;     // Write pointer (next write location)
    reg [ADDR_WIDTH-1:0] rd_ptr;     // Read pointer  (next read location)
    reg [ADDR_WIDTH  :0] count;      // Number of valid entries (0 to DEPTH)

    //=========================================================================
    // Status Flag Generation (Combinational)
    //=========================================================================
    assign full  = (count == DEPTH);    // Full  when count reaches DEPTH
    assign empty = (count == 0);        // Empty when count is zero

    //=========================================================================
    // Write Operation
    //=========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            wr_ack <= 1'b0;
        end else begin
            wr_ack <= 1'b0;  // Default: no acknowledge
            if (wr_en && !full) begin
                mem[wr_ptr] <= data_in;                         // Store data
                wr_ptr      <= wr_ptr + 1'b1;                  // Advance pointer
                wr_ack      <= 1'b1;                            // Acknowledge write
            end
        end
    end

    //=========================================================================
    // Read Operation
    //=========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            rd_ptr   <= {ADDR_WIDTH{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
            rd_valid <= 1'b0;
        end else begin
            rd_valid <= 1'b0;  // Default: output not valid
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr];                        // Fetch data
                rd_ptr   <= rd_ptr + 1'b1;                     // Advance pointer
                rd_valid <= 1'b1;                               // Output is valid
            end
        end
    end

    //=========================================================================
    // Occupancy Counter
    //=========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            count <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count <= count + 1'b1;  // Write only
                2'b01:   count <= count - 1'b1;  // Read only
                2'b11:   count <= count;          // Simultaneous R+W: count unchanged
                default: count <= count;          // No operation
            endcase
        end
    end

    //=========================================================================
    // Simulation Assertions (ignored by synthesis)
    //=========================================================================
    // synthesis translate_off
    always @(posedge clk) begin
        if (rst_n) begin
            if (wr_en && full)
                $display("[WARNING] %0t | FIFO OVERFLOW  attempted — write ignored", $time);
            if (rd_en && empty)
                $display("[WARNING] %0t | FIFO UNDERFLOW attempted — read ignored", $time);
        end
    end
    // synthesis translate_on

endmodule
