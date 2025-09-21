# TEA Test ADC MUX

A Verilog-based multi-channel ADC (Analog-to-Digital Converter) system with multiplexer functionality for TEA Lab testing purposes.

## Overview

This project implements an 8-channel ADC system that collects serial data from multiple channels and multiplexes them into a 128-bit AXI-Stream output. The system is designed for testing and validation purposes in the TEA Lab environment.

## Architecture

The system consists of three main modules:

### 1. ADC Module (`adc.v`)

- **Purpose**: Serial data collection from individual ADC channels
- **Inputs**:
  - `sck`: Serial clock (64x the word select frequency)
  - `ws`: Word select signal (sample rate)
  - `sd`: Serial data input
  - `rst`: Reset signal
  - `start`: Start signal
  - `flag_in`: Ready signal from multiplexer
- **Outputs**:
  - `data[31:0]`: 32-bit parallel data output
  - `flag_out`: Data valid signal to multiplexer

**Key Features**:

- Collects 24-bit serial data and outputs as 32-bit parallel data
- Implements ready/valid handshake protocol
- State machine-based control for reliable data collection
- Synchronous reset and start functionality

### 2. Multiplexer Module (`mux.v`)

- **Purpose**: Collects data from 8 ADC channels and multiplexes into AXI-Stream format
- **Inputs**:
  - `clk`: System clock
  - `rst`: Reset signal
  - `start`: Start signal
  - `S_AXIS_tready`: AXI-Stream ready signal
  - `data1` through `data8`: 32-bit data from each ADC channel
  - `flag1_in` through `flag8_in`: Data valid signals from each ADC
- **Outputs**:
  - `S_AXIS_tdata[127:0]`: 128-bit AXI-Stream data
  - `S_AXIS_tvalid`: AXI-Stream valid signal
  - `S_AXIS_tlast`: AXI-Stream last signal
  - `flag1_out` through `flag8_out`: Ready signals to each ADC

**Key Features**:

- State machine with 4 states: IDLE, CHECK, TRANS1, TRANS2
- Collects data from channels 1-4 in first transaction
- Collects data from channels 5-8 in second transaction
- Implements proper AXI-Stream protocol with tvalid and tlast signals

### 3. Wrapper Module (`wrapper.v`)

- **Purpose**: Top-level module that instantiates 8 ADC modules and 1 multiplexer
- **Inputs**:
  - `sck`: Serial clock
  - `ws`: Word select signal
  - `rst`: Reset signal
  - `start`: Start signal
  - `S_AXIS_tready`: AXI-Stream ready signal
  - `sd[7:0]`: 8-bit serial data input (one bit per channel)
- **Outputs**:
  - `S_AXIS_tdata[127:0]`: 128-bit AXI-Stream data
  - `S_AXIS_tvalid`: AXI-Stream valid signal
  - `S_AXIS_tlast`: AXI-Stream last signal
  - `flag_mux_to_adc_fuck[7:0]`: Debug output for multiplexer to ADC flags
  - `flag_adc_to_mux_fuck[7:0]`: Debug output for ADC to multiplexer flags

## Testbench

The testbench (`wrapper_tb.v`) provides comprehensive testing functionality:

### Clock Generation

- **SCK**: 1.024 MHz (976.5625 ns period)
- **WS**: 16 kHz (SCK/64, synchronized division)

### Test Data

- Generates 8 different 24-bit test patterns:
  - Channel 0: `0xaaaaaa`
  - Channel 1: `0xbbbbbb`
  - Channel 2: `0xcccccc`
  - Channel 3: `0xdddddd`
  - Channel 4: `0xeeeeee`
  - Channel 5: `0xffffff`
  - Channel 6: `0x111111`
  - Channel 7: `0x222222`

### Test Scenarios

1. **Reset and Initialization**: 32 SCK cycles of reset
2. **Normal Operation**: 300 SCK cycles of data collection
3. **Backpressure Testing**: Simulates AXI-Stream backpressure by deasserting `S_AXIS_tready`
4. **Recovery Testing**: Resumes normal operation after backpressure

## Signal Timing

- **Serial Clock (SCK)**: 1.024 MHz
- **Word Select (WS)**: 16 kHz (SCK/64)
- **Data Collection**: 24 bits per channel during WS=0
- **Data Output**: 32-bit parallel data per channel
- **AXI-Stream**: 128-bit output (4 channels × 32 bits per transaction)

## Usage

1. **Synthesis**: Use with standard Verilog synthesis tools (Vivado, Quartus, etc.)
2. **Simulation**: Run the testbench to verify functionality
3. **Integration**: Connect to AXI-Stream compatible systems

## File Structure

```text
├── adc.v          # ADC module implementation
├── mux.v          # Multiplexer module implementation
├── wrapper.v      # Top-level wrapper module
├── wrapper_tb.v   # Testbench
└── README.md      # This documentation
```

## Dependencies

- Verilog synthesis and simulation tools
- AXI-Stream compatible downstream modules
- Clock and reset generation logic

## Notes

- The system uses a ready/valid handshake protocol for reliable data transfer
- All modules are synchronous and use positive-edge clocking
- Reset is synchronous and active-high
- The system is designed for 8-channel operation but can be easily modified for different channel counts
