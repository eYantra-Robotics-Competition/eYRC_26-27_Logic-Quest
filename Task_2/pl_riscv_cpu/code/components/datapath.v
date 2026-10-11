// datapath.v - 5-stage pipelined datapath (Fetch | Decode | Execute | Memory | Writeback)

module datapath (
    input         clk, reset,
    input  [1:0]  ResultSrc,
    input         ALUSrc, RegWrite, MemWrite,
    input  [1:0]  ImmSrc,
    input  [2:0]  ALUControl,
    input         Branch, Jump, Jalr,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] InstrD,
    output reg        MemWriteM,
    output reg [2:0]  funct3M,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output reg [31:0] PCW, ALUResultW, WriteDataW
);

// Fetch
wire [31:0] PCNext, PCJalr, PCPlus4F;
// Decode
wire [31:0] PCD, PCPlus4D, RD1D, RD2D, ImmExtD;
// Execute
reg  [31:0] PCE, PCPlus4E, InstrE, RD1E, RD2E, ImmExtE;
reg         RegWriteE, MemWriteE, JumpE, BranchE, JalrE, ALUSrcE;
reg  [1:0]  ResultSrcE;
reg  [2:0]  ALUControlE;
wire [31:0] SrcAE, SrcBE, WriteDataE, ALUResultE;
wire [31:0] PCTargetE, AuiPCE, lAuiPCE;
wire        ZeroE, TakeBranchE;
wire [4:0]  Rs1E = InstrE[19:15];
wire [4:0]  Rs2E = InstrE[24:20];
wire [4:0]  RdE  = InstrE[11:7];
wire        PCSrcE = ((BranchE & TakeBranchE) | JumpE | JalrE);
// Memory
reg  [31:0] ALUResultM, WriteDataM, PCPlus4M, lAuiPCM, PCM;
reg  [4:0]  RdM;
reg         RegWriteM;
reg  [1:0]  ResultSrcM;
wire [31:0] FwdValM;
// Writeback
reg  [31:0] ReadDataW, PCPlus4W, lAuiPCW;
reg  [4:0]  RdW;
reg         RegWriteW;
reg  [1:0]  ResultSrcW;
// Hazard unit outputs
wire        StallF, StallD, FlushD, FlushE;
wire [1:0]  ForwardAE, ForwardBE;

// ================= FETCH =================
mux2 #(32)   pcmux   (PCPlus4F, PCTargetE, PCSrcE, PCNext);
mux2 #(32)   jalrmux (PCNext, ALUResultE, JalrE, PCJalr);

