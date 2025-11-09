module clk_enable #(
    parameter integer INPUT_FREQ  = 1_000_000,
    parameter integer TARGET_FREQ = 10
)(
    input  wire clk,
    input  wire rst_n,
    output reg  ena_pulse   // 1 cycle high
);
    localparam DIV = INPUT_FREQ / TARGET_FREQ;

    reg [31:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter   <= 0;
            ena_pulse <= 0;
        end else begin
            if (counter >= DIV-1) begin
                counter   <= 0;
                ena_pulse <= 1'b1;   // 1 CLK period high
            end else begin
                counter   <= counter + 1;
                ena_pulse <= 1'b0;
            end
        end
    end
endmodule
