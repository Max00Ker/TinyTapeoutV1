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


`ifndef TRAFFIC_LIGHT_V
`define TRAFFIC_LIGHT_V
`default_nettype none

module tt_um_Max00Ker_Traffic_Light (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: input path
    output wire [7:0] uio_out,  // IOs: output path
    output wire [7:0] uio_oe,   // IOs: enable path
    input  wire       ena,      // enable
    input  wire       clk,      // 1MHz
    input  wire       rst_n     // active-low reset
);

    // -----------------------
    // Clock generation
    // -----------------------
    // wire clk_10Hz;
    // wire clk_1kHz;
    // wire clk_1MHz;
    wire ena_1kHz, ena_10Hz;

    `ifdef SIM
        // Values for GTKWave Simulation
        // clk_divider #(1000, 10) sim_div10Hz (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_10Hz));
        // assign clk_1kHz = clk;
        // assign clk_1MHz = clk;
        clk_enable #(1000, 10)   div10 (.clk(clk), .rst_n(rst_n), .ena_pulse(ena_10Hz));
        clk_enable #(1000, 1000)   div1k (.clk(clk), .rst_n(rst_n), .ena_pulse(ena_1kHz));
        
    `else
        // Values for real Hardware
        // clk_divider #(1_000_000, 10) hw_div10Hz  (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_10Hz));
        // clk_divider #(1_000_000, 1000) hw_div1kHz (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1kHz));
        // assign clk_1MHz = clk;
        clk_enable #(1_000_000, 1000) div1k (.clk(clk), .rst_n(rst_n), .ena_pulse(ena_1kHz));
        clk_enable #(1_000_000, 10)   div10 (.clk(clk), .rst_n(rst_n), .ena_pulse(ena_10Hz));
    `endif

    // -----------------------
    // States & Parameters
    // -----------------------
    localparam C_IDLE        = 3'd0;
    localparam C_RED         = 3'd1;
    localparam C_RED_YELLOW  = 3'd2;
    localparam C_GREEN       = 3'd3;
    localparam C_GREEN_BLINK = 3'd4;
    localparam C_YELLOW      = 3'd5;

    localparam P_IDLE        = 2'd0;
    localparam P_RED         = 2'd1;
    localparam P_GREEN       = 2'd2;
    localparam P_GREEN_BLINK = 2'd3;

    localparam T_RED         = 8'd150;
    localparam T_RED_YELLOW  = 8'd10;
    localparam T_GREEN       = 8'd150;
    localparam T_GREEN_BLINK = 8'd40;
    localparam T_YELLOW      = 8'd30;
    localparam T_COUNTDOWN   = 8'd90;
    localparam BLINK_VAL     = 8'd5;
    localparam DEBOUNCE_TIME = 9'd50;

    // -----------------------
    // Registers
    // -----------------------
    reg [2:0] car_state;
    reg [7:0] car_counter;
    reg [7:0] blink_counter;
    reg       blink;

    reg [1:0] ped_state;


    reg [3:0] countdown;
    reg [3:0] countdown_counter;
    reg       countdown_active;

    reg [8:0] global_counter;
    reg [8:0] debounce_counter;
    reg       early_ped_green;
    reg       pushed_left;
    reg       pushed_right;

    // -----------------------
    // Input wires
    // -----------------------
    wire switch_traffic_light_on = ui_in[0];
    wire ped_request_left = ui_in[1];
    wire ped_request_right = ui_in[2];
    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, ui_in[3], ui_in[4], ui_in[5], ui_in[6], ui_in[7], uio_in, 1'b0};

    // -----------------------
    // Lights
    // -----------------------
    wire car_red_light    = (car_state == C_RED || car_state == C_RED_YELLOW);
    wire car_yellow_light = (car_state == C_YELLOW || car_state == C_RED_YELLOW || (car_state == C_IDLE && blink));
    wire car_green_light  = (car_state == C_GREEN || (car_state == C_GREEN_BLINK && blink));

    wire ped_red_light   = ped_state == P_RED && ped_state != P_IDLE;
    wire ped_green_light = (ped_state == P_GREEN || (ped_state == P_GREEN_BLINK && blink)) && ped_state != P_IDLE;
    

    // -----------------------
    // Output pins
    // -----------------------
    // car light
    assign uo_out[0] = car_red_light;
    assign uo_out[1] = car_yellow_light;
    assign uo_out[2] = car_green_light;
    // pedestrian light left
    assign uo_out[3] = ped_red_light;
    assign uo_out[4] = ped_green_light;
    // pedestrian light right
    assign uo_out[5] = ped_red_light;
    assign uo_out[6] = ped_green_light;
    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out[7] = 0;

    // MAX7219 Display
    wire DIN, CS, SCLK;
    // -----------------------
    // Bidirectional pins
    // -----------------------
    assign uio_out[0] = DIN;
    assign uio_out[1] = CS;
    assign uio_out[2] = SCLK;
    assign uio_out[3] = DIN;
    assign uio_out[4] = CS;
    assign uio_out[5] = SCLK;
    assign uio_out[6] = pushed_left;
    assign uio_out[7] = pushed_right;
    assign uio_oe = 8'b11111111;

    // -----------------------
    // Car FSM & Pedestrian FSM
    // -----------------------
    always @(posedge clk or negedge rst_n) begin
    // always @(posedge clk_10Hz or negedge rst_n) begin
        if (!rst_n) begin
            car_state <= C_IDLE;
            car_counter <= 0;
            ped_state <= P_IDLE;
            countdown <= 9;
            countdown_active <= 0;
            global_counter <= 0;

            blink_counter <= 0;
            blink <= 0;
            debounce_counter <= 0;
            early_ped_green <= 0;
            pushed_left <=0;
            pushed_right <=0;
        end else if (ena_10Hz) begin
            if (!switch_traffic_light_on) begin
                car_state <= C_IDLE;
                car_counter <= 0;
                ped_state <= P_IDLE;
                countdown_active <= 0;
                global_counter <= 0;
            end else begin
                // Car FSM
                global_counter <= global_counter + 1;
                case(car_state)
                    C_IDLE: begin
                    if(switch_traffic_light_on) begin
                        car_state <= C_RED;
                        car_counter <= 0;
                    end
                    end
                    C_RED: begin
                        if(car_counter >= T_RED) begin
                            car_state <= C_RED_YELLOW;
                            car_counter <= 0;
                        end else car_counter <= car_counter + 1;
                    end
                    C_RED_YELLOW: begin
                        if(car_counter >= T_RED_YELLOW) begin
                            car_state <= C_GREEN;
                            car_counter <= 0;
                            global_counter <= 0;
                        end else car_counter <= car_counter + 1;
                    end
                    C_GREEN: begin
                        if((early_ped_green && countdown==7) || car_counter >= T_GREEN) begin
                            car_state <= C_GREEN_BLINK;
                            car_counter <= 0;
                        end else car_counter <= car_counter + 1;
                    end
                    C_GREEN_BLINK: begin
                        if(car_counter >= T_GREEN_BLINK) begin
                            car_state <= C_YELLOW;
                            car_counter <= 0;
                        end else car_counter <= car_counter + 1;
                    end
                    C_YELLOW: begin
                        if(car_counter >= T_YELLOW) begin
                            car_state <= C_RED;
                            car_counter <= 0;
                        end else car_counter <= car_counter + 1;
                    end
                    default: car_state <= C_IDLE;
                endcase

                // Pedestrian FSM
                case(ped_state)
                    P_IDLE: begin
                    if(switch_traffic_light_on) 
                        ped_state <= P_RED;
                    end

                    P_RED: begin
                    if(car_state == C_RED) begin 
                        ped_state <= P_GREEN; 
                    end
                    if (!countdown_active && !early_ped_green) begin
                        countdown <= 12; //sad smiley
                    end
                    end
                
                    P_GREEN: begin
                    if(car_state == C_RED && car_counter >= T_RED-T_GREEN_BLINK) begin 
                        ped_state <= P_GREEN_BLINK; 
                    end
                    if (!countdown_active && !early_ped_green) begin
                        countdown <= 10; //happy smiley
                    end
                    end

                    P_GREEN_BLINK: begin
                    if(car_state == C_RED_YELLOW) begin 
                        ped_state <= P_RED; 
                    end
                    if (!countdown_active && !early_ped_green) begin
                        countdown <= 11; //neutral smiley
                    end
                    end
                endcase

                // Countdown
                if ((early_ped_green||(global_counter >= T_GREEN + T_GREEN_BLINK + T_YELLOW - T_COUNTDOWN-7) && car_state == C_GREEN && ped_state == P_RED) && !countdown_active) begin
                    countdown_active <= 1;
                    countdown_counter <= 0;
                    countdown <= 9;
                end

                if(countdown_active) begin
                    countdown_counter <= countdown_counter + 1;
                    if(countdown_counter >= 9) begin
                        countdown_counter <= 0;
                        if(countdown == 0) begin
                            countdown_active <= 0;
                            countdown <= 9;
                        end else begin
                            countdown <= countdown-1;
                        end
                    end
                end
            end
            // -----------------------
            // Blink generator
            // -----------------------
            if (car_state == C_GREEN_BLINK || car_state == C_IDLE || ped_state == P_GREEN_BLINK) begin
                if (blink_counter == BLINK_VAL-1) begin
                    blink_counter <= 0;
                    blink <= ~blink;
                end else begin
                    blink_counter <= blink_counter + 1;
                end
            end else begin
                blink_counter <= 0;
                blink <= 0;
            end
        // -----------------------
        // Debounce
        // -----------------------
        end else if (ena_1kHz) begin
            if ((ped_request_left || ped_request_right) && car_state==C_GREEN && !early_ped_green) begin
                if(debounce_counter >= DEBOUNCE_TIME) begin
                    early_ped_green <= 1;
                    if(ped_request_left) begin
                        pushed_left<=1;
                    end else begin
                        pushed_right <=1;
                    end
                end
                else begin
                    debounce_counter <= debounce_counter + 1;
                end
            end else begin
                debounce_counter <= 0;
            end
            if(early_ped_green && countdown == 0) begin
                early_ped_green <= 0;
                pushed_left <= 0;
                pushed_right <= 0;
            end
        end
    end

    // // -----------------------
    // // Blink generator
    // // -----------------------
    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         blink_counter <= 0;
    //         blink <= 0;
    //     end if(ena_10Hz) begin
    //         if (car_state == C_GREEN_BLINK || car_state == C_IDLE || ped_state == P_GREEN_BLINK) begin
    //             if (blink_counter == BLINK_VAL-1) begin
    //                 blink_counter <= 0;
    //                 blink <= ~blink;
    //             end else begin
    //                 blink_counter <= blink_counter + 1;
    //             end
    //         end else begin
    //             blink_counter <= 0;
    //             blink <= 0;
    //         end
    //     end
    // end

    // -----------------------
    // Debounce
    // -----------------------
    // always @(posedge clk or negedge rst_n) begin
    //     if (!rst_n) begin
    //         debounce_counter <= 0;
    //         early_ped_green <= 0;
    //     end if(ena_1kHz) begin
    //         if ((ped_request_left || ped_request_right) && car_state==C_GREEN && !early_ped_green) begin
    //             if(debounce_counter >= DEBOUNCE_TIME) begin
    //                 early_ped_green <= 1;
    //             end
    //             else begin
    //                 debounce_counter <= debounce_counter + 1;
    //             end
    //         end else begin
    //             debounce_counter <= 0;
    //         end
    //         if(early_ped_green && countdown == 0) begin
    //             early_ped_green <= 0;
    //         end
    //     end
    // end

    // -----------------------
    // Display
    // -----------------------
    max7219_driver matrix_driver (
      .clk(clk),
      .rst_n(rst_n),
      .digit(countdown),
      .display_active(countdown_active),
      .DIN(DIN),
      .CS(CS),
      .SCLK(SCLK)
    );

endmodule
`endif