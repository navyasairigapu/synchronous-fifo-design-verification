#=============================================================================
# Project : Design and Verification of Synchronous FIFO
# File    : Makefile
# Targets :
#   make iverilog  — compile and run with Icarus Verilog (free)
#   make modelsim  — run ModelSim simulation
#   make wave      — open GTKWave
#   make lint      — run Verilator lint check
#   make clean     — remove generated files
#=============================================================================

RTL_DIR  = ../rtl
TB_DIR   = ../tb
SIM_DIR  = ../sim

RTL_SRC  = $(RTL_DIR)/sync_fifo.v
TB_SRC   = $(TB_DIR)/tb_sync_fifo.v
VCD_FILE = $(SIM_DIR)/sync_fifo_waves.vcd

# ---- Icarus Verilog ----
iverilog:
	iverilog -o $(SIM_DIR)/sim_out -Wall -g2012 $(RTL_SRC) $(TB_SRC)
	cd $(SIM_DIR) && vvp sim_out

# ---- GTKWave Viewer ----
wave:
	gtkwave $(VCD_FILE) &

# ---- ModelSim ----
modelsim:
	cd $(SIM_DIR) && vsim -do run_sim.do

# ---- Verilator Lint Check ----
lint:
	verilator --lint-only -Wall $(RTL_SRC) --top-module sync_fifo

# ---- Clean ----
clean:
	rm -rf $(SIM_DIR)/work $(SIM_DIR)/sim_out \
	       $(SIM_DIR)/*.vcd $(SIM_DIR)/transcript $(SIM_DIR)/*.wlf

.PHONY: iverilog wave modelsim lint clean
