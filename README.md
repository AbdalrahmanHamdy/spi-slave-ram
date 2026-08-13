# SPI Slave with Single-Port RAM

A synchronous SPI slave interface driving a single-port RAM, implemented in Verilog and verified on QuestaSim, with three FSM encoding variants (Gray, One-hot, Sequential) compared and synthesized in Vivado.

<!-- Optional badges once CI is set up:
![Simulation](https://img.shields.io/badge/simulation-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
-->

## Overview

This project implements a full SPI-to-memory bridge:

- **SPI Slave FSM** — deserializes commands and address/data words arriving on `MOSI`, and serializes read results back out on `MISO`.
- **Single-Port RAM** — stores 256 bytes, addressed by a two-bit command field embedded in each 10-bit SPI word.
- **SPI Wrapper** — connects the two modules and exposes the four-wire SPI interface (`MOSI`, `MISO`, `SCK`/`clk`, `SS_n`).

The design was verified with a self-checking testbench (write → read round-trips across multiple addresses), then synthesized and implemented in Vivado under three different FSM state encodings to compare timing results and select the best-performing variant for the target FPGA.

## Protocol

Each SPI transaction is a 10-bit word, MSB-first. The top two bits select the command:

| `din[9:8]` | Command      | Behavior                                                        |
|------------|--------------|-------------------------------------------------------------------|
| `00`       | Write address | Latches `din[7:0]` internally as the write address               |
| `01`       | Write data    | Writes `din[7:0]` to RAM at the previously latched write address |
| `10`       | Read address  | Latches `din[7:0]` internally as the read address                 |
| `11`       | Read execute  | Drives `dout` with `RAM[read_address]`, raises `tx_valid`         |

A full write-then-read cycle takes four SPI transactions: write address, write data, read address, read execute.

## Repository structure

```
.
├── rtl/
│   ├── ram.v                  # Single-port synchronous RAM
│   ├── spi_slave.v            # SPI slave FSM (shift registers, command decode)
│   └── spi_wrapper.v          # Top-level wiring (SPI slave + RAM)
├── sim/
│   ├── spi_wrapper_tb.v       # Self-checking testbench
│   └── run.do                 # QuestaSim run script
├── constraints/
│   └── spi_project.xdc        # Pin mapping (rst_n/SS_n/MOSI -> switches, MISO -> LED)
├── fsm_variants/
│   ├── gray/                  # Gray-encoded FSM synthesis results
│   ├── one_hot/                # One-hot encoded FSM synthesis results
│   └── sequential/            # Sequential (binary) encoded FSM synthesis results
├── reports/
│   ├── timing_summary.md      # WNS/slack comparison across encodings
│   └── utilization_summary.md
├── docs/
│   ├── SPI_Project_Report.pdf # Full submitted report (waveforms, lint, synthesis, timing)
│   └── lessons_learned.md     # Bugs found, root causes, fixes, general RTL principles
└── README.md
```

## Getting started

### Simulation (QuestaSim)

```bash
cd sim
vlib work
vlog ../rtl/ram.v ../rtl/spi_slave.v ../rtl/spi_wrapper.v spi_wrapper_tb.v
vsim -voptargs="+acc" work.spi_wrapper_tb -do run.do
```

Expected output: `ALL TESTS PASSED SUCCESSFULLY` from the self-checking testbench.

### Synthesis & Implementation (Vivado)

1. Create a new RTL project, add the files under `rtl/`.
2. Add `constraints/spi_project.xdc`.
3. Set the FSM encoding via the `fsm_encoding` synthesis attribute (or vendor-specific synthesis option) — see `fsm_variants/` for the three tested configurations.
4. Run synthesis → implementation → generate bitstream.

## FSM encoding comparison

<!-- Fill in with your actual Vivado timing report numbers -->

| Encoding    | WNS (ns) | Worst hold slack (ns) | LUTs | FFs |
|-------------|----------|------------------------|------|-----|
| Gray        |          |                        |      |     |
| One-hot     |          |                        |      |     |
| Sequential  |          |                        |      |     |

**Selected encoding:** _(fill in the winner and a one-line justification)_

## Key design decisions

- **Separate write/read address registers** in the RAM — required because the write-address and read-address commands arrive in independent transactions and must not alias.
- **Unified enable condition (`!SS_n`)** driving both the bit counter and the shift register — earlier revisions used separate per-state conditions for each, which drifted out of sync and corrupted captured words; see [`docs/lessons_learned.md`](docs/lessons_learned.md) for the full debugging trace.
- **`rd_addr_received` flag** — required by the assignment spec to let the FSM distinguish a read-address transaction from a read-execute transaction across two separate SPI messages.

For the complete list of bugs found, root causes, and fixes applied during development, see [`docs/lessons_learned.md`](docs/lessons_learned.md).

## Author

_(your name / team name here)_

## License

_(MIT / none — your choice)_
