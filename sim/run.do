# --- 1. Create and map work library ---
vlib work
vmap work work

# --- 2. Compile RTL and Testbench files ---
vlog -reportprogress 300 ./ram.v
vlog -reportprogress 300 ./spi_slave.v
vlog -reportprogress 300 ./spi_wrapper.v
vlog -reportprogress 300 ./spi_wrapper_tb.v

# --- 3. Load the design ---
vsim -voptargs="+acc" work.spi_wrapper_tb

# --- 4. Clear old waves and add all signals clearly ---
delete wave *

add wave -noupdate -divider {SPI Master Signals}
add wave -color Cyan /spi_wrapper_tb/clk
add wave -color Yellow /spi_wrapper_tb/rst_n
add wave -color Magenta /spi_wrapper_tb/SS_n
add wave -color Green /spi_wrapper_tb/MOSI
add wave -color Green /spi_wrapper_tb/MISO

add wave -noupdate -divider {SPI Slave FSM & Registers}
add wave -radix unsigned -color Orange /spi_wrapper_tb/uut/u_spi_slave/curr_state
add wave -radix unsigned -color Khaki /spi_wrapper_tb/uut/u_spi_slave/bit_counter
add wave -radix hexadecimal -color Pink /spi_wrapper_tb/uut/u_spi_slave/rx_shift_reg
add wave -radix hexadecimal -color Pink /spi_wrapper_tb/uut/u_spi_slave/tx_shift_reg

add wave -noupdate -divider {RAM Interface (Valid & Data)}
add wave -radix hexadecimal -color DodgerBlue /spi_wrapper_tb/uut/u_spi_slave/rx_data
add wave -color Yellow /spi_wrapper_tb/uut/u_spi_slave/rx_valid
add wave -radix hexadecimal -color DodgerBlue /spi_wrapper_tb/uut/u_spi_slave/tx_data
add wave -color Yellow /spi_wrapper_tb/uut/u_spi_slave/tx_valid

# --- 5. Run simulation ---
run -all

# --- 6. Zoom to fit whole simulation wave ---
wave zoomfull
