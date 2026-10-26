# systemverilog-uart
UART transmitter and receiver in SystemVerilog with self-checking simulation tests.

This project explores serial communication, finite-state machines,
clock-based timing, and digital hardware verification.

## Status

Work in progress. An initial implementation and testbench are available.
I’m working through the design and reproducing the simulation results.

## What It Does

The transmitter accepts an 8-bit byte and sends it one bit at a time
using the UART 8N1 format:

- 1 start bit (low)
- 8 data bits, least-significant bit first
- No parity bit
- 1 stop bit (high)

The serial output stays high when idle.

## Interface

| Signal | Direction | Description |
|--------|-----------|-------------|
| clk | Input | System clock |
| rst | Input | Synchronous, active-high reset |
| start | Input | One-clock pulse requesting transmission |
| data_in[7:0] | Input | Byte to transmit |
| tx | Output | Serial data output |
| busy | Output | High while transmitting |

Requests are accepted only when idle. The input byte is saved when
a request is accepted. Requests while busy are ignored.

## Design

The transmitter uses four states:

IDLE → START → DATA → STOP → IDLE

A counter holds each serial bit for CLKS_PER_BIT clock cycles.
An index selects which of the eight saved data bits to transmit.

CLKS_PER_BIT must be at least 1. The default value of 4 is intended
for easy simulation.

Actual baud rate = clock frequency / CLKS_PER_BIT

## Repository Structure

rtl/uart_tx.sv     — Transmitter design
tb/uart_tx_tb.sv   — Self-checking testbench

## Run the Simulation

Install Icarus Verilog, then run from the repository root:

    mkdir -p build
    iverilog -g2012 -s uart_tx_tb -o build/uart_sim rtl/uart_tx.sv tb/uart_tx_tb.sv
    vvp build/uart_sim

The testbench prints PASS if its checks succeed and generates
uart_tx.vcd for waveform inspection.

## Verification

The testbench checks:

- All 256 possible byte values
- Start, data, and stop bit timing
- Busy signal behavior
- Changes to data_in during transmission
- Ignoring requests while busy
- Reset during transmission and recovery afterward

## Planned Improvements

- Add an annotated simulation waveform
- Document design decisions and lessons learned
- Build a UART receiver
- Connect the transmitter and receiver in a loopback test
