// riscv_cpu.v - Single-cycle RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result
);

wire        ALUSrc, RegWrite, Jump, LUI, JALR, Zero;
wire [1:0]  ResultSrc;
wire [2:0]  ImmSrc;
wire [2:0]  ALUControl;
wire        PCSrc;

controller c (
    .op(Instr[6:0]),
    .funct3(Instr[14:12]),
    .funct7b5(Instr[30]),
    .Zero(Zero),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .Jump(Jump),
    .LUI(LUI),
    .JALR(JALR),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl)
);

datapath dp (
    .clk(clk),
    .reset(reset),
    .ResultSrc(ResultSrc),
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    .LUI(LUI),
    .JALR(JALR),
    .Zero(Zero),
    .PC(PC),
    .Instr(Instr),
    .Mem_WrAddr(Mem_WrAddr),
    .Mem_WrData(Mem_WrData),
    .ReadData(ReadData),
    .Result(Result)
);

endmodule
