/*
 * Top-modul for traffic light
 * Copyright (c) 2025 Maximilian Kernmaier
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

`include "traffic_light.v"

module tt_um_Max00Ker_Traffic_Light_Top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    // Simulation / Real Clock
    `ifdef SIM
        localparam MAIN_CLK_FREQ = 1_000;      // 1 kHz für schnelle Simulation
    `else
        localparam MAIN_CLK_FREQ = 1_000_000;  // 1 MHz für echtes Board
    `endif

    // Instantiate Traffic Light
    tt_um_Max00Ker_Traffic_Light traffic_light_inst (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Unused inputs
    wire _unused = &{ui_in[7:1], uio_in[7:0], ena};

endmodule
