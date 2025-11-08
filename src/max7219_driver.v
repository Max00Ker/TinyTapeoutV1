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
module max7219_driver(
    input wire clk,             // FPGA clock (1MHz)
    input wire rst_n,
    input wire [3:0] digit,     // digit to display
    input wire display_active,  // display LED on or off
    output wire DIN,            // Data to MAX7219
    output reg CS,              // Chip select
    output wire SCLK            // Serial Clock
);

    // ===============================
    // SPI interface
    // ===============================
    reg  [15:0] spi_data;
    reg         start_transfer;
    wire        busy_spi;

    spi_master spi (
        .clk    (clk),
        .rst_n  (rst_n),
        .start  (start_transfer),
        .data_in(spi_data),
        .DIN    (DIN),
        .SCLK   (SCLK),
        .busy   (busy_spi)
    );

    // font pattern from 0 to 9 + 10,11,12 smileys
    reg [7:0] font [0:12][0:7];
        initial begin
            // Digit 0
            font[0][0] = 8'b00111100;
            font[0][1] = 8'b01100110;
            font[0][2] = 8'b01100110;
            font[0][3] = 8'b01111110;
            font[0][4] = 8'b01100110;
            font[0][5] = 8'b01100110;
            font[0][6] = 8'b00111100;
            font[0][7] = 8'b00000000;

            // Digit 1
            font[1][0] = 8'b00011000;
            font[1][1] = 8'b00111000;
            font[1][2] = 8'b00011000;
            font[1][3] = 8'b00011000;
            font[1][4] = 8'b00011000;
            font[1][5] = 8'b00011000;
            font[1][6] = 8'b01111110;
            font[1][7] = 8'b00000000;

            // Digit 2
            font[2][0] = 8'b00111100;
            font[2][1] = 8'b01100110;
            font[2][2] = 8'b00000110;
            font[2][3] = 8'b00001100;
            font[2][4] = 8'b00110000;
            font[2][5] = 8'b01100000;
            font[2][6] = 8'b01111110;
            font[2][7] = 8'b00000000;

            // Digit 3
            font[3][0] = 8'b00111100;
            font[3][1] = 8'b01100110;
            font[3][2] = 8'b00000110;
            font[3][3] = 8'b00011100;
            font[3][4] = 8'b00000110;
            font[3][5] = 8'b01100110;
            font[3][6] = 8'b00111100;
            font[3][7] = 8'b00000000;

            // Digit 4
            font[4][0] = 8'b00001100;
            font[4][1] = 8'b00011100;
            font[4][2] = 8'b00101100;
            font[4][3] = 8'b01001100;
            font[4][4] = 8'b01111110;
            font[4][5] = 8'b00001100;
            font[4][6] = 8'b00011110;
            font[4][7] = 8'b00000000;

            // Digit 5
            font[5][0] = 8'b01111110;
            font[5][1] = 8'b01100000;
            font[5][2] = 8'b01111100;
            font[5][3] = 8'b00000110;
            font[5][4] = 8'b00000110;
            font[5][5] = 8'b01100110;
            font[5][6] = 8'b00111100;
            font[5][7] = 8'b00000000;

            // Digit 6
            font[6][0] = 8'b00111100;
            font[6][1] = 8'b01100110;
            font[6][2] = 8'b01100000;
            font[6][3] = 8'b01111100;
            font[6][4] = 8'b01100110;
            font[6][5] = 8'b01100110;
            font[6][6] = 8'b00111100;
            font[6][7] = 8'b00000000;

            // Digit 7
            font[7][0] = 8'b01111110;
            font[7][1] = 8'b01100110;
            font[7][2] = 8'b00001100;
            font[7][3] = 8'b00011000;
            font[7][4] = 8'b00110000;
            font[7][5] = 8'b00110000;
            font[7][6] = 8'b00110000;
            font[7][7] = 8'b00000000;

            // Digit 8
            font[8][0] = 8'b00111100;
            font[8][1] = 8'b01100110;
            font[8][2] = 8'b01100110;
            font[8][3] = 8'b00111100;
            font[8][4] = 8'b01100110;
            font[8][5] = 8'b01100110;
            font[8][6] = 8'b00111100;
            font[8][7] = 8'b00000000;

            // Digit 9
            font[9][0] = 8'b00111100;
            font[9][1] = 8'b01100110;
            font[9][2] = 8'b01100110;
            font[9][3] = 8'b00111110;
            font[9][4] = 8'b00000110;
            font[9][5] = 8'b01100110;
            font[9][6] = 8'b00111100;
            font[9][7] = 8'b00000000;

            // Smiley 10: Happy
            font[10][0] = 8'b00111100;
            font[10][1] = 8'b01000010;
            font[10][2] = 8'b10100101; 
            font[10][3] = 8'b10000001;
            font[10][4] = 8'b10100101; 
            font[10][5] = 8'b10011001;
            font[10][6] = 8'b01000010;
            font[10][7] = 8'b00111100;

            // Smiley 11: Neutral
            font[11][0] = 8'b00111100;
            font[11][1] = 8'b01000010;
            font[11][2] = 8'b10100101; 
            font[11][3] = 8'b10000001;
            font[11][4] = 8'b10011101; 
            font[11][5] = 8'b10000001;
            font[11][6] = 8'b01000010;
            font[11][7] = 8'b00111100;

            // Smiley 12: Sad
            font[12][0] = 8'b00111100;
            font[12][1] = 8'b01000010;
            font[12][2] = 8'b10100101; 
            font[12][3] = 8'b10000001;
            font[12][4] = 8'b10011001; 
            font[12][5] = 8'b10100101; 
            font[12][6] = 8'b01000010;
            font[12][7] = 8'b00111100;

    end

    // States
    parameter INIT_SHUTDOWN    = 3'd0;
    parameter INIT_DECODE      = 3'd1;
    parameter INIT_SCANLIMIT   = 3'd2;
    parameter INIT_INTENSITY   = 3'd3;
    parameter INIT_DISPLAYTEST = 3'd4;
    parameter SEND_ROW         = 3'd5;
    parameter WAIT_SPI         = 3'd6;

    reg [2:0] row_index;
    reg [2:0] state;
    reg [2:0] next_state;

    // debug registers for GTKWave-sim
    `ifdef SIM
        reg [7:0] display_row0;
        reg [7:0] display_row1;
        reg [7:0] display_row2;
        reg [7:0] display_row3;
        reg [7:0] display_row4;
        reg [7:0] display_row5;
        reg [7:0] display_row6;
        reg [7:0] display_row7;
    `endif

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= INIT_SHUTDOWN;
            row_index <= 0;
            CS <= 1;
            start_transfer <= 0;
        end else begin
            case (state)
                // ----------------------
                // INIT MAX7219
                // ----------------------
                INIT_SHUTDOWN: begin 
                    // Shutdown register -> normal mode
                    spi_data <= {8'h0C, 8'h01}; // pattern {register address, value}
                    CS <= 0;
                    start_transfer <= 1;
                    state <= WAIT_SPI;
                    next_state <= INIT_DECODE;
                end
                INIT_DECODE: begin
                    // Decode register -> no decode for digits 7-0
                    spi_data <= {8'h09, 8'h00};
                    CS <= 0;
                    start_transfer <= 1;
                    state <= WAIT_SPI;
                    next_state <= INIT_SCANLIMIT;
                end
                INIT_SCANLIMIT: begin
                    // Scan limit register -> scan all 8 digits
                    spi_data <= {8'h0B, 8'h07}; 
                    CS <= 0;
                    start_transfer <= 1;
                    state <= WAIT_SPI;
                    next_state <= INIT_INTENSITY;
                end 
                INIT_INTENSITY: begin
                    // Intensity register -> max intensity
                    spi_data <= {8'h0A, 8'h0F}; 
                    CS <= 0;
                    start_transfer <= 1;
                    state <= WAIT_SPI;
                    next_state <= INIT_DISPLAYTEST;
                end
                INIT_DISPLAYTEST: begin
                    // Display test register -> no display test
                    spi_data <= {8'h0F, 8'h00}; 
                    CS <= 0;
                    start_transfer <= 1;
                    state <= WAIT_SPI;
                    next_state <= SEND_ROW;
                end
                // End of Init

                // ----------------------
                // send digit
                // ----------------------
                SEND_ROW: begin                 
                    if (display_active)
                        // {address 00000001, data 00000000}
                        spi_data <= {8'h01 + {5'b0, row_index}, font[digit][row_index]};
                    else
                        // all LED's off
                        spi_data <= {8'h01 + {5'b0, row_index}, 8'b00000000};

                    // for simulation
                    `ifdef SIM
                        display_row0 <= font[digit][0];
                        display_row1 <= font[digit][1];
                        display_row2 <= font[digit][2];
                        display_row3 <= font[digit][3];
                        display_row4 <= font[digit][4];
                        display_row5 <= font[digit][5];
                        display_row6 <= font[digit][6];
                        display_row7 <= font[digit][7];
                    `endif
                    CS <= 0;
                    start_transfer <= 1;
                    state <= WAIT_SPI;
                    next_state <= SEND_ROW;
                end
                
                // ----------------------
                // Wait for SPI-Master
                // ----------------------
                WAIT_SPI: begin
                    start_transfer <= 0;  // nur 1 Takt impuls
                    if (!busy_spi && !start_transfer) begin
                        CS <= 1;
                        row_index <= (row_index == 7) ? 0 : row_index + 1;
                        state <= next_state;
                    end
                end
                default: state <= INIT_SHUTDOWN;
            endcase
        end
    end
endmodule


