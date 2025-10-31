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
