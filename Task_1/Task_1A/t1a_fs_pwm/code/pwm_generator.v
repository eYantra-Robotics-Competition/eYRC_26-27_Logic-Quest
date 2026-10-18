// Logic Quest Bot : Task 1A : PWM Generator
/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.
This file is used to design a module which will scale down the clk_5MHz Clock Frequency to 500Hz and perform Pulse Width Modulation on it.

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

//PWM Generator
//Inputs : clk_5MHz, pulse_width
//Output : clk_500Hz, pwm_signal

module pwm_generator(
    input clk_5MHz,
    input reset_n,
    input [4:0] pulse_width,
    output reg clk_500Hz, pwm_signal
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE //////////////////

reg [12:0] clk_count;
reg [4:0] pwm_count;

always @(posedge clk_5MHz or negedge reset_n) begin
    if (!reset_n) begin
        clk_count <= 13'd0;
        clk_500Hz <= 1'b0;
    end
    else if (clk_count == 13'd4999) begin
        clk_count <= 13'd0;
        clk_500Hz <= ~clk_500Hz;
    end
    else begin
        clk_count <= clk_count + 1'b1;
    end
end

always @(posedge clk_500Hz or negedge reset_n) begin
    if (!reset_n) begin
        pwm_count <= 5'd0;
        pwm_signal <= 1'b0;
    end
    else begin
        if (pwm_count == 5'd31)
            pwm_count <= 5'd0;
        else
            pwm_count <= pwm_count + 1'b1;

        if (pwm_count < pulse_width)
            pwm_signal <= 1'b1;
        else
            pwm_signal <= 1'b0;
    end
end
 
//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////

endmodule

