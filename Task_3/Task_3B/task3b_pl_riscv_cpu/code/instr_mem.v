
// instr_mem.v - instruction memory

module instr_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 1024) (
    input       [ADDR_WIDTH-1:0] instr_addr,
    output      [DATA_WIDTH-1:0] instr
);

// array of 1024 32-bit words or instructions (4 KB)
reg [DATA_WIDTH-1:0] instr_ram [0:MEM_SIZE-1];

initial begin
    $readmemh("program.hex", instr_ram);
    // $readmemh("rv32i_test.hex", instr_ram);
end

// word-aligned memory access
// combinational read logic
assign instr = instr_ram[instr_addr[31:2]];

endmodule

