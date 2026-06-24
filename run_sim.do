# =============================================================================
# Project      : Design and Verification of Synchronous FIFO
# File         : run_sim.do
# Description  : ModelSim Simulation Script
#                Run from ModelSim: do run_sim.do
# =============================================================================

# ---- Clean up previous work library ----
if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# ---- Compile RTL ----
echo "=== Compiling RTL ==="
vlog -work work -timescale "1ns/1ps" \
    ../rtl/sync_fifo.v

# ---- Compile Testbench ----
echo "=== Compiling Testbench ==="
vlog -work work -timescale "1ns/1ps" \
    ../tb/tb_sync_fifo.v

# ---- Start Simulation ----
echo "=== Starting Simulation ==="
vsim -t 1ns -lib work tb_sync_fifo \
     -voptargs="+acc" \
     -do "

    # ---- Waveform Groups ----

    add wave -divider {=== CLOCK & RESET ===}
    add wave -color Gold    sim:/tb_sync_fifo/clk
    add wave -color Red     sim:/tb_sync_fifo/rst_n

    add wave -divider {=== WRITE INTERFACE ===}
    add wave -color Cyan    sim:/tb_sync_fifo/wr_en
    add wave -color Yellow  -radix hex  sim:/tb_sync_fifo/data_in
    add wave -color Green   sim:/tb_sync_fifo/wr_ack

    add wave -divider {=== READ INTERFACE ===}
    add wave -color Cyan    sim:/tb_sync_fifo/rd_en
    add wave -color Yellow  -radix hex  sim:/tb_sync_fifo/data_out
    add wave -color Green   sim:/tb_sync_fifo/rd_valid

    add wave -divider {=== STATUS FLAGS ===}
    add wave -color Orange  sim:/tb_sync_fifo/full
    add wave -color Magenta sim:/tb_sync_fifo/empty

    add wave -divider {=== INTERNAL STATE ===}
    add wave -color White   -radix unsigned  sim:/tb_sync_fifo/DUT/wr_ptr
    add wave -color White   -radix unsigned  sim:/tb_sync_fifo/DUT/rd_ptr
    add wave -color White   -radix unsigned  sim:/tb_sync_fifo/DUT/count

    add wave -divider {=== MEMORY ARRAY ===}
    add wave -color LightBlue -radix hex sim:/tb_sync_fifo/DUT/mem

    # ---- Run Simulation ----
    run -all
    wave zoom full
"
