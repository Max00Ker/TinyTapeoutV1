module max7219_driver(
    input wire clk,             // FPGA clock (e.g., 1 kHz)
    input wire [3:0] digit,     // digit to display
    input wire display_active,          // display LED on or off
    output reg DIN,             // Data to MAX7219
    output reg CS,              // Chip select
    output reg SCLK             // Serial Clock
);

// font pattern from 0 to 9
reg [7:0] font [0:9][0:7];
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

    end

    // States
    parameter INIT_POWERUP      = 3'd0;
    parameter INIT_DECODE_OFF   = 3'd1;
    parameter INIT_SCAN_ALL     = 3'd2;
    parameter INIT_BRIGHTNESS   = 3'd3;
    parameter INIT_DISPLAY_TEST = 3'd4;
    parameter SEND_ROW_DATA     = 3'd5;
    parameter SPI_TRANSFER      = 3'd6;

    reg [15:0] shift_data; //8bit adress + 8bit data = 16bit
    reg [5:0] bitcount = 0;
    reg [2:0] row_index = 0;
    reg [2:0] state = INIT_POWERUP;
    reg        prev_display_active = 0;

    // debug registers for GTKWave-sim
    reg [7:0] display_row0;
    reg [7:0] display_row1;
    reg [7:0] display_row2;
    reg [7:0] display_row3;
    reg [7:0] display_row4;
    reg [7:0] display_row5;
    reg [7:0] display_row6;
    reg [7:0] display_row7;

    // FSM
    always @(posedge clk) begin
        prev_display_active <= display_active;
        case (state)
            // --- INIT MAX7219
            INIT_POWERUP: begin 
                // Shutdown register -> normal mode
                shift_data <= {8'h0C, 8'h01}; // pattern {register address, value}
                state <= INIT_DECODE_OFF; 
            end
            INIT_DECODE_OFF: begin
                // Decode register -> no decode for digits 7-0
                shift_data <= {8'h09, 8'h00}; 
                state <= INIT_SCAN_ALL; 
            end
            INIT_SCAN_ALL: begin
                // Scan limit register -> scan all 8 digits
                shift_data <= {8'h0B, 8'h07}; 
                state <= INIT_BRIGHTNESS; 
            end 
            INIT_BRIGHTNESS: begin
                // Intensity register -> intensity 21 of 32(max)
                shift_data <= {8'h0A, 8'h0A}; 
                state <= INIT_DISPLAY_TEST; 
            end
            INIT_DISPLAY_TEST: begin
                // Display test register -> no display test
                shift_data <= {8'h0F, 8'h00}; 
                state <= SEND_ROW_DATA; 
            end
            // End of Init

            // normal operation
            // Send row data for current digit
            SEND_ROW_DATA: begin
                if (display_active)
                    // {address 00000001, data 00000000}
                    shift_data <= {8'h01 + {5'b0, row_index}, font[digit][row_index]};
                else
                    // all LED's off
                    shift_data <= {8'h01 + {5'b0, row_index}, 8'b00000000};
                state <= SPI_TRANSFER;
            end
            // --- Send bits over SPI ---
            SPI_TRANSFER: begin
                CS <= 0; 
                DIN <= shift_data[15];
                shift_data <= shift_data << 1; //e.g. shift_data 00000001 -> 00000010
                SCLK <= ~SCLK;
                bitcount <= bitcount + 1;
                if (bitcount == 16) begin
                    CS <= 1;
                    SCLK <= 0;
                    bitcount <= 0;
                    // for simulation
                    case(row_index)
                        0: display_row0 <= display_active ? font[digit][0] : 8'b00000000;
                        1: display_row1 <= display_active ? font[digit][1] : 8'b00000000;
                        2: display_row2 <= display_active ? font[digit][2] : 8'b00000000;
                        3: display_row3 <= display_active ? font[digit][3] : 8'b00000000;
                        4: display_row4 <= display_active ? font[digit][4] : 8'b00000000;
                        5: display_row5 <= display_active ? font[digit][5] : 8'b00000000;
                        6: display_row6 <= display_active ? font[digit][6] : 8'b00000000;
                        7: display_row7 <= display_active ? font[digit][7] : 8'b00000000;
                    endcase
                    if (row_index == 7)
                        row_index <= 0;
                    else
                        row_index <= row_index + 1;
                    state <= SEND_ROW_DATA;
                end
            end
            default: state <= INIT_POWERUP;
        endcase
    end
endmodule