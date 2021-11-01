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

// enum for states
enum logic [1:0] { INIT, BUSY, FINISH } state_p, state_n;

logic [7:0] subtrahend_p, subtrahend_n;
logic [8:0] quotient_p, quotient_n;

// next state logic
always_comb begin
    
    //default assignment
    state_n = state_p;

    case (state_p)
    INIT: begin
            //start & divisor != 0
            if (start_i & divisor_i != 0) begin
                state_n = BUSY;
            //start & divisor == 0
            end else if (start_i & divisor_i == 0) begin                
                state_n = FINISH;
            end
        end
     BUSY: begin
            //subtrahend >= divisor
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

// Output logic
assign finish_o = (state_p == FINISH) ? 1'b1 : 1'b0;
assign busy_o = (state_p == BUSY) ? 1'b1 : 1'b0;
assign quotient_o = quotient_p;

always_comb begin
  // Default assignments
  quotient_n = quotient_p;
  subtrahend_n = subtrahend_p;
  
  case(state_p)
    INIT: begin
        //Standard INIT lt. ASM Diagramm
          quotient_n = 9'b0;
          subtrahend_n = dividend_i;
        //Start bei Divisor == 0
        if (divisor_i == 0 && start_i == 1) begin
          quotient_n = 'b1_1111_1111;
        end
    end

    BUSY: begin
        //+1 bei quotient und 1x divisor abziehen
        if (subtrahend_p >= divisor_i) begin
            quotient_n = quotient_p + 'b1;
            subtrahend_n = subtrahend_p - divisor_i;   
        end 
    end

    FINISH: begin
        //es passiert hier nichts neues
    end
  endcase
end

// registers
always_ff @(posedge clk_i or posedge reset_i) begin
  if(reset_i) begin
    state_p <= INIT;
    quotient_p <= 9'b0;
    subtrahend_p <= 8'b0;
  end else begin
    state_p <= state_n;
    quotient_p <= quotient_n;
    subtrahend_p <= subtrahend_n;
  end
end

endmodule


