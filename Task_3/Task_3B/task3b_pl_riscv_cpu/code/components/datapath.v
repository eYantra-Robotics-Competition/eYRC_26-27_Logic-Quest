
// datapath.v
module datapath (
    input         clk, reset,
    input [1:0]   ResultSrc,
    input         ALUSrc, RegWrite,
    input [1:0]   ImmSrc,
    input [2:0]   ALUControl,
    input         Branch, Jump, Jalr,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output [31:0] PCW, ALUResultW, WriteDataW
);

wire [31:0] PCNext, PCJalr, PCPlus4, PCTarget, AuiPC, lAuiPC;
wire [31:0] ImmExt, SrcA, SrcB, WriteData, ALUResult;
wire Zero, TakeBranch;

wire PCSrc = ((Branch & TakeBranch) || Jump || Jalr) ? 1'b1 : 1'b0;

// next PC logic
mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCNext);
mux2 #(32)     jalrmux (PCNext, ALUResult, Jalr, PCJalr);

// stallF - should be wired from hazard unit
wire StallF = 0; // remove it after adding hazard unit.
reset_ff #(32) pcreg(clk, reset, StallF, PCJalr, PC);
adder          pcadd4(PC, 32'd4, PCPlus4);

// Pipeline Register 1 -> Fetch | Decode

wire FlushD = 0; // remove it after adding hazard unit
// FlushD - should be wired from hazard unit
// pl_reg_fd plfd (clk, StallD, FlushD, Instr, PC, PCPlus4,
            //   InstrD, PCD, PCPlus4D);

adder          pcaddbranch(PC, ImmExt, PCTarget);

// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend     ext (Instr[31:7], ImmSrc, ImmExt);

// Pipeline Register 2 -> Decode | Execute


// ALU logic
mux2 #(32)     srcbmux(WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA, SrcB, ALUControl, ALUResult, Zero);
adder #(32)    auipcadder ({Instr[31:12], 12'b0}, PC, AuiPC);
mux2 #(32)     lauipcmux (AuiPC, {Instr[31:12], 12'b0}, Instr[5], lAuiPC);

branching_unit bu (Instr[14:12], Zero, ALUResult[31], TakeBranch);

// Pipeline Register 3 -> Execute | Memory


// Pipeline Register 4 -> Memory | Writeback


// Result Source
mux4 #(32)     resultmux(ALUResult, ReadData, PCPlus4, lAuiPC, ResultSrc, Result);

// hazard unit

assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;

// eventually this statements will be removed while adding pipeline registers
assign PCW = PC;
assign ALUResultW = ALUResult;
assign WriteDataW = WriteData;

endmodule
