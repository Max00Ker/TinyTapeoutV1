/*
 * Traffic Light Controller
 * Maximilian Kernmaier, 2025
 * SPDX-License-Identifier: Apache-2.0
 */

`ifndef TRAFFIC_LIGHT_V
`define TRAFFIC_LIGHT_V
`default_nettype none

module tt_um_Max00Ker_Traffic_Light (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: input path
    output wire [7:0] uio_out,  // IOs: output path
    output wire [7:0] uio_oe,   // IOs: enable path (active high: 0=input, 1= output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
`define SIM
  // -----------------------------------------
  // ------------- Input Outputs -------------
  // -----------------------------------------

  // --- input pins ---
  wire switch_on_off = ui_in[0];

  // -----------------------------------------
  // -------------- Parameters ---------------
  // -----------------------------------------

  // --- states ---
  localparam IDLE          = 3'd0;
  localparam S_RED         = 3'd1;
  localparam S_RED_YELLOW  = 3'd2;
  localparam S_GREEN       = 3'd3;
  localparam S_GREEN_BLINK = 3'd4;
  localparam S_YELLOW      = 3'd5;

  // --- light durations within states ---
  localparam T_RED              = 5'd20;
  localparam T_RED_YELLOW       = 5'd3;
  localparam T_GREEN            = 5'd20;
  localparam T_GREEN_BLINK      = 5'd6;
  localparam T_YELLOW           = 5'd3;
  localparam T_IDLE             = 5'd6;
  localparam BLINK_VAL          = 5'd1;
  localparam T_COUNTDOWN        = 5'd9;

  // -----------------------------------------
  // ------------ Wires / Regs ---------------
  // -----------------------------------------

  // traffic lights
  wire red_light;
  wire yellow_light;
  wire green_light;

  // pedistrian lights
  wire ped_red_light;
  wire ped_green_light;
  
  // Clock Divider Instances
  wire clk_1Hz; // for Traffic Light
  wire clk_1kHz; // for pedestiran push button
  wire clk_1MHz;

  `ifdef SIM
    // Simulation: schneller Takt, kleinere Timer
    wire clk_1Hz_sim;
    clk_divider #(1000, 1) sim_div(.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1Hz_sim));
    assign clk_1Hz = clk_1Hz_sim;
    assign clk_1kHz = clk;
    assign clk_1MHz = clk_1kHz;
  `else
    // Hardware: echte Frequenzen
    clk_divider #(1000000, 1) hw_div(.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1Hz));
    clk_divider #(1000000, 1000) hw_div2(.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1kHz));
  `endif


  // clk_divider #(1000000, 1) div_1Hz (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1Hz));
  // clk_divider #(1000000, 1000) div_1kHz (.clk_in(clk), .rst_n(rst_n), .clk_out(clk_1kHz)); 
  // assign clk_1MHz = clk;

  // MAX7219
  wire max_din;
  wire max_cs;
  wire max_clk;

  // intern signals
  reg [2:0] cur_state;
  reg [4:0] clk_counter;
  reg [4:0] blink_counter;
  reg       blink;
  reg       LED_on_off;

  // -----------------------------------------
  // --------------- Assigns -----------------
  // -----------------------------------------
  
  assign red_light = (
    cur_state == S_RED || 
    cur_state == S_RED_YELLOW
  );
  assign yellow_light = (
    cur_state == S_YELLOW || 
    cur_state == S_RED_YELLOW ||
    (cur_state == IDLE && blink)
  );
  assign green_light = (
    cur_state == S_GREEN || 
    (cur_state == S_GREEN_BLINK && blink)
  );

  assign ped_red_light = (cur_state == S_YELLOW || cur_state == S_RED_YELLOW || cur_state == S_GREEN || cur_state == S_GREEN_BLINK);
  assign ped_green_light = cur_state == S_RED;

  // --- output pins ---
  assign uo_out[0] = red_light;
  assign uo_out[1] = yellow_light;
  assign uo_out[2] = green_light;
  assign uo_out[3] = ped_red_light;
  assign uo_out[4] = ped_green_light;
  assign uo_out[7:5] = 3'b0; // unused

  // --- bidirectional pins ---
  assign uio_out[0] = max_din;
  assign uio_out[1] = max_cs;
  assign uio_out[2] = max_clk;
  assign uio_out[7:3] = 5'b0; // unused
  assign uio_oe       = 8'b00000111;  // direction 0 (input), 1 (output)


  // -----------------------------------------
  // ------------ Always blocks --------------
  // -----------------------------------------

  // -------------------------
  // --- button debouncing ---
  // -------------------------

  localparam DEBOUNCE_TIME = 50; // number of stable tacts
  wire pushed_button;
  assign pushed_button = ui_in[1];  
  // --- Signale ---
  reg [8:0] debounce_counter = 0; // genug Bits für DEBOUNCE_TIME
  reg debounced_push_button = 0;
  reg button_pressed;
  reg [3:0] countdown; // für die 0..9 Anzeige
  reg countdown_active;
  reg button_release;

  // --- FSM ---
  always @(posedge clk_1Hz) begin
    if (!rst_n) begin
      cur_state   <= IDLE;
      clk_counter <= 0;
      button_pressed <= 0;
      LED_on_off <= 0;
      countdown_active <= 0;
      countdown <= 9;
      button_release <= 0;
      
    end else begin
      if (!switch_on_off) begin // traffic light on / off
        cur_state <= IDLE;
        clk_counter <= 0;
        LED_on_off <=0;
        countdown_active <= 0;
        countdown <= 9;
        button_release <= 0;
      end else begin
        case (cur_state)

          IDLE: begin
            LED_on_off <= 0;
            countdown_active <= 0;
            countdown <= 9;

            if (clk_counter >= T_IDLE) begin
              cur_state <= S_RED;
              clk_counter <= 0;
            end else begin
              clk_counter <= clk_counter + 1;
            end
          end

          S_RED: begin
            if (clk_counter >= T_RED) begin
              cur_state <= S_RED_YELLOW;
              clk_counter <= 0;
            end else begin
              clk_counter <= clk_counter + 1;
            end
          end

          S_RED_YELLOW: begin
            if (clk_counter >= T_RED_YELLOW) begin
              cur_state <= S_GREEN;
              clk_counter <= 0;
            end else clk_counter <= clk_counter + 1;
          end

          S_GREEN: begin
            if (debounced_push_button) begin
              button_pressed <= 1;
            end
            if ((button_pressed && !countdown_active) || (clk_counter == T_GREEN - T_COUNTDOWN)) begin
              LED_on_off <=1;
              countdown_active <= 1;
              countdown <= 9; // Startwert
            end

            if (countdown_active) begin
              if (clk_counter % 1 == 0)
                  countdown <= countdown - 1;
              if (countdown == 0) begin
                  cur_state <= S_GREEN_BLINK;            
                  button_pressed <= 0;
                  LED_on_off <=0;
                  countdown_active <= 0;
                  clk_counter <= 0;    
              end
            end else begin
                clk_counter <= clk_counter + 1;
            end
          end

          S_GREEN_BLINK: begin
            if (clk_counter >= T_GREEN_BLINK) begin
              cur_state <= S_YELLOW;
              clk_counter <= 0;
            end else clk_counter <= clk_counter + 1;
          end

          S_YELLOW: begin
            if (clk_counter >= T_YELLOW) begin
              cur_state <= S_RED;
              clk_counter <= 0;
            end else clk_counter <= clk_counter + 1;
          end

          default: begin
            cur_state   <= IDLE;
            clk_counter <= 0;
          end
        endcase
      end
    end
  end

  // --- Debounce Logik ---
  always @(posedge clk_1kHz) begin
      if (!rst_n) begin
          debounce_counter <= 0;
          debounced_push_button <= 0;
      end else begin
          if (pushed_button) begin               
              if (debounce_counter >= DEBOUNCE_TIME)
                  debounced_push_button <= 1;
              else
                debounce_counter <= debounce_counter + 1;              
          end else begin
              debounce_counter <= 0;
              debounced_push_button <= 0;
          end
      end
  end

  // --- blink generator ---
  always @(posedge clk_1Hz) begin
    if (!rst_n) begin
      blink_counter <= 0;
      blink         <= 0;
    end else if (cur_state == S_GREEN_BLINK || cur_state == IDLE) begin
      if (blink_counter == BLINK_VAL - 1) begin
        blink_counter <= 0;
        blink <= ~blink;
      end else blink_counter <= blink_counter + 1;
    end else begin
      blink_counter <= 0;
      blink <= 0;
    end
  end

  // Display Driver for MAX7219
  max7219_driver display_driver(
    .clk(clk_1MHz),
    .digit(countdown),
    .display_active(LED_on_off),
    .DIN(max_din),
    .CS(max_cs),
    .SCLK(max_clk)
);
endmodule
`endif