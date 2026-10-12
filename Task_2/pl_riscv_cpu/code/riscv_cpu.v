// riscv_cpu.v - 5-stage pipelined RISC-V CPU Processor

module riscv_cpu (
    input         clk, reset,
    output [31:0] PC,
    input  [31:0] Instr,
    output        MemWrite,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData,
    output [31:0] Result,
    output [ 2:0] funct3,
    output [31:0] PCW, ALUResultW, WriteDataW
);

wire        ALUSrc, RegWrite, MemWriteD, Branch, Jump, Jalr;
wire [1:0]  ResultSrc, ImmSrc;
wire [2:0]  ALUControl;
wire [31:0] InstrD;

controller  c   (InstrD[6:0], InstrD[14:12], InstrD[30],
                ResultSrc, MemWriteD, ALUSrc,
                RegWrite, Branch, Jump, Jalr, ImmSrc, ALUControl);

datapath    dp  (clk, reset, ResultSrc,
                ALUSrc, RegWrite, MemWriteD, ImmSrc, ALUControl, Branch, Jump, Jalr,
                PC, Instr, InstrD, MemWrite, funct3,
                Mem_WrAddr, Mem_WrData, ReadData, Result,
                PCW, ALUResultW, WriteDataW);

endmodule
