module divider(
    input logic         clk_i,
    input logic         reset_i,
    input logic [7:0]   dividend_i,
    input logic [7:0]   divisor_i,
    input logic         start_i,
    output logic        busy_o,
    output logic        finish_o,
    output logic [8:0] quotient_o
);
endmodule