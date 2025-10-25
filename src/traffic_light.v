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

  // interne Signale
  reg [2:0] cur_state;
  reg [3:0] clk_counter;
  reg [3:0] blink_counter;
  reg       blink;
  reg [3:0] remaining_time;
  reg [6:0] seven_seg;

  // --- States ---
  localparam IDLE          = 3'd0;
  localparam S_RED         = 3'd1;
  localparam S_RED_YELLOW  = 3'd2;
  localparam S_GREEN       = 3'd3;
  localparam S_GREEN_BLINK = 3'd4;
  localparam S_YELLOW      = 3'd5;

  // --- Zeiten ---
  localparam T_RED         = 4'd9;
  localparam T_RED_YELLOW  = 4'd3;
  localparam T_GREEN       = 4'd9;
  localparam T_GREEN_BLINK = 4'd5;
  localparam T_YELLOW      = 4'd3;
  localparam T_IDLE        = 4'd6;
  localparam BLINK_VAL     = 4'd1;

  // --- FSM ---
  always @(posedge clk) begin
    if (!rst_n) begin
      cur_state   <= IDLE;
      clk_counter <= 0;
    end else begin
      case (cur_state)
        IDLE: begin
          if (clk_counter >= T_IDLE)
            cur_state <= S_RED;
          else
            clk_counter <= clk_counter + 1;
        end
        S_RED: begin
          if (clk_counter >= T_RED) begin
            cur_state <= S_RED_YELLOW;
            clk_counter <= 0;
          end else clk_counter <= clk_counter + 1;
        end
        S_RED_YELLOW: begin
          if (clk_counter >= T_RED_YELLOW) begin
            cur_state <= S_GREEN;
            clk_counter <= 0;
          end else clk_counter <= clk_counter + 1;
        end
        S_GREEN: begin
          if (clk_counter >= T_GREEN) begin
            cur_state <= S_GREEN_BLINK;
            clk_counter <= 0;
          end else clk_counter <= clk_counter + 1;
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

  // --- blink generator ---
  always @(posedge clk) begin
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

  // --- Remaining time
  always @(*) begin
    case (cur_state)
      S_RED: remaining_time = T_RED - clk_counter;
      default: remaining_time = 0;
    endcase
  end

  // --- 7-Segment Anzeige (an uio_out[0..6])
  always @(*) begin
    case (remaining_time)
      4'd0: seven_seg = 7'b0111111;
      4'd1: seven_seg = 7'b0000110;
      4'd2: seven_seg = 7'b1011011;
      4'd3: seven_seg = 7'b1001111;
      4'd4: seven_seg = 7'b1100110;
      4'd5: seven_seg = 7'b1101101;
      4'd6: seven_seg = 7'b1111101;
      4'd7: seven_seg = 7'b0000111;
      4'd8: seven_seg = 7'b1111111;
      4'd9: seven_seg = 7'b1101111;
      default: seven_seg = 7'b0000000;
    endcase
  end

  // --- Ampellichter ---
  wire red_light, yellow_light, green_light;
  assign red_light    = (cur_state == S_RED || cur_state == S_RED_YELLOW);
  assign yellow_light = (cur_state == S_YELLOW || cur_state == S_RED_YELLOW || (cur_state == IDLE && blink));
  assign green_light  = (cur_state == S_GREEN || (cur_state == S_GREEN_BLINK && blink));

  // --- Ausgabe zu den TT-Pins ---
  assign uo_out[0] = red_light;
  assign uo_out[1] = yellow_light;
  assign uo_out[2] = green_light;
  assign uo_out[7:3] = 5'b0; // unbenutzt

  // 7-Segment an bidirektionale Pins
  assign uio_out[6:0] = seven_seg;
  assign uio_out[7]   = 1'b0;         // ungenutzter Pin — auf 0 gelegt
  assign uio_oe       = 8'b01111111;  // Bit7 = 0 (Input), Rest = Output
endmodule