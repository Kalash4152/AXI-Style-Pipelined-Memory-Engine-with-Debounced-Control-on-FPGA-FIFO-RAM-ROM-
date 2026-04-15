# AXI-Style Pipelined Memory Engine on FPGA

## Overview

This project implements a **fully synchronous pipelined memory datapath** on FPGA using:

* FIFO buffer
* Dual-port RAM
* ROM lookup table

The design follows **AXI-style valid/ready handshaking** and includes **robust button conditioning (synchronization + debounce + edge detection)** for reliable real-world input handling.

---

## Architecture

```
SW → Input → FIFO → RAM → ROM → Output → LED
              ↑
           Start (BTN0)
```

* **FIFO**: Buffers incoming data
* **RAM**: Intermediate storage (pipeline stage)
* **ROM**: Lookup table (data transformation)
* **LED**: Displays processed output

---

## Key Features

* Fully pipelined architecture (1 output per cycle after fill)
* AXI-style valid/ready flow control
* Parameterized RTL design
* Debounced and synchronized button inputs
* Clean top-level modular integration
* Synthesized and implemented on **Arty A7 FPGA**

---

## Button Conditioning (Critical Concept)

Raw button inputs are:

* Asynchronous
* Noisy (bounce)

### Solution implemented:

```
Raw Input → 2-FF Synchronizer → Debounce Counter → Edge Detector
```

* **BTN0 (Start)** → Single-cycle pulse
* **BTN1 (Reset)** → Stable level signal

This ensures:

* No metastability
* No multiple triggers
* Deterministic behavior

---

## Operation (How to Run on FPGA)

### Step 1: Reset

Press **BTN1**

* Clears pipeline and output
* LED = 0

### Step 2: Set Input

Use **SW[3:0]**

* Input expanded to 8-bit internally

### Step 3: Start Processing

Press **BTN0**

* Generates 1-cycle pulse
* Data enters pipeline

### Step 4: Observe Output

* After pipeline latency
* LED displays processed value

---

## Example

| Input (SW) | Decimal | Output (LED) |
| ---------- | ------- | ------------ |
| 1010       | 10      | 11101000     |

Output is **ROM lookup result**, not direct mapping.

---

## Timing & Pipeline Behavior

### Pipeline Stages:

1. FIFO
2. RAM
3. ROM

### Characteristics:

* **Latency**: ~3 clock cycles
* **Throughput**: 1 output per cycle (after fill)
* **Clock**: 100 MHz

### Key Timing Insight:

* All logic is synchronous (posedge clk)
* No combinational long paths
* Registered output ensures glitch-free behavior

---

## Design Concepts Demonstrated

* Synchronous FIFO design
* Memory hierarchy (FIFO + RAM + ROM)
* Pipeline architecture
* Valid/ready handshake
* Clock domain safety (synchronization)
* Debouncing real-world inputs
* RTL modular design

---

## File Structure

```
├── fpga_top.v           # Top module (integration)
├── btn_conditioner.v    # Input conditioning (sync + debounce)
├── pipeline_top.v       # Core pipeline
├── fifo.v               # FIFO module
├── ram_dp.v             # Dual-port RAM
├── rom.v                # Lookup table
├── constraints.xdc      # FPGA pin constraints
```

---

## Waveform


<img width="1576" height="615" alt="image" src="https://github.com/user-attachments/assets/0727e012-4abc-4e33-9c93-8ac76e908297" />


---

## FPGA Used

* **Board**: Arty A7-100T
* **Clock**: 100 MHz

---

## Future Improvements

* Add AXI-Stream interface
* Introduce backpressure handling (out_ready control)
* Extend to cache controller / memory hierarchy
* Add testbench with self-checking

---

## Author

Designed as part of VLSI-focused FPGA learning and system design practice.
