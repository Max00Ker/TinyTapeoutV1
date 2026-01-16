![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg) ![](../../workflows/fpga/badge.svg)

# Traffic Light Controller — Tiny Tapeout Project

This project implements a **digital traffic light controller** with **pedestrian request logic** and **LED countdown displays** on a Tiny Tapeout chip.  

The system:

- Controls car and pedestrian lights  
- Allows pedestrians to request an early green phase  
- Shows a visual countdown using two MAX7219 LED matrices  
- Displays smiley faces corresponding to the pedestrian signal:
  - 😀 Green — safe to walk  
  - 😐 Blinking green — pedestrian phase ending  
  - ☹️ Red — wait  


This project implements a **digital traffic light controller** with integrated **pedestrian request logic** and **MAX7219 LED display output**.  
It demonstrates how real-world traffic light behavior can be implemented entirely in **Verilog**, including:

- FSM-based traffic light sequencing  
- Button-debouncing and pedestrian request handling  
- Visual countdown with MAX7219 LED matrices and smiley faces  

![WokwiSimulation](docs/WokwiSimulation.png)

The system is designed for **1 MHz clock operation** and has been simulated in **GTKWave** and validated in **Wokwi**.

---

## Documentation

For detailed information about the project, see the full documentation:

- [Read the documentation for project](docs/info.md)

---

## How to Test with Hardware

### 1. Connect the LEDs

| Output pin | Function |
|------------|---------|
| uo[0]      | Car red |
| uo[1]      | Car yellow |
| uo[2]      | Car green |
| uo[3]      | Pedestrian red (right) |
| uo[4]      | Pedestrian green (right) |
| uo[5]      | Pedestrian red (left) |
| uo[6]      | Pedestrian green (left) |

### 2. Connect the Inputs

| Input pin | Function |
|-----------|---------|
| ui[0]     | Main ON/OFF switch |
| ui[1]     | Pedestrian request (left) |
| ui[2]     | Pedestrian request (right) |

### 3. Connect the MAX7219 LED Modules

| Pin | Function |
|-----|---------|
| uio[0] | DIN (left module) |
| uio[1] | CLK (left module) |
| uio[2] | CS  (left module) |
| uio[3] | DIN (right module) |
| uio[4] | CLK (right module) |
| uio[5] | CS  (right module) |
| uio[6] | Pedestrian request indicator (left) |
| uio[7] | Pedestrian request indicator (right) |

### 4. Power On and Observe

- The traffic lights will run through the automatic sequence  
- Pedestrian requests will trigger early green if pressed during red  
- The LED matrices show the countdown and the corresponding smiley face  
- Request indicators light up when the system acknowledges a pedestrian input  

---

## What is Tiny Tapeout?

Tiny Tapeout is an educational project that aims to make it easier and cheaper than ever to get your digital and analog designs manufactured on a real chip.

To learn more and get started, visit https://tinytapeout.com.
