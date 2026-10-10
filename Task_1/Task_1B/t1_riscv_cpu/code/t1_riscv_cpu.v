// t1_riscv_cpu.v - Top module to test riscv_cpu

module t1_riscv_cpu (
    input         clk, reset,
    input  [31:0] Ext_MemWrite,
    input  [31:0] Ext_MemWriteData, Ext_DataAdr,
    output        MemWrite,
    output [31:0] WriteData, DataAdr, ReadData,
    output [31:0] PC, Result
);

wire [31:0] Instr;
wire [31:0] DataAdr_rv32, WriteData_rv32;
wire        MemWrite_rv32;

// instantiate processor and memories
riscv_cpu rvCPU (
    clk, reset, PC, Instr,
    MemWrite_rv32, DataAdr_rv32,
    WriteData_rv32, ReadData, Result
);

instr_mem imem (PC, Instr);
data_mem dmem (clk, MemWrite, DataAdr, WriteData, ReadData);

assign MemWrite = (Ext_MemWrite && reset) ? 1 : MemWrite_rv32;
assign WriteData = (Ext_MemWrite && reset) ? Ext_MemWriteData : WriteData_rv32;
assign DataAdr = reset ? Ext_DataAdr : DataAdr_rv32;

endmodule
