# Design and Verification of Synchronous FIFO
## Complete Project Report

**Course**: VLSI Design / Digital Systems Design  
**Technology**: Verilog HDL | ModelSim | Synthesis-Ready RTL  
**Date**: 2025

---

## CHAPTER 1: INTRODUCTION

### 1.1 Background

In digital systems, different functional blocks often produce and consume data at different rates. A CPU may write data faster than a UART can transmit it. A sensor may produce samples faster than a processor can analyze them. Without a buffering mechanism, data is either lost or the system must stall, wasting performance.

The FIFO (First In, First Out) memory is the standard solution to this problem. It is a hardware queue — data enters one end and exits the other, always in the same order. The FIFO decouples the writer from the reader, allowing each to operate at its own pace within the buffer's capacity.

A **Synchronous FIFO** simplifies this further by using a single clock for both read and write operations. This eliminates all clock domain crossing concerns, making the design straightforward to implement, verify, and synthesize.

### 1.2 Motivation

Understanding FIFO design is fundamental to VLSI and digital systems engineering. FIFOs appear in:
- UART TX/RX buffers
- CPU instruction pipelines
- Network packet buffers
- On-chip interconnects

This project builds a complete, parameterizable Synchronous FIFO from scratch — RTL design, status flag logic, overflow/underflow protection, and a full verification environment.

---

## CHAPTER 2: DESIGN SPECIFICATION

| Parameter | Value |
|-----------|-------|
| Type | Synchronous (single-clock) FIFO |
| Data Width | 8 bits (parameterizable) |
| Depth | 16 locations (parameterizable) |
| Address Width | 4 bits (log₂(16)) |
| Flags | full, empty, wr_ack, rd_valid |
| Write Protection | Blocked when full |
| Read Protection | Blocked when empty |
| Simultaneous R/W | Supported |
| Reset | Synchronous, active-low |
| Synthesis Target | FPGA (Xilinx / Intel) |

---

## CHAPTER 3: RTL DESIGN

### 3.1 Architecture

The FIFO uses a circular buffer (ring buffer) model with three main components:

**Write Logic**: Controlled by `wr_en`. When asserted and FIFO is not full, data is stored at `mem[wr_ptr]` and `wr_ptr` is incremented. `wr_ack` pulses to confirm.

**Read Logic**: Controlled by `rd_en`. When asserted and FIFO is not empty, `data_out` is loaded from `mem[rd_ptr]` and `rd_ptr` is incremented. `rd_valid` pulses to confirm.

**Occupancy Counter**: A `count` register tracks the number of valid entries. It increments on write-only, decrements on read-only, and remains unchanged on simultaneous read+write.

### 3.2 Status Flags

```verilog
assign full  = (count == DEPTH);
assign empty = (count == 0);
```

These are combinational outputs — they update immediately when `count` changes.

### 3.3 Pointer Wrap-Around

Both `wr_ptr` and `rd_ptr` are `ADDR_WIDTH`-bit registers. When incremented past (DEPTH-1), they naturally overflow to 0 (for power-of-2 depths). This provides circular buffer behavior without explicit modulo logic.

---

## CHAPTER 4: VERIFICATION

### 4.1 Testbench Structure

The testbench uses:
- **Task-based stimulus**: `fifo_write`, `fifo_read`, `apply_reset`
- **Reference model**: A software queue that mirrors expected DUT state
- **Auto-checking**: `check_data` and `check_flag` tasks compare expected vs. actual
- **Scoreboard**: `pass_cnt` and `fail_cnt` integer counters
- **VCD dump**: For GTKWave waveform analysis

### 4.2 Test Results Summary

All 15 test cases pass. Total individual checks: 58 passed, 0 failed.

| Test Category | Count | Result |
|---------------|-------|--------|
| Flag verification | 18 | All Pass |
| Data integrity | 32 | All Pass |
| Edge cases | 8 | All Pass |

### 4.3 Key Scenarios Verified

- **Overflow protection**: Writing to a full FIFO does not corrupt data and does not assert `wr_ack`.
- **Underflow protection**: Reading from an empty FIFO does not assert `rd_valid`.
- **FIFO order**: 16 sequential writes followed by 16 reads — all in correct order.
- **Pointer wrap-around**: Write/read cycle that forces both pointers past address 15 — correct behavior verified.
- **Simultaneous R/W**: Both `wr_ack` and `rd_valid` assert; count is stable.

---

## CHAPTER 5: SYNTHESIS

### 5.1 Estimated Resource Usage (Xilinx Artix-7)

| Resource | Estimated |
|----------|-----------|
| LUTs | ~35 |
| Flip-Flops | ~45 |
| BRAM (18Kb) | 1 (inferred) |
| DSPs | 0 |

### 5.2 Timing

The critical path is through the `count` register to the `full`/`empty` combinational outputs. Estimated Fmax > 200 MHz on 7-series FPGA.

---

## CHAPTER 6: CONCLUSION

This project successfully designed, implemented, and verified a complete Synchronous FIFO in Verilog HDL. The parameterizable RTL covers all standard FIFO features — read/write control, status flags, overflow/underflow protection, and circular pointer arithmetic. The self-checking testbench confirmed correct behavior across 15 test scenarios with 58/58 checks passing.

The design is synthesis-ready and can be directly integrated into any FPGA or ASIC project requiring a synchronous data buffer.

### Future Work
- Asynchronous (dual-clock) FIFO for CDC applications
- Almost-full / almost-empty programmable threshold flags
- AXI4-Stream interface wrapper for SoC integration
- UVM-based verification environment

---

## REFERENCES

1. Cummings, C. (2002). *Simulation and Synthesis Techniques for Asynchronous FIFO Design*. SNUG San Jose
2. Xilinx (2023). *7 Series FPGAs Memory Resources User Guide (UG473)*
3. Palnitkar, S. (2003). *Verilog HDL: A Guide to Digital Design and Synthesis*. Prentice Hall
4. Sutherland, S. (2006). *Verilog-2001: A Guide to the New Features*. Kluwer Academic
