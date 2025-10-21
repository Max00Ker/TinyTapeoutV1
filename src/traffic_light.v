module tt_um_Max00Ker (
  // definitions of signals, which are visible from outside
  input  wire       clk,
  input  wire       rst_n,
  input  wire       ena,
  output reg [2:0]  cur_state,  
  output reg        red_light,
  output reg        yellow_light,
  output reg        green_light,
  output reg [6:0]  seven_seg
);

  // --- States ---
  localparam IDLE    = 3'd0;  //equals yellow blinking traffic light
  localparam S_RED = 3'd1;
  localparam S_RED_YELLOW = 3'd2;
  localparam S_GREEN = 3'd3;
  localparam S_GREEN_BLINK = 3'd4;
  localparam S_YELLOW = 3'd5;

  // --- Internal registers ---
  reg [3:0] clk_counter;
  reg [3:0] blink_counter; // 4 Bit reicht bis 15
  reg       blink;
  reg [3:0] remaining_time;

  // --- Zeitkonstanten für jeden Zustand ---
  localparam T_RED         = 4'd10  - 4'd1;
  localparam T_RED_YELLOW  = 4'd3  - 4'd1;
  localparam T_GREEN       = 4'd10  - 4'd1;
  localparam T_GREEN_BLINK = 4'd8  - 4'd1; //3x1s blink
  localparam T_YELLOW      = 4'd3  - 4'd1;
  localparam T_IDLE        = 4'd6  - 4'd1;
  
  localparam BLINK_VAL = 4'd1;

  // --- FSM ---
  always @(posedge clk) begin
    if (!rst_n) begin
      cur_state <= IDLE;
      clk_counter <= 0;

    end else begin

      case (cur_state)

        IDLE: begin
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
          end else begin 
            clk_counter <= clk_counter + 1;
          end
        end

        S_GREEN: begin
          if (clk_counter >= T_GREEN) begin  
            cur_state <= S_GREEN_BLINK;
            clk_counter <= 0; 
          end else begin 
            clk_counter <= clk_counter + 1;
          end
        end

        S_GREEN_BLINK: begin
          if (clk_counter >= T_GREEN_BLINK) begin  
            cur_state <= S_YELLOW;
            clk_counter <= 0; 
          end else begin 
            clk_counter <= clk_counter + 1;
          end
        end

        S_YELLOW: begin
          if (clk_counter >= T_YELLOW) begin 
            cur_state <= S_RED;
            clk_counter <= 0; 
          end else begin 
            clk_counter <= clk_counter + 1;
          end
        end

        default: begin
          cur_state <= IDLE;
          clk_counter <= 0;
        end
      endcase
    end
  end


  // --- blink generator ---
  always @(posedge clk) begin
    if (!rst_n) begin
      blink_counter <= 0;
      blink     <= 0;
    end else begin
      if (cur_state == S_GREEN_BLINK || cur_state == IDLE) begin
        // blink state active
        if (blink_counter == BLINK_VAL - 1) begin
          blink_counter <= 0;
          blink <= ~blink;
        end else begin
          blink_counter <= blink_counter + 1;
        end
      end else begin
        // otherwise reset blink values
        blink_counter <= 0;
        blink <= 0;
      end
    end
  end

  always @(*) begin
    case (remaining_time)
      4'd0: seven_seg = 7'b0000000; // 0
      4'd1: seven_seg = 7'b0000110; // 1
      4'd2: seven_seg = 7'b1011011; // 2
      4'd3: seven_seg = 7'b1001111; // 3
      4'd4: seven_seg = 7'b1100110; // 4
      4'd5: seven_seg = 7'b1101101; // 5
      4'd6: seven_seg = 7'b1111101; // 6
      4'd7: seven_seg = 7'b0000111; // 7
      4'd8: seven_seg = 7'b1111111; // 8
      4'd9: seven_seg = 7'b1101111; // 9
      default: seven_seg = 7'b0000000;
    endcase
  end

  always @(*) begin
    case(cur_state)
      S_RED: remaining_time = T_RED - clk_counter;
      default: remaining_time = 0;
    endcase
  end

  // --- Output ---
  always @(*) begin
    // default all lights off
    red_light    = 0;
    yellow_light = 0;
    green_light  = 0;

    case (cur_state)
      IDLE: begin
        yellow_light = blink;
      end
      S_RED: begin
        red_light = 1;
      end
      S_RED_YELLOW: begin
        red_light = 1;
        yellow_light = 1;
      end
      S_GREEN: begin
        green_light = 1;
      end
      S_GREEN_BLINK: begin
        green_light = blink;
      end
      S_YELLOW: begin
        yellow_light = 1;
      end
      default:;

    endcase
  end
endmodule
