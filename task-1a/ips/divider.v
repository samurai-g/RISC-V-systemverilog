module divider (
  input clk_i,
  input reset_i,
  input [3:0] dividend_i,
  input [3:0] divisor_i,
  input start_i,
  output busy_o,
  output finish_o,
  output [4:0] quotient_o
);
  assign finish_o = 1;
endmodule
