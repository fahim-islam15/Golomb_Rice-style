# Golomb-Rice Encoder

A hardware implementation of a Golomb-Rice encoder in Verilog, taken from RTL through to a GDSII layout.

## Overview

[1-2 sentences: what the design does, e.g. "Encodes input samples using Golomb-Rice coding with parameter k."]

## Repository Structure

- `RTL/` - Verilog source files
- `TB/` - testbenches
- `config.json` - OpenLane configuration for the RTL-to-GDSII flow
- `GRC_TOP.gds` - final layout of the top module

## Top Module

`GRC_TOP`

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| clk  | input     | 1     | Clock       |
| rst  | input     | 1     | Reset       |
| [add your ports] | | | |

## How to Simulate

[Your command, e.g. `iverilog -o sim RTL/*.v TB/*.v && vvp sim`]

## Results

- Technology / PDK: [e.g. sky130]
- Clock frequency: [value]
- Area: [value]

## GDS Viewer

- [View in 3D GDS Viewer](https://gds-viewer.tinytapeout.com/?model=https://raw.githubusercontent.com/fahim-islam15/Golomb_Rice-style/master/GRC_TOP.gds)
- [View in Tiny Tapeout Explorer](https://gds-explorer.tinytapeout.com/viewer.html?gds=https://raw.githubusercontent.com/fahim-islam15/Golomb_Rice-style/master/GRC_TOP.gds)
