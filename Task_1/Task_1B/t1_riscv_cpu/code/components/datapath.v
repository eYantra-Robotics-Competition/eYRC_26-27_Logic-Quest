// datapath.v

module datapath (
    input clk, reset,
    input [1:0] ResultSrc,
    input PCSrc, ALUSrc,
    input RegWrite,
    input [2:0] ImmSrc,
    input [2:0] ALUControl,
    output Zero,
    output [31:0] PC,
    input [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input [31:0] ReadData,
    output [31:0] Result
);

wire [31:0] PCNext, PCPlus4, PCTarget;
wire [31:0] ImmExt;
wire [31:0] SrcA, SrcB;
wire [31:0] RegSrcA, WriteData;
wire [31:0] ALUResult;

wire is_LUI;
wire is_AUIPC;
wire is_JALR;

// Instruction detection
assign is_LUI   = (Instr[6:0] == 7'b0110111);
assign is_AUIPC = (Instr[6:0] == 7'b0010111);
assign is_JALR  = (Instr[6:0] == 7'b1100111);


// --------------------------------------------------
// Register file logic
// --------------------------------------------------

reg_file rf (
    clk,
    RegWrite,
    Instr[19:15],
    Instr[24:20],
    Instr[11:7],
    Result,
    RegSrcA,
    WriteData
);


// --------------------------------------------------
// Immediate extension
// --------------------------------------------------

imm_extend ext (
    Instr[31:7],
    ImmSrc,
    ImmExt
);


// --------------------------------------------------
// ALU Source A
//
// LUI   -> 0 + Immediate
// AUIPC -> PC + Immediate
// Other -> rs1
// --------------------------------------------------

assign SrcA = is_LUI ? 32'b0 :
              is_AUIPC ? PC :
              RegSrcA;


// --------------------------------------------------
// ALU Source B
// --------------------------------------------------

mux2 #(32) srcbmux (
    WriteData,
    ImmExt,
    ALUSrc,
    SrcB
);


// --------------------------------------------------
// ALU
// --------------------------------------------------

alu alu (
    SrcA,
    SrcB,
    ALUControl,
    ALUResult,
    Zero
);


// --------------------------------------------------
// PC + 4
// --------------------------------------------------

adder pcadd4 (
    PC,
    32'd4,
    PCPlus4
);


// --------------------------------------------------
// Normal branch/jump target
// PC + Immediate
// --------------------------------------------------

adder pcaddbranch (
    PC,
    ImmExt,
    PCTarget
);


// --------------------------------------------------
// JALR target
// rs1 + Immediate
// --------------------------------------------------

wire [31:0] JALRTarget;

adder jalradd (
    RegSrcA,
    ImmExt,
    JALRTarget
);


// --------------------------------------------------
// Select final PC target
// --------------------------------------------------

wire [31:0] FinalTarget;

assign FinalTarget = is_JALR ? JALRTarget : PCTarget;


// --------------------------------------------------
// PC mux
// --------------------------------------------------

mux2 #(32) pcmux (
    PCPlus4,
    FinalTarget,
    PCSrc,
    PCNext
);


// --------------------------------------------------
// Program Counter
// --------------------------------------------------

reset_ff #(32) pcreg (
    clk,
    reset,
    PCNext,
    PC
);


// --------------------------------------------------
// Result mux
//
// 00 -> ALUResult
// 01 -> ReadData
// 10 -> PCPlus4
// --------------------------------------------------

mux3 #(32) resultmux (
    ALUResult,
    ReadData,
    PCPlus4,
    ResultSrc,
    Result
);


// --------------------------------------------------
// Memory connections
// --------------------------------------------------

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

endmodule

