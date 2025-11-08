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

module clk_divider #(parameter input_clk_frequency = 1000000, parameter output_clk_frequency = 1) (
    input clk_in, 
    input rst_n,
    output reg clk_out
);
    reg [19:0] counter;
    localparam divider = input_clk_frequency / output_clk_frequency;
    localparam clock_counter = divider/2;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter >= clock_counter-1) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else
                counter <= counter + 1;
        end
    end
endmodule
