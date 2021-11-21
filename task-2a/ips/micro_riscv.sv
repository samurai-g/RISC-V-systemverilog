`include "defines.vh"
import cpu_pkg::*;

//AKTUELLE VERSION 21.11 18:51

module micro_riscv(
  input logic         clk_i,
  input logic         reset_i,

  output logic [31:0] cpu_data_addr_o,
  input  logic [31:0] cpu_data_rdata_i,
  output logic [31:0] cpu_data_wdata_o,
  output logic        cpu_data_re_o,
  output logic        cpu_data_we_o,

  output logic [31:0] cpu_instr_addr_o,
  input  logic [31:0] cpu_instr_rdata_i,

  output logic        cpu_finish_o
);
  // Stop the testbench if we finish the CPU via EBREAK
  // For a pipelined CPU it sometimes occurs to read and decode invalid instructions.
  // This, however, is corrected when dealing when hazards
  logic illegal_insn, illegal_insn_n, illegal_insn_p;
  logic cpu_halt_n, cpu_halt_p;

  assign cpu_finish_o = cpu_halt_p;

  //##################################################################################################
  // Instruction Fetch
  //
  logic [31:0] PC_p, PC_n; // Program Counter
  logic [31:0] PC_incr;
  logic PC_src;

  // Next program counter
  assign PC_incr = PC_p + 4;

  always_comb begin
    PC_n = PC_p;
    casez({cpu_halt_p, PC_src})
      2'b1?: PC_n = PC_p;
      2'b01: PC_n = PC_alu;
      2'b00: PC_n = PC_incr;
    endcase
  end

  // Redirect PC to the instruction memory interface
  assign cpu_instr_addr_o = PC_p;

  // Model PC register
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      PC_p <= RESET_ADDR;
    end else begin
      PC_p <= PC_n;
    end
  end

  // IF/ID STAGE PIPELINE

  logic [31:0] PC_if_p, PC_if_n; // IF Program Counter
  logic [31:0] Instruction_if_p, Instruction_if_n; // IF Instruction Register
  logic nop_if_n, nop_if_p; //pipelined ‘no-operation’ signal
  
  // Wire PC to IF PC
  assign PC_if_n = PC_p;

  // PC register - just take PC from register
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      PC_if_p <= 32'b0;
    end else begin
      PC_if_p <= PC_if_n;
    end
  end

  // Control Flow Hazard (NOP in if/id stage)
  always_comb begin
    Instruction_if_n = cpu_instr_rdata_i;
    if (PC_src == 1'b1) begin
      Instruction_if_n = 32'b00000000000000000000000000010011;
    end
  end

  // Nop register - save IF_nop flag if nop instruction
  //always_ff @(posedge clk_i or posedge reset_i) begin
  //  if (reset_i) begin
  //    nop_if_p <= 32'b0;
  //  end else begin
  //    nop_if_p <= nop_if_n;
  //  end
  //end

  // Instruction register - save current instruction
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      Instruction_if_p <= 32'b0;
    end else begin
      Instruction_if_p <= Instruction_if_n;
    end
  end

  //-------------------------------------------
  // ID/EX STAGE
  
  logic [31:0] PC_id_p, PC_id_n; // ID Program Counter
  logic [31:0] PC_id_incr;
  logic nop_id_n, nop_id_p;

  //connect pc and nop registers
  assign  PC_id_n = PC_if_p;
  assign  nop_id_n = nop_if_p;
  
  // ID_PC + 4
  assign PC_id_incr = PC_id_p + 4;

  //PC register - just take PC from IF/ID register
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      PC_id_p <= 32'b0;
    end else begin
      PC_id_p <= PC_id_n;
    end
  end

  //nop register - just take PC from IF/ID register
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      nop_id_p <= 32'b0;
    end else begin
      nop_id_p <= nop_id_n;
    end
  end

  // ID/EX (Decode/Execution) register
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      alu_operator_p   <= 1'b0;
      imm_sel_p        <= 1'b0;
      alu_src_p        <= 1'b0;
      alu_is_branch_p  <= 1'b0;
      alu_is_jump_p    <= 1'b0;
      alu_mem_read_p   <= 1'b0;
      alu_mem_write_p  <= 1'b0;
      alu_reg_write_p  <= 1'b0;
      mem_to_reg_p     <= 1'b0;
      alu_pc_reg_src_p <= 1'b0;
      illegal_insn_p   <= 1'b0;
      cpu_halt_p       <= 1'b0;
    end else begin
       alu_operator_p   <=  alu_operator_n;
       imm_sel_p        <=  imm_sel_n;      
       alu_src_p        <=  alu_src_n;       
       alu_is_branch_p  <=  alu_is_branch_n;
       alu_is_jump_p    <=  alu_is_jump_n;   
       alu_mem_read_p   <=  alu_mem_read_n;  
       alu_mem_write_p  <=  alu_mem_write_n; 
       alu_reg_write_p  <=  alu_reg_write_n;
       mem_to_reg_p     <=  mem_to_reg_n;    
       alu_pc_reg_src_p <=  alu_pc_reg_src_n;
       illegal_insn_p   <=  illegal_insn_n;
       cpu_halt_p       <=  cpu_halt_n;        
       rd_p             <=  rd_n;
       alu_imm_p        <=  alu_imm_n;     
    end
  end

  //reg_data_register
  always_ff @(posedge clk_i or posedge reset_i) begin
    if (reset_i) begin
      reg_data_1_p     <= 32'b0;
      reg_data_2_p     <= 32'b0;
    end else begin
      reg_data_1_p     <= reg_data_1_n;
      reg_data_2_p     <= reg_data_2_n;     
    end 
  end

  //assign reg_data_1_n = reg_data_1;
  //assign reg_data_2_n = reg_data_2;

  logic forward_log;
  logic test1, test2, test3;

  //FORWARD LOGIC
  always_comb begin
    test1 = 1'b0;
    if (rd_p == rs1)
      test1 = 1'b1;
  end

  always_comb begin
    test2 = 1'b0;
    if (reg_write_data != 32'b0)
      test2 = 1'b1;
  end

  always_comb begin
   test3 = 1'b0;
   if (rd_p != 32'b0)
     test3 = 1'b1;
 end

  //For reg_data_1
  //always_comb begin
  //  case({forward_log})
  //    1'b1: reg_data_1_n = reg_data_1;
  //    1'b0: reg_data_1_n = reg_write_data;
  //  endcase
  //end



  //##################################################################################################
  // Instruction Decode
  //
  // RISC-V Instruction Formats:
  //
  //           31          25 24      20 19      15 14  12 11       7 6            0
  //  R-Type: |    funct7    |   rs2    |   rs1    |funct3|   rd     |    opcode    |
  //  I-Type: |          imm[11:0]      |   rs1    |funct3|   rd     |    opcode    |
  //  S-Type: |  imm[11:5]   |   rs2    |   rs1    |funct3| imm[4:0] |    opcode    |
  //  U-Type: |                    imm                    |   rd     |    opcode    |
  //
  // RISC-V Immediate Formats:
  //
  //           31 30                 20 19            12 11 10         5 4      1  0
  // I-Imm:   |                 <-- sext 31                |    30:25   |  24:21 |20|
  // S-Imm:   |                 <-- sext 31                |    30:25   |  11:8  | 7|
  // B-Imm:   |               <-- sext 31               | 7|    30:25   |  11:8  | z|
  // U-Imm:   |31|        30:20        |      19:12     |          <-- zext         |
  // J-Imm:   |       <-- sext 31      |      19:12     |20|    30:25   |  24:21 | z|
  //
  //##################################################################################################

  logic [6:0]  opcode;
  logic [2:0]  funct3;
  logic [6:0]  funct7;
  logic [11:0] funct12;
  logic [4:0]  rd_n, rd_p;
  logic [4:0]  rs1;
  logic [4:0]  rs2;
  logic rs1_valid; 
  logic rs2_valid;

  // Just for renaming
  logic [31:0] Instruction;
  assign Instruction = Instruction_if_p;

  assign opcode  = Instruction[6:0];
  assign funct3  = Instruction[14:12];
  assign funct7  = Instruction[31:25];
  assign funct12 = Instruction[31:20];
  assign rd_n    = Instruction[11:7];
  assign rs1     = rs1_valid ? Instruction[19:15] : 5'b0;
  assign rs2     = rs2_valid ? Instruction[24:20] : 5'b0;

  logic [31:0] reg_data_1, reg_data_1_n,     reg_data_1_p;
  logic [31:0] reg_data_2, reg_data_2_n,     reg_data_2_p;
  logic [31:0] reg_write_data;

  logic alu_reg_write_n, alu_reg_write_p;

  // Register File
  register_file reg_file_i (
    .clk_i         (clk_i),
    .reset_i       (reset_i),
    .read_reg_1_i  (rs1),
    .read_data_1_o (reg_data_1),
    .read_reg_2_i  (rs2),
    .read_data_2_o (reg_data_2),
    .write_i       (alu_reg_write_p),
    .write_reg_i   (rd_p),
    .write_data_i  (reg_write_data)
  );

  //Initate _n and _p for decode register
  logic alu_src_n,        alu_src_p;
  logic alu_is_branch_n,  alu_is_branch_p;
  logic alu_is_jump_n,    alu_is_jump_p;
  logic alu_mem_write_n,  alu_mem_write_p;
  logic alu_mem_read_n,   alu_mem_read_p;
  logic mem_to_reg_n,     mem_to_reg_p;
  logic alu_pc_reg_src_n, alu_pc_reg_src_p; 

  //Assign to *decode*_n to avoid rewriting decode
  //assign alu_pc_reg_src_n = alu_pc_reg_src ;
  

  imm_t imm_sel, imm_sel_n, imm_sel_p;
  alu_op_t alu_operator_n, alu_operator_p;

  // Decoder and ALU control
  always_comb begin
    alu_operator_n   = ALU_ADD;
    imm_sel        = IMM_I;
    alu_src_n        = 1'b0;
    alu_is_branch_n  = 1'b0;
    alu_is_jump_n    = 1'b0;
    alu_mem_read_n   = 1'b0;
    alu_mem_write_n  = 1'b0;
    alu_reg_write_n  = 1'b0;
    mem_to_reg_n     = 1'b0;
    alu_pc_reg_src_n = 1'b0;
    illegal_insn   = 1'b0;
    cpu_halt_n       = 1'b0;
    rs1_valid      = 1'b0;
    rs2_valid      = 1'b0;

    case(opcode)
      OPC_JAL: begin
        alu_operator_n  = ALU_ADD;
        imm_sel       = IMM_UJ;
        alu_is_jump_n   = 1'b1;
        alu_reg_write_n = 1'b1;
      end
      OPC_JALR: begin
        alu_operator_n   = ALU_ADD;
        imm_sel        = IMM_I;
        rs1_valid      = 1'b1;
        alu_is_jump_n    = 1'b1;
        alu_reg_write_n  = 1'b1;
        alu_pc_reg_src_n = 1'b1;
      end
      OPC_BRANCH: begin
        imm_sel       = IMM_SB;
        alu_is_branch_n = 1'b1;
        rs1_valid     = 1'b1;
        rs2_valid     = 1'b1;
        case (funct3)
          F3_BEQ:  alu_operator_n = ALU_EQ;
          F3_BNE:  alu_operator_n = ALU_NE;
          F3_BLT:  alu_operator_n = ALU_LTS;
          F3_BGE:  alu_operator_n = ALU_GES;
          default: illegal_insn = 1'b1;
        endcase
      end
      OPC_LOAD: begin
        alu_operator_n  = ALU_ADD;
        imm_sel       = IMM_I;
        rs1_valid     = 1'b1;
        alu_reg_write_n = 1'b1;
        alu_src_n       = 1'b1;
        alu_mem_read_n  = 1'b1;
        mem_to_reg_n    = 1'b1;
      end
      OPC_STORE: begin
        alu_operator_n  = ALU_ADD;
        imm_sel       = IMM_S;
        rs1_valid     = 1'b1;
        rs2_valid     = 1'b1;
        alu_src_n       = 1'b1;
        alu_mem_write_n = 1'b1;
      end
      OPC_LUI: begin
        alu_operator_n  = ALU_ADD;
        imm_sel       = IMM_U;
        alu_src_n       = 1'b1;
        alu_reg_write_n = 1'b1;
      end
      OPC_IMM: begin
        imm_sel       = IMM_I;
        rs1_valid     = 1'b1;
        alu_src_n       = 1'b1;
        alu_reg_write_n = 1'b1;

        case (funct3)
          default: illegal_insn = 1'b1;
          F3_ADD:  alu_operator_n = ALU_ADD;  // Add Immediate
        endcase
      end
      OPC_ALSU: begin
        alu_reg_write_n = 1'b1;
        rs1_valid     = 1'b1;
        rs2_valid     = 1'b1;

        case ({funct7, funct3})
          // RV32I ALU operations
          {7'b000_0000, F3_ADD}: alu_operator_n = ALU_ADD;   // Add
          {7'b010_0000, F3_ADD}: alu_operator_n = ALU_SUB;   // Sub
          {7'b000_0000, F3_XOR}: alu_operator_n = ALU_XOR;   // Xor
          {7'b000_0000, F3_OR }: alu_operator_n = ALU_OR;    // Or
          {7'b000_0000, F3_AND}: alu_operator_n = ALU_AND;   // And
          {7'b000_0000, F3_SLL}: alu_operator_n = ALU_SLL;   // Shift Left Logical
          {7'b000_0000, F3_SRL}: alu_operator_n = ALU_SRL;   // Shift Right Logical
          {7'b010_0000, F3_SRL}: alu_operator_n = ALU_SRA;   // Shift Right
          default:               illegal_insn = 1'b1;
        endcase
      end
      OPC_SYSTEM: begin
        if({funct12, rs1, funct3, rd_p} == 25'b0000000000010000000000000) begin
          cpu_halt_n = 1'b1;
        end else begin
          illegal_insn = 1'b1;
        end
      end
      default: begin
        illegal_insn = 1'b1;
      end
    endcase
    // Gate out control signal in case of decoding an invalid instruction
    if (illegal_insn) begin
      alu_operator_n   = ALU_ADD;
      imm_sel        = IMM_I;
      alu_src_n        = 1'b0;
      alu_is_branch_n  = 1'b0;
      alu_is_jump_n  = 1'b0;
      alu_mem_write_n  = 1'b0;
      alu_mem_read_n   = 1'b0;
      alu_reg_write_n  = 1'b0;
      mem_to_reg_n     = 1'b0;
      alu_pc_reg_src_n = 1'b0;
      cpu_halt_n        = 1'b0;
      rs1_valid      = 1'b0;
      rs2_valid      = 1'b0;
    end
  end
  //END OF DECODE

  // Immediate generation
  logic signed [31:0] i_imm;
  logic signed [31:0] s_imm;
  logic signed [31:0] sb_imm;
  logic signed [31:0] u_imm;
  logic signed [31:0] uj_imm;
  logic signed [31:0] alu_imm_n, alu_imm_p;

  assign i_imm = {{20{Instruction[31]}}, Instruction[31:20]};
  assign s_imm = {{20{Instruction[31]}}, Instruction[31:25], Instruction[11:7]};
  assign sb_imm = {{19{Instruction[31]}}, Instruction[31], Instruction[7], Instruction[30:25], Instruction[11:8], 1'b0};
  assign u_imm = {Instruction[31:12], 12'b0};
  assign uj_imm = {{12{Instruction[31]}}, Instruction[19:12], Instruction[20], Instruction[30:21], 1'b0};

  // Immediate mux
  always_comb begin
    alu_imm_n = i_imm; // JALR, Load, ALUi,
    case(imm_sel)
      IMM_U:  alu_imm_n = u_imm; // LUI, AUIPC
      IMM_UJ: alu_imm_n = uj_imm; // JAL
      IMM_SB: alu_imm_n = sb_imm; // Conditional branches
      IMM_S:  alu_imm_n = s_imm;  // Store
    endcase
  end

  // ALU
  logic signed [31:0] alu_data_2;
  logic signed [31:0] alu_result;
  logic alu_branch_o;

  // Select sign-extended immediate from insruction or register value 2 as ALU input
  assign alu_data_2 = alu_src_p? alu_imm_p : reg_data_2_p;

  alu alu_i (
    .alu_rs1_i    (reg_data_1_p),
    .alu_rs2_i    (alu_data_2),
    .alu_op_i     (alu_operator_p),
    .alu_branch_o (alu_branch_o),
    .alu_result_o (alu_result)
  );


  // Compute PC from instruction. Source is either the current PC (direct jump)
  // or a register (indirect jump)
  logic [31:0] PC_alu;
  assign PC_alu = (alu_pc_reg_src_p? reg_data_1_p : PC_id_p) + alu_imm_p;

  // Determine PC source based on instruction and branch result
  assign PC_src = (alu_branch_o & alu_is_branch_p) |  // Conditional branch taken
                   alu_is_jump_p;                     // Unconditional jump

  // Data memory interface
  assign cpu_data_addr_o  = alu_result;
  assign cpu_data_wdata_o = reg_data_2_p;
  assign cpu_data_re_o    = alu_mem_read_p;
  assign cpu_data_we_o    = alu_mem_write_p;

  // Write-back data to the register file
  always_comb begin
    reg_write_data = alu_result;
    priority casez ({mem_to_reg_p, alu_is_jump_p})
      2'b?1: reg_write_data = PC_id_incr;
      2'b0?: reg_write_data = alu_result;
      2'b1?: reg_write_data = cpu_data_rdata_i;
    endcase
  end
endmodule