reset_ff #(32) pcreg (clk, reset, StallF, PCJalr, PC);
adder          pcadd4(PC, 32'd4, PCPlus4F);

// Pipeline Register 1 -> Fetch | Decode
pl_reg_fd plfd (clk, StallD, FlushD | reset, Instr, PC, PCPlus4F,
                InstrD, PCD, PCPlus4D);

// ================= DECODE =================
reg_file    rf  (clk, RegWriteW, InstrD[19:15], InstrD[24:20], RdW, Result, RD1D, RD2D);
imm_extend  ext (InstrD[31:7], ImmSrc, ImmExtD);

// Pipeline Register 2 -> Decode | Execute
initial begin
    PCE = 0; PCPlus4E = 0; InstrE = 0; RD1E = 0; RD2E = 0; ImmExtE = 0;
    RegWriteE = 0; MemWriteE = 0; JumpE = 0; BranchE = 0; JalrE = 0; ALUSrcE = 0;
    ResultSrcE = 0; ALUControlE = 0;
end

always @(posedge clk) begin
    if (FlushE | reset) begin
        PCE <= 0; PCPlus4E <= 0; InstrE <= 0; RD1E <= 0; RD2E <= 0; ImmExtE <= 0;
        RegWriteE <= 0; MemWriteE <= 0; JumpE <= 0; BranchE <= 0; JalrE <= 0;
        ALUSrcE <= 0; ResultSrcE <= 0; ALUControlE <= 0;
    end else begin
        PCE <= PCD; PCPlus4E <= PCPlus4D; InstrE <= InstrD;
        RD1E <= RD1D; RD2E <= RD2D; ImmExtE <= ImmExtD;
        RegWriteE <= RegWrite; MemWriteE <= MemWrite; JumpE <= Jump;
        BranchE <= Branch; JalrE <= Jalr; ALUSrcE <= ALUSrc;
        ResultSrcE <= ResultSrc; ALUControlE <= ALUControl;
    end
end

// ================= EXECUTE =================
// forwarding: 00 = reg file, 01 = Result (WB), 10 = Memory stage
mux3 #(32) fwdamux (RD1E, Result, FwdValM, ForwardAE, SrcAE);
mux3 #(32) fwdbmux (RD2E, Result, FwdValM, ForwardBE, WriteDataE);

mux2 #(32) srcbmux (WriteDataE, ImmExtE, ALUSrcE, SrcBE);
alu        alu_i   (SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);

adder      pcaddbranch (PCE, ImmExtE, PCTargetE);

adder #(32) auipcadder ({InstrE[31:12], 12'b0}, PCE, AuiPCE);
mux2  #(32) lauipcmux  (AuiPCE, {InstrE[31:12], 12'b0}, InstrE[5], lAuiPCE);

branching_unit bu (InstrE[14:12], ZeroE, ALUResultE[31], TakeBranchE);

// Pipeline Register 3 -> Execute | Memory
initial begin
    ALUResultM = 0; WriteDataM = 0; PCPlus4M = 0; lAuiPCM = 0; RdM = 0; PCM = 0;
    RegWriteM = 0; MemWriteM = 0; ResultSrcM = 0; funct3M = 0;
end

always @(posedge clk) begin
    if (reset) begin
        ALUResultM <= 0; WriteDataM <= 0; PCPlus4M <= 0; lAuiPCM <= 0; RdM <= 0; PCM <= 0;
        RegWriteM <= 0; MemWriteM <= 0; ResultSrcM <= 0; funct3M <= 0;
    end else begin
        ALUResultM <= ALUResultE; WriteDataM <= WriteDataE;
        PCPlus4M <= PCPlus4E; lAuiPCM <= lAuiPCE; RdM <= RdE; PCM <= PCE;
        RegWriteM <= RegWriteE; MemWriteM <= MemWriteE;
        ResultSrcM <= ResultSrcE; funct3M <= InstrE[14:12];
    end
end

// ================= MEMORY =================
assign Mem_WrData = WriteDataM;
assign Mem_WrAddr = ALUResultM;

// value forwarded from Memory stage (handles jal/jalr/lui/auipc results)
mux4 #(32) fwdmmux (ALUResultM, ALUResultM, PCPlus4M, lAuiPCM, ResultSrcM, FwdValM);

// Pipeline Register 4 -> Memory | Writeback
initial begin
    ReadDataW = 0; PCPlus4W = 0; lAuiPCW = 0; RdW = 0;
    RegWriteW = 0; ResultSrcW = 0;
    PCW = 0; ALUResultW = 0; WriteDataW = 0;
end

always @(posedge clk) begin
    if (reset) begin
        ReadDataW <= 0; PCPlus4W <= 0; lAuiPCW <= 0; RdW <= 0;
        RegWriteW <= 0; ResultSrcW <= 0;
        PCW <= 0; ALUResultW <= 0; WriteDataW <= 0;
    end else begin
        ReadDataW <= ReadData; PCPlus4W <= PCPlus4M; lAuiPCW <= lAuiPCM; RdW <= RdM;
        RegWriteW <= RegWriteM; ResultSrcW <= ResultSrcM;
        PCW <= PCM; ALUResultW <= ALUResultM; WriteDataW <= WriteDataM;
    end
end

// ================= WRITEBACK =================
mux4 #(32) resultmux (ALUResultW, ReadDataW, PCPlus4W, lAuiPCW, ResultSrcW, Result);

// ================= HAZARD UNIT =================
hazard_unit hu (InstrD[19:15], InstrD[24:20], Rs1E, Rs2E, RdE, RdM, RdW,
                RegWriteM, RegWriteW, ResultSrcE, PCSrcE,
                StallF, StallD, FlushD, FlushE, ForwardAE, ForwardBE);

endmodule


// hazard_unit - forwarding, load-use stall and branch/jump flush
module hazard_unit (
    input  [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    input        RegWriteM, RegWriteW,
    input  [1:0] ResultSrcE,
    input        PCSrcE,
    output       StallF, StallD, FlushD, FlushE,
    output [1:0] ForwardAE, ForwardBE
);

assign ForwardAE = (((Rs1E == RdM) & RegWriteM) & (Rs1E != 0)) ? 2'b10 :
                   (((Rs1E == RdW) & RegWriteW) & (Rs1E != 0)) ? 2'b01 : 2'b00;

assign ForwardBE = (((Rs2E == RdM) & RegWriteM) & (Rs2E != 0)) ? 2'b10 :
                   (((Rs2E == RdW) & RegWriteW) & (Rs2E != 0)) ? 2'b01 : 2'b00;

// load = ResultSrc 01
wire lwStall = (ResultSrcE == 2'b01) & ((Rs1D == RdE) | (Rs2D == RdE));

assign StallF = lwStall;
assign StallD = lwStall;
assign FlushD = PCSrcE;
assign FlushE = lwStall | PCSrcE;

endmodule
