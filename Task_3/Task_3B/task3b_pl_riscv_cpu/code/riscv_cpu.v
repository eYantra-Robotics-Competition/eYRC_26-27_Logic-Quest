
// riscv_cpu.v - single-cycle RISC-V CPU Processor

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

wire        ALUSrc, RegWrite, Branch, Jump, Jalr;
wire [1:0]  ResultSrc, ImmSrc;
wire [2:0]  ALUControl;

controller  c   (Instr[6:0], Instr[14:12], Instr[30],
                ResultSrc, MemWrite, ALUSrc,
                RegWrite, Branch, Jump, Jalr, ImmSrc, ALUControl);

datapath    dp  (clk, reset, ResultSrc,
                ALUSrc, RegWrite, ImmSrc, ALUControl, Branch, Jump, Jalr,
                PC, Instr, Mem_WrAddr, Mem_WrData, ReadData, Result, PCW, ALUResultW, WriteDataW);

// Eventually will be removed while adding pipeline registers
assign funct3 = Instr[14:12];

endmodule
