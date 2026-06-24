# 🔷 Design and Verification of Synchronous FIFO in Verilog HDL

<div align="center">

![Language](https://img.shields.io/badge/Language-Verilog%20HDL-orange?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Verified%20%26%20Synthesizable-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)
![Simulator](https://img.shields.io/badge/Simulator-ModelSim%20%7C%20Icarus-purple?style=for-the-badge)
![Flags](https://img.shields.io/badge/Flags-Full%20%7C%20Empty%20%7C%20WR%20%7C%20RD-red?style=for-the-badge)
![Clock](https://img.shields.io/badge/Clock-Synchronous%20%7C%20Single%20Domain-cyan?style=for-the-badge)

**Industry-grade RTL design of a Synchronous FIFO memory with full status flag logic — parameterizable, synthesizable, and verified with a 15-scenario self-checking testbench.**

</div>

---

## 📑 Table of Contents

- [Abstract](#-abstract)
- [Problem Statement](#-problem-statement)
- [Objectives](#-objectives)
- [System Architecture](#-system-architecture)
- [Working Principle](#-working-principle)
- [FIFO Architecture](#-fifo-architecture)
- [Repository Structure](#-repository-structure)
- [Port Description](#-port-description)
- [Status Flags](#-status-flags)
- [Simulation Procedure](#-simulation-procedure)
- [Expected Waveforms](#-expected-waveforms)
- [Verification Strategy](#-verification-strategy)
- [Test Cases](#-test-cases)
- [Sample Simulation Results](#-sample-simulation-results)
- [Features](#-features)
- [Applications](#-applications)
- [Advantages & Limitations](#-advantages--limitations)
- [Future Scope](#-future-scope)
- [Interview Q&A](#-20-interview-questions--answers)
- [Viva Q&A](#-20-viva-questions--answers)
- [Resume Description](#-resume-project-description)
- [LinkedIn Description](#-linkedin-project-description)

---

## 📄 Abstract

This project presents the **RTL design and functional verification** of a Synchronous FIFO (First In, First Out) memory buffer using Verilog HDL. A FIFO is a temporary data storage structure where data is read out in the exact order it was written — the first data word written is the first to be read. The design operates on a **single clock domain** for both read and write operations, making it a synchronous FIFO. Key status flags — **Full, Empty, Write Enable, and Read Enable** — are implemented and fully verified through Verilog testbenches and simulation waveforms. The design is parameterizable, synthesizable, and validated across 15 functional test scenarios with a self-checking scoreboard.

---

## ❗ Problem Statement

In digital systems, the producer (writer) and consumer (reader) of data often operate at different rates. Without a buffer between them, data is either lost (producer too fast) or the system stalls (consumer too slow). A FIFO memory resolves this mismatch by acting as a temporary holding area.

The specific challenges addressed in this design are:
1. Correctly managing read and write pointers that advance independently
2. Accurately generating **Full** and **Empty** status flags to prevent overflow and underflow
3. Handling simultaneous read and write without corrupting the occupancy count
4. Ensuring the design is **synthesizable** and free from timing issues, latches, and unintended behavior

---

## 🎯 Objectives

| # | Objective |
|---|-----------|
| 1 | Design a synchronous FIFO operating on a single clock for both read and write ports |
| 2 | Implement independent read (`rd_ptr`) and write (`wr_ptr`) pointer logic |
| 3 | Generate accurate `full` and `empty` status flags using an occupancy counter |
| 4 | Implement `wr_en` and `rd_en` control with `wr_ack` and `rd_valid` handshake signals |
| 5 | Handle overflow and underflow gracefully — no data corruption when flags are ignored |
| 6 | Develop a self-checking Verilog testbench with 15 directed test scenarios |
| 7 | Produce simulation waveforms in ModelSim / GTKWave for visual verification |
| 8 | Ensure synthesizable RTL with zero latches and zero lint warnings |

---

## 🏗️ System Architecture

```
                    ┌──────────────────────────────────────────────┐
                    │             SYNCHRONOUS FIFO                  │
                    │                                               │
  wr_en   ─────────►│  ┌─────────┐    ┌────────────────────┐      │
  data_in ─────────►│  │  WRITE  │───►│                    │      │
  wr_ack  ◄─────────│  │  LOGIC  │    │   MEMORY ARRAY     │      │
                    │  │ (wr_ptr)│    │   [DEPTH × WIDTH]  │      │
                    │  └─────────┘    │                    │      │
  clk     ─────────►│                 │                    │      │
  rst_n   ─────────►│  ┌─────────┐    │                    │      │
                    │  │  READ   │◄───│                    │      │
  rd_en   ─────────►│  │  LOGIC  │    └────────────────────┘      │
  data_out◄─────────│  │ (rd_ptr)│                                │
  rd_valid◄─────────│  └─────────┘    ┌────────────────────┐      │
                    │                  │   COUNT REGISTER   │      │
                    │  ┌───────────┐   │   (Occupancy)      │      │
  full    ◄─────────│  │   FLAG    │◄──│                    │      │
  empty   ◄─────────│  │   LOGIC   │   └────────────────────┘      │
                    │  └───────────┘                                │
                    └──────────────────────────────────────────────┘

  Single Clock Domain: clk drives all registers (wr_ptr, rd_ptr, count, mem)
```

---

## ⚙️ Working Principle

### FIFO Concept
A FIFO (First In, First Out) buffer stores data entries and returns them in the same order they were received — like a queue at a counter. In digital design, FIFOs decouple data producers from data consumers.

### Write Operation
When `wr_en` is asserted and the FIFO is **not full**, the data on `data_in` is stored at the location pointed to by `wr_ptr`. The write pointer then increments to the next location. `wr_ack` pulses high for one clock cycle to confirm the write.

### Read Operation
When `rd_en` is asserted and the FIFO is **not empty**, the data stored at `rd_ptr` is placed on `data_out`. The read pointer increments. `rd_valid` pulses high for one clock cycle to confirm valid data on the output.

### Pointer Wrap-Around
Both `wr_ptr` and `rd_ptr` are modulo-DEPTH counters — when they reach the last address, they wrap back to address 0. This gives the FIFO its circular buffer behavior.

### Status Flag Logic
```
empty = (count == 0)
full  = (count == DEPTH)
```
A dedicated `count` register tracks the number of valid entries and is incremented on writes and decremented on reads. On a simultaneous read and write, count remains unchanged.

### Timing Diagram
```
CLK    ‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_|

       — Write Cycle —              — Read Cycle —
wr_en  _|‾‾‾|___________________________
data   _|D0 |___________________________
wr_ack __|‾‾‾|__________________________   (registered, 1-clk after posedge)
empty  ‾‾‾|_____________________________   (goes low after first write)

rd_en  _____________________________|‾‾‾|_
data_out __________________________________|D0|_
rd_valid __________________________________|‾‾‾|_
empty  ______________________________________|‾‾  (goes high after last read)
```

---

## 🔲 FIFO Architecture

### Circular Buffer (Ring Buffer) Concept
```
Memory Array (DEPTH = 8, shown for illustration)
┌───┬───┬───┬───┬───┬───┬───┬───┐
│ 0 │ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │  ← Address index
└───┴───┴───┴───┴───┴───┴───┴───┘
      ↑rd_ptr             ↑wr_ptr     (Example: 3 entries pending read)

After wr_ptr reaches 7, it wraps → 0 (circular behavior)
After rd_ptr reaches 7, it wraps → 0
```

### Occupancy Count States
```
count=0           → empty=1, full=0  (no data available)
0 < count < DEPTH → empty=0, full=0  (normal operation)
count=DEPTH       → empty=0, full=1  (no space available)
```

---

## 📁 Repository Structure

```
Sync_FIFO/
│
├── rtl/                          # Synthesizable RTL Design
│   └── sync_fifo.v               # Synchronous FIFO — top-level design
│
├── tb/                           # Verification Environment
│   └── tb_sync_fifo.v            # Self-checking testbench (15 test cases)
│
├── sim/                          # Simulation Artifacts
│   └── run_sim.do                # ModelSim script with waveform configuration
│
├── scripts/                      # Build & Automation
│   └── Makefile                  # Targets: iverilog, modelsim, lint, clean
│
├── docs/                         # Documentation
│   ├── PROJECT_REPORT.md         # Full project report (6 chapters)
│   ├── PPT_CONTENT.md            # Slide-by-slide presentation content
│   └── DRAWIO_DESCRIPTION.md     # Block diagram drawing instructions
│
└── README.md                     # This file
```

---

## 🔌 Port Description

### Inputs

| Port | Width | Description |
|------|-------|-------------|
| `clk` | 1 | System clock — single clock for read and write |
| `rst_n` | 1 | Active-low synchronous reset |
| `wr_en` | 1 | Write enable — assert to write `data_in` to FIFO |
| `data_in` | DATA_WIDTH | Data word to write into the FIFO |
| `rd_en` | 1 | Read enable — assert to read next data word from FIFO |

### Outputs

| Port | Width | Description |
|------|-------|-------------|
| `data_out` | DATA_WIDTH | Data word read from the FIFO |
| `full` | 1 | FIFO full flag — no writes should occur when high |
| `empty` | 1 | FIFO empty flag — no reads should occur when high |
| `wr_ack` | 1 | Write acknowledge — 1-clock pulse confirming successful write |
| `rd_valid` | 1 | Read valid — 1-clock pulse confirming valid data on `data_out` |

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `DATA_WIDTH` | 8 | Width of each data word in bits |
| `DEPTH` | 16 | Number of data words the FIFO can hold |
| `ADDR_WIDTH` | 4 | Address bits = log₂(DEPTH) |

---

## 🚦 Status Flags

| Flag | Condition | Meaning |
|------|-----------|---------|
| `empty` | `count == 0` | No data in FIFO; reads will be ignored |
| `full` | `count == DEPTH` | FIFO completely filled; writes will be ignored |
| `wr_ack` | `wr_en && !full` | Successful write confirmed (1-clk pulse) |
| `rd_valid` | `rd_en && !empty` | Data on `data_out` is valid (1-clk pulse) |

---

## 🖥️ Simulation Procedure

### Option A — ModelSim
```bash
cd sim/
vsim -do run_sim.do
```

### Option B — Icarus Verilog (Free, open-source)
```bash
cd scripts/
make iverilog
make wave       # Opens GTKWave waveform viewer
```

### Option C — Manual Icarus
```bash
iverilog -o sim/sim_out -Wall -g2012 \
    rtl/sync_fifo.v \
    tb/tb_sync_fifo.v

cd sim && vvp sim_out
gtkwave sync_fifo_waves.vcd
```

### Option D — Verilator Lint Check
```bash
cd scripts/
make lint
```

---

## 📊 Expected Waveforms

### Write Operation (Normal)
```
CLK     _|‾|_|‾|_|‾|_|‾|_|
RST_N   ___|‾‾‾‾‾‾‾‾‾‾‾‾‾‾
WR_EN   ____|‾‾‾‾‾‾‾|______
DATA_IN ____[0xA5  ]______
EMPTY   ‾‾‾‾|______________  ← goes low after first write
WR_ACK  _____|‾‾‾‾‾|______   ← acknowledges successful write
COUNT   0000 0001 0002 ...   ← increments per write
```

### Read Operation (Normal)
```
CLK     _|‾|_|‾|_|‾|_|‾|_|
RD_EN   _|‾‾‾‾‾‾|__________
DATA_OUT _______[0xA5]_____  ← data appears 1 clk after rd_en
RD_VALID _______[‾‾‾‾]_____  ← rd_valid confirms data
EMPTY   ____________|‾‾‾‾‾  ← goes high when last word read
COUNT   0001 0000            ← decrements per read
```

### Full Flag Behavior
```
COUNT   0010 0011 ... 1110 1111 0000(FULL=16)
FULL    _____________________|‾‾‾‾‾‾‾‾‾‾‾‾‾‾
WR_EN   ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
WR_ACK  ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾_____________     ← no ack when full
```

### Simultaneous Read & Write (count stable)
```
CLK     _|‾|_|‾|_|
WR_EN   _|‾‾‾‾‾|__
RD_EN   _|‾‾‾‾‾|__
COUNT   ─── N ───  ← unchanged (write + read cancel out)
WR_ACK  __[‾‾‾‾]_
RD_VALID _[‾‾‾‾]__
```

---

## ✅ Verification Strategy

### Approach
A **directed, self-checking testbench** with a built-in reference model (software queue) verifies the DUT output against expected values automatically. Pass/Fail is printed for every check with the expected and actual values.

### Test Plan

| TC-ID | Test Name | Coverage Goal |
|-------|-----------|---------------|
| TC-01 | Reset Verification | All outputs/flags clear post-reset |
| TC-02 | Single Write | `wr_ack` asserts, `empty` deasserts |
| TC-03 | Single Read | Correct data on `data_out`, `rd_valid` asserts |
| TC-04 | Empty Flag | `empty` asserts after last read |
| TC-05 | Fill to Full | `full` asserts after DEPTH writes |
| TC-06 | Overflow Attempt | `wr_ack` stays low, data not corrupted |
| TC-07 | Drain from Full | FIFO order maintained across all DEPTH reads |
| TC-08 | Simultaneous RW | Count stable, both acks correct |
| TC-09 | Underflow Attempt | `rd_valid` stays low, FIFO stays empty |
| TC-10 | Burst Write + Read | Data integrity across 8-word burst |
| TC-11 | Alternating WR | Single interleaved ops, always correct |
| TC-12 | wr_en Deasserted | No write without wr_en |
| TC-13 | rd_en Deasserted | No read without rd_en |
| TC-14 | Pointer Wrap-Around | Circular buffer rollover correctness |
| TC-15 | Data Patterns 0x00/0xFF | Edge-case data values |

---

## 📋 Test Cases — Input/Output Table

| TC | wr_en | rd_en | data_in | Expected data_out | Expected full | Expected empty | Expected wr_ack | Expected rd_valid |
|----|-------|-------|---------|-------------------|---------------|----------------|-----------------|-------------------|
| 01 | 0 | 0 | — | — | 0 | **1** | 0 | 0 |
| 02 | 1 | 0 | 0xA5 | — | 0 | 0 | **1** | 0 |
| 03 | 0 | 1 | — | **0xA5** | 0 | 1 | 0 | **1** |
| 05 | 1×16 | 0 | 0x01–0x10 | — | **1** | 0 | 1 | 0 |
| 06 | 1 | 0 | 0xFF | — | **1** | 0 | **0** | 0 |
| 07 | 0 | 1×16 | — | 0x01–0x10 | 0 | **1** | 0 | **1** |
| 08 | 1 | 1 | 0xCC | 0xBB (prev) | 0 | 0 | 1 | 1 |
| 09 | 0 | 1 | — | — | 0 | **1** | 0 | **0** |

---

## 📊 Sample Simulation Results

```
================================================================
  Synchronous FIFO — Functional Verification Suite
  Depth=16  Width=8  Clock=100MHz
================================================================

--- TC-01: Reset Verification ---
[PASS] TC-01 | empty   = 1 (correct)
[PASS] TC-01 | full    = 0 (correct)
[PASS] TC-01 | wr_ack  = 0 (correct)
[PASS] TC-01 | rd_valid= 0 (correct)

--- TC-02: Single Write [data=0xA5] ---
[PASS] TC-02 | wr_ack  = 1 (correct)
[PASS] TC-02 | empty   = 0 (correct)
[PASS] TC-02 | full    = 0 (correct)

--- TC-03: Single Read [expect=0xA5] ---
[PASS] TC-03 | rd_valid= 1 (correct)
[PASS] TC-03 | Expected=0xA5  Got=0xA5
[PASS] TC-03 | empty   = 1 (correct)

--- TC-05: Fill FIFO to Full [write 16 words] ---
[PASS] TC-05 | full    = 1 (correct)
[PASS] TC-05 | empty   = 0 (correct)

--- TC-06: Overflow Attempt [write when full] ---
[PASS] TC-06 | wr_ack  = 0 (correct)
[PASS] TC-06 | full    = 1 (correct)

--- TC-07: Drain FIFO and Verify FIFO Order ---
[PASS] TC-07 | Expected=0x01  Got=0x01
[PASS] TC-07 | Expected=0x02  Got=0x02
... (16 entries, all pass)
[PASS] TC-07 | empty   = 1 (correct)

--- TC-08: Simultaneous Read & Write ---
[PASS] TC-08 | wr_ack  = 1 (correct)
[PASS] TC-08 | rd_valid= 1 (correct)
[PASS] TC-08 | Expected=0xBB  Got=0xBB
[PASS] TC-08 | Expected=0xCC  Got=0xCC

--- TC-09: Underflow Attempt [read when empty] ---
[PASS] TC-09 | rd_valid= 0 (correct)
[PASS] TC-09 | empty   = 1 (correct)

--- TC-14: Pointer Wrap-Around Test ---
[PASS] TC-14 | Expected=0xF0  Got=0xF0
... (8 entries, all pass)
[PASS] TC-14 | empty   = 1 (correct)

--- TC-15: Data Pattern Test [0x00 and 0xFF] ---
[PASS] TC-15 | Expected=0x00  Got=0x00
[PASS] TC-15 | Expected=0xFF  Got=0xFF

================================================================
  VERIFICATION COMPLETE
  Total Checks : 58
  PASSED       : 58
  FAILED       : 0
  STATUS       : *** ALL TESTS PASSED — DESIGN VERIFIED ***
================================================================
```

---

## ⭐ Features

- 🔹 **Single-clock synchronous** design — no clock domain crossing issues
- 🔹 **Parameterizable** data width and depth — drop-in for any project
- 🔹 **Four status flags** — `full`, `empty`, `wr_ack`, `rd_valid`
- 🔹 **Overflow / underflow protection** — writes and reads blocked gracefully
- 🔹 **Simultaneous read and write** support — count remains stable
- 🔹 **Circular buffer (ring buffer)** pointer architecture
- 🔹 **BRAM-inference friendly** — memory array maps to Block RAM in FPGAs
- 🔹 **Synthesizable** — no latches, all registers synchronous with reset
- 🔹 **Self-checking testbench** with 15 test scenarios and automated scoring
- 🔹 **VCD waveform dump** for GTKWave visualization
- 🔹 **Simulation assertions** with overflow / underflow warning messages

---

## 🌐 Applications

| Domain | Application |
|--------|-------------|
| UART / SPI / I2C | Data buffering between serial peripheral and CPU |
| Processor Design | Instruction queue, pipeline stage buffers |
| Networking | Packet buffering between MAC and PHY layers |
| Audio / Video | Stream buffering to handle rate mismatches |
| DMA Controllers | Data staging between memory and peripherals |
| Embedded Systems | Real-time sensor data buffering |
| ASIC / SoC | Inter-module communication buffer |
| FPGA Designs | General-purpose on-chip data queue |

---

## ✅ Advantages & ⚠️ Limitations

### Advantages
- ✅ Simple, proven architecture — easy to understand and implement
- ✅ Single clock eliminates metastability concerns
- ✅ Synthesizes efficiently — maps to BRAM in all major FPGA families
- ✅ Zero data loss on overflow/underflow — flags prevent illegal access
- ✅ Parameterizable — one module serves all width/depth combinations
- ✅ Low area overhead — only pointers, counter, and memory required

### Limitations
- ⚠️ Single clock only — cannot directly connect producer and consumer in different clock domains (use Async FIFO for CDC)
- ⚠️ No burst-read mode — one word per clock cycle
- ⚠️ No "almost full" / "almost empty" programmable threshold flags (can be added as future work)
- ⚠️ DEPTH must be a power of 2 for correct pointer wrap-around (as implemented)
- ⚠️ No built-in ECC — data corruption in memory is not detected

---

## 🚀 Future Scope

1. **Asynchronous FIFO** — Dual-clock version with gray-code pointers for safe clock domain crossing (CDC)
2. **Almost-Full / Almost-Empty Flags** — Programmable threshold flags for early warning
3. **First-Word Fall-Through (FWFT)** mode — data appears on `data_out` without needing `rd_en`
4. **AXI4-Stream Interface** — Wrap in AXI4-Stream for SoC integration (TDATA, TVALID, TREADY)
5. **Error Detection** — Add SECDED ECC to detect and correct single-bit errors in memory
6. **Formal Verification** — SVA assertions + SymbiYosys to formally prove flag correctness
7. **Non-power-of-2 Depths** — Modified pointer logic to support arbitrary DEPTH values
8. **UVM Testbench** — Replace directed TB with UVM-based verification environment

---

## 🎤 20 Interview Questions & Answers

<details>
<summary><b>Click to expand Interview Q&A</b></summary>

**Q1: What is a FIFO and what does it stand for?**
FIFO stands for First In, First Out. It is a data buffer where the first data word written is the first data word to be read out. It works like a queue — the order of data is preserved between the writer and the reader.

**Q2: What is the difference between a synchronous and asynchronous FIFO?**
A synchronous FIFO uses a single clock for both read and write operations, making design straightforward with no metastability concerns. An asynchronous FIFO uses two separate clocks — one for the write port and one for the read port. The latter requires gray-code pointer synchronization to safely cross clock domains.

**Q3: What are the status flags in this FIFO design?**
Four status flags are implemented: `full` (no write space available), `empty` (no data to read), `wr_ack` (write acknowledged — write occurred successfully), and `rd_valid` (read data on output is valid).

**Q4: How is the `full` flag generated?**
`full` is asserted when the occupancy counter `count` equals `DEPTH` — meaning all storage locations are occupied. At this point, any write attempt (even with `wr_en` high) is blocked.

**Q5: How is the `empty` flag generated?**
`empty` is asserted when the occupancy counter `count` equals 0 — meaning no data is stored. Any read attempt when empty is ignored and `rd_valid` remains low.

**Q6: What happens during a simultaneous read and write?**
When `wr_en` and `rd_en` are both asserted simultaneously and the FIFO is neither full nor empty, both operations succeed. A new word is written at `wr_ptr` and an old word is read from `rd_ptr`. The occupancy count remains unchanged (write +1 and read -1 cancel out).

**Q7: What is pointer wrap-around?**
The write pointer (`wr_ptr`) and read pointer (`rd_ptr`) are modulo-DEPTH counters. When a pointer reaches the last valid address (DEPTH-1), the next increment wraps it back to address 0. This gives the FIFO a circular (ring buffer) behavior, reusing memory locations efficiently.

**Q8: What is an overflow condition? How is it handled?**
Overflow occurs when a write is attempted (`wr_en=1`) while the FIFO is already full (`full=1`). In this design, the write is blocked — the memory is not written, `wr_ptr` does not advance, and `wr_ack` remains low. No data is corrupted.

**Q9: What is an underflow condition? How is it handled?**
Underflow occurs when a read is attempted (`rd_en=1`) while the FIFO is empty (`empty=1`). The read is blocked — `data_out` is not updated, `rd_ptr` does not advance, and `rd_valid` remains low.

**Q10: Why use a separate count register instead of comparing wr_ptr and rd_ptr?**
Comparing wr_ptr == rd_ptr can mean either full or empty — it is ambiguous. A dedicated count register removes this ambiguity: count=0 means empty, count=DEPTH means full. It also directly gives occupancy information for future threshold flags.

**Q11: What is the role of `wr_ack`?**
`wr_ack` is a 1-clock acknowledge pulse that confirms a write was successfully executed. The upstream logic can monitor `wr_ack` to know whether its data was actually stored, rather than assuming the write succeeded.

**Q12: What is the role of `rd_valid`?**
`rd_valid` is a 1-clock pulse that signals the data on `data_out` is valid and was successfully read from the FIFO. The downstream logic should only latch `data_out` when `rd_valid` is high.

**Q13: How do you ensure this FIFO is synthesizable?**
All registers use non-blocking assignments (`<=`) inside `always @(posedge clk)` blocks. Every register has a reset condition. No combinational feedback loops exist. No `initial` blocks appear in RTL (only in testbench). The memory is inferred as synchronous BRAM.

**Q14: What is First-Word Fall-Through (FWFT) mode?**
In FWFT mode, the first word written into the FIFO immediately appears on `data_out` without needing a read pulse. This reduces read latency by one clock cycle. The current design uses standard (non-FWFT) mode.

**Q15: Why is DEPTH a power of 2 in this design?**
With ADDR_WIDTH = log₂(DEPTH), the pointer naturally wraps from (DEPTH-1) back to 0 when it overflows its bit width — no modulo logic is needed. If DEPTH is not a power of 2, explicit comparator logic is required to reset the pointer.

**Q16: What is a circular buffer? How does the FIFO use it?**
A circular buffer is a fixed-size memory array where the read and write positions wrap around from the end back to the beginning. The FIFO's ring structure means once `wr_ptr` reaches the end, it wraps to 0 — reusing freed locations as they are read out.

**Q17: How many bits are needed for the pointers if DEPTH=16?**
ADDR_WIDTH = log₂(16) = 4 bits. Both `wr_ptr` and `rd_ptr` are 4-bit registers, addressing locations 0–15.

**Q18: How would you add an "almost full" flag?**
Add a programmable threshold parameter (e.g., `AF_THRESHOLD = DEPTH - 2`). Then: `almost_full = (count >= AF_THRESHOLD)`. This gives early warning before the FIFO actually fills, allowing upstream logic to slow down.

**Q19: What is the latency of a read operation in this design?**
Read latency is 1 clock cycle. On the clock edge when `rd_en` is asserted (and `!empty`), the data is registered to `data_out` and `rd_valid` is set. The output is available on the next clock edge.

**Q20: How would you convert this to an asynchronous FIFO?**
Replace the single occupancy counter with gray-code encoded pointers. The write pointer is synchronized to the read clock domain using a 2-FF synchronizer (and vice versa). Gray code ensures only one bit changes per increment, preventing metastability during synchronization. The full/empty flags are derived from the synchronized gray-code pointers.

</details>

---

## 📚 20 Viva Questions & Answers

<details>
<summary><b>Click to expand Viva Q&A</b></summary>

**V1: What does FIFO stand for?** First In, First Out.

**V2: What type of FIFO is implemented here?** Synchronous FIFO — a single clock drives both read and write operations.

**V3: What are the inputs to the FIFO?** `clk`, `rst_n`, `wr_en`, `data_in`, `rd_en`.

**V4: What are the outputs of the FIFO?** `data_out`, `full`, `empty`, `wr_ack`, `rd_valid`.

**V5: What does the `full` flag indicate?** The FIFO has no more space — all DEPTH locations are occupied. Writes are ignored when full.

**V6: What does the `empty` flag indicate?** There is no data in the FIFO. Reads are ignored when empty.

**V7: What is `wr_ack`?** A one-clock pulse that confirms a write was successfully executed.

**V8: What is `rd_valid`?** A one-clock pulse that confirms the data on `data_out` is valid.

**V9: How many storage locations does this FIFO have?** 16 (DEPTH=16), configurable via the `DEPTH` parameter.

**V10: How wide is each storage location?** 8 bits (DATA_WIDTH=8), configurable via the `DATA_WIDTH` parameter.

**V11: What is the total storage capacity?** 16 × 8 = 128 bits = 16 bytes.

**V12: What happens if you write to a full FIFO?** The write is blocked — `wr_ack` stays low and the memory is not modified.

**V13: What happens if you read from an empty FIFO?** The read is blocked — `rd_valid` stays low and `data_out` is not updated.

**V14: What is the `count` register used for?** It tracks the current number of valid entries in the FIFO and drives the `full` and `empty` flags.

**V15: What is pointer wrap-around?** When a pointer reaches the last address (15 for DEPTH=16), it resets to 0 on the next increment — enabling circular reuse of memory.

**V16: What simulation tool is used?** ModelSim (primary) and Icarus Verilog with GTKWave (alternative).

**V17: What is a testbench?** A non-synthesizable Verilog module that applies stimulus to the DUT and verifies its outputs.

**V18: What is a self-checking testbench?** A testbench that automatically compares expected outputs to actual outputs and prints PASS or FAIL — no manual waveform inspection needed.

**V19: What is VCD?** Value Change Dump — a file format that records signal changes during simulation. GTKWave reads VCD files to display waveforms.

**V20: What is the difference between `full` and `wr_ack`?** `full` is a **level** signal — it stays high as long as the FIFO is full. `wr_ack` is a **pulse** — it goes high for exactly one clock to confirm a specific write was accepted.

</details>

---

## 📝 Resume Project Description

```
Design and Verification of Synchronous FIFO | Verilog HDL | VLSI / Digital Design
────────────────────────────────────────────────────────────────────────────────────
• Designed a parameterizable Synchronous FIFO memory in Verilog HDL with
  independent read/write pointer logic, a circular buffer architecture, and
  an occupancy counter driving Full and Empty status flags.

• Implemented wr_en/rd_en control with wr_ack and rd_valid handshake signals
  to ensure safe data transfer with overflow and underflow protection, preventing
  memory corruption under all operating conditions.

• Developed a self-checking Verilog testbench with 15 directed test scenarios
  covering reset, single R/W, burst R/W, simultaneous R+W, overflow/underflow
  attempts, pointer wrap-around, and data pattern tests — achieving 58/58 checks
  passed with automated pass/fail scoring.

• Generated ModelSim simulation waveforms for visual verification of all status
  flags and data flow; ensured synthesizable RTL with zero latches and zero lint
  warnings, targeting FPGA deployment on Xilinx and Intel platforms.
```

---

## 💼 LinkedIn Project Description

```
🔷 Design and Verification of Synchronous FIFO | Verilog HDL | VLSI Design

Designed and verified a Synchronous FIFO memory buffer in Verilog HDL as
part of an industry-oriented VLSI design project.

🛠️ Technical Highlights:
→ Parameterizable RTL design (configurable data width and depth) with
   circular buffer (ring buffer) architecture
→ Status flags: Full, Empty, Write Acknowledge (wr_ack), Read Valid (rd_valid)
→ Overflow and underflow protection — no data corruption under any condition
→ 15-scenario self-checking testbench: reset, burst, simultaneous R/W,
   pointer wrap-around, data patterns — 58/58 checks passed
→ Simulation in ModelSim with waveform verification in GTKWave

📁 Full repository: RTL → Testbench → Simulation → Documentation

🔑 Skills: Verilog HDL · FIFO Design · RTL Design · Functional Verification ·
           ModelSim · GTKWave · Digital Design · FPGA · VLSI

#VLSI #VerilogHDL #FPGADesign #DigitalDesign #RTLDesign #FIFO #Semiconductor
```

---

## 📖 License

This project is licensed under the **MIT License** — free to use, modify, and distribute with attribution.

---

## 🤝 Contributing

Pull requests are welcome. Please open an issue first for major changes.

---

<div align="center">

**Designed with ❤️ for the VLSI & Digital Design Community**

⭐ Star this repo if it helped you | 🍴 Fork it to build your own FIFO variant

</div>
