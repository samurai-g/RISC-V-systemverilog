module divider(
    input logic         clk_i,
    input logic         reset_i,
    input logic [7:0]   dividend_i,
    input logic [7:0]   divisor_i,
    input logic         start_i,
    output logic        busy_o,
    output logic        finish_o,
    output logic [8:0]  quotient_o
);

// next state logic
enum logic [1:0] { INIT, BUSY, FINISH } state_p, state_n;
logic [7:0] quotient_p, quotient_n, subtrahend_p, subtrahend_n;

always@(*) begin
    //default
    state_n = state_p;

    case (state_p)
    INIT: begin
            if (start_i & divisor_i != 0) begin
                state_n = BUSY;
            end else if (start_i & divisor_i == 0) begin                
                state_n = FINISH;
            end
        end
     BUSY: begin
            if (subtrahend_n >= divisor_i) begin
                state_n = BUSY;
            end else begin
                state_n = FINISH; 
            end
        end
    FINISH: begin
            state_n = INIT;
        end
    endcase
end

// output logic
always@(*) begin
    //default
    busy_o = 'b0;
    finish_o = 'b0;
    quotient_n <= quotient_p;
    subtrahend_n <= subtrahend_p;
    
    case (state_p)
        INIT: begin
            subtrahend_n <= dividend_i;
        end
        BUSY: begin
            busy_o = 'b1;
            subtrahend_n <= subtrahend_n - divisor_i;    
            quotient_n <= quotient_n + 1;
        end
        FINISH: begin
            finish_o = 'b1;
        end
        default: state_n <= state_p; //default case
    endcase
end


// registers
always_ff @(posedge clk_i or posedge reset_i) begin
  // reset
  if(reset_i) begin
    state_p <= INIT;
    quotient_p <= 9'b0;
    subtrahend_p <= 8'b0;
  end 
  // quotient == 0
  if(state_p == INIT & start_i == 1 & divisor_i ==0) begin
    quotient_p <= 'b1_1111_1111;
  end
  else begin
    state_p  <= state_n;
    quotient_p <= quotient_n;
    subtrahend_p <= subtrahend_n;
  end
end

endmodule


