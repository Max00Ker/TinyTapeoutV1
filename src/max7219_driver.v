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

    reg [7:0] row_data;

    always @(*) begin
        case (digit)
            4'd0: case(row_index) // Digit 0
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b01100110;
                3'd3: row_data = 8'b01111110;
                3'd4: row_data = 8'b01100110;
                3'd5: row_data = 8'b01100110;
                3'd6: row_data = 8'b00111100;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd1: case(row_index) // Digit 1
                3'd0: row_data = 8'b00011000;
                3'd1: row_data = 8'b00111000;
                3'd2: row_data = 8'b00011000;
                3'd3: row_data = 8'b00011000;
                3'd4: row_data = 8'b00011000;
                3'd5: row_data = 8'b00011000;
                3'd6: row_data = 8'b01111110;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd2: case(row_index) // Digit 2
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b00000110;
                3'd3: row_data = 8'b00001100;
                3'd4: row_data = 8'b00110000;
                3'd5: row_data = 8'b01100000;
                3'd6: row_data = 8'b01111110;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd3: case(row_index) // Digit 3
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b00000110;
                3'd3: row_data = 8'b00011100;
                3'd4: row_data = 8'b00000110;
                3'd5: row_data = 8'b01100110;
                3'd6: row_data = 8'b00111100;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd4: case(row_index) // Digit 4
                3'd0: row_data = 8'b00001100;
                3'd1: row_data = 8'b00011100;
                3'd2: row_data = 8'b00101100;
                3'd3: row_data = 8'b01001100;
                3'd4: row_data = 8'b01111110;
                3'd5: row_data = 8'b00001100;
                3'd6: row_data = 8'b00011110;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd5: case(row_index) // Digit 5
                3'd0: row_data = 8'b01111110;
                3'd1: row_data = 8'b01100000;
                3'd2: row_data = 8'b01111100;
                3'd3: row_data = 8'b00000110;
                3'd4: row_data = 8'b00000110;
                3'd5: row_data = 8'b01100110;
                3'd6: row_data = 8'b00111100;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd6: case(row_index) // Digit 6
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b01100000;
                3'd3: row_data = 8'b01111100;
                3'd4: row_data = 8'b01100110;
                3'd5: row_data = 8'b01100110;
                3'd6: row_data = 8'b00111100;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd7: case(row_index) // Digit 7
                3'd0: row_data = 8'b01111110;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b00001100;
                3'd3: row_data = 8'b00011000;
                3'd4: row_data = 8'b00110000;
                3'd5: row_data = 8'b00110000;
                3'd6: row_data = 8'b00110000;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd8: case(row_index) // Digit 8
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b01100110;
                3'd3: row_data = 8'b00111100;
                3'd4: row_data = 8'b01100110;
                3'd5: row_data = 8'b01100110;
                3'd6: row_data = 8'b00111100;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd9: case(row_index) // Digit 9
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01100110;
                3'd2: row_data = 8'b01100110;
                3'd3: row_data = 8'b00111110;
                3'd4: row_data = 8'b00000110;
                3'd5: row_data = 8'b01100110;
                3'd6: row_data = 8'b00111100;
                3'd7: row_data = 8'b00000000;
            endcase

            4'd10: case(row_index) // Smiley Happy
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01000010;
                3'd2: row_data = 8'b10100101;
                3'd3: row_data = 8'b10000001;
                3'd4: row_data = 8'b10100101;
                3'd5: row_data = 8'b10011001;
                3'd6: row_data = 8'b01000010;
                3'd7: row_data = 8'b00111100;
            endcase

            4'd11: case(row_index) // Smiley Neutral
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01000010;
                3'd2: row_data = 8'b10100101;
                3'd3: row_data = 8'b10000001;
                3'd4: row_data = 8'b10011101;
                3'd5: row_data = 8'b10000001;
                3'd6: row_data = 8'b01000010;
                3'd7: row_data = 8'b00111100;
            endcase

            4'd12: case(row_index) // Smiley Sad
                3'd0: row_data = 8'b00111100;
                3'd1: row_data = 8'b01000010;
                3'd2: row_data = 8'b10100101;
                3'd3: row_data = 8'b10000001;
                3'd4: row_data = 8'b10011001;
                3'd5: row_data = 8'b10100101;
                3'd6: row_data = 8'b01000010;
                3'd7: row_data = 8'b00111100;
            endcase

            default: row_data = 8'b00000000;
        endcase
    end

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
                        spi_data <= {8'h01 + {5'b0, row_index}, row_data};
                    else
                        // all LED's off
                        spi_data <= {8'h01 + {5'b0, row_index}, 8'b00000000};

                    // for simulation
                    // `ifdef SIM
                    //     display_row0 <= get_font(digit, 0);
                    //     display_row1 <= get_font(digit, 1);
                    //     display_row2 <= get_font(digit, 2);
                    //     display_row3 <= get_font(digit, 3);
                    //     display_row4 <= get_font(digit, 4);
                    //     display_row5 <= get_font(digit, 5);
                    //     display_row6 <= get_font(digit, 6);
                    //     display_row7 <= get_font(digit, 7);
                    // `endif
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


