// Copyright 2025 Maximilian Kernmaier
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE−2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

`default_nettype none

module tt_um_Max00Ker_Traffic_Light_Top (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,      // enable
    input  wire       clk,      // Main clock
    input  wire       rst_n     // reset (active-low)
);

    // -----------------------
    // Clock generation
    // -----------------------
    wire clk_10Hz;
    wire clk_1kHz;
    wire clk_1MHz;

    `ifdef SIM
        // Values for GTKWave Simulation
        clk_divider #(1000, 10) sim_div10Hz (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_10Hz));
        assign clk_1kHz = clk;
        assign clk_1MHz = clk;
    `else
        // Values for real Hardware
        clk_divider #(1_000_000, 10) hw_div10Hz  (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_10Hz));
        clk_divider #(1_000_000, 1000) hw_div1kHz (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1kHz));
        assign clk_1MHz = clk;
    `endif


    // -----------------------
    // Traffic Light Instantiation
    // -----------------------
    tt_um_Max00Ker_Traffic_Light traffic_light_inst (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk_10Hz(clk_10Hz),
        .clk_1kHz(clk_1kHz),
        .clk_1MHz(clk_1MHz),
        .rst_n(rst_n)
    );

endmodule
