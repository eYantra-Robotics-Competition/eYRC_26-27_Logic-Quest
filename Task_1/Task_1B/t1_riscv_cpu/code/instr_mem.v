// instr_mem.v - instruction memory

module instr_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 512) (
    input  [ADDR_WIDTH-1:0] addr,
    output [DATA_WIDTH-1:0] instr
);

// array of 64 32-bit words or instructions
reg [DATA_WIDTH-1:0] instr_mem [0:MEM_SIZE-1];

initial begin
    // Task 1B test program
    $readmemh("rv32i_test_1b.hex", instr_mem);
end

// word-aligned memory access
// combinational read logic
assign instr = instr_mem[addr[31:2]];

endmodule

