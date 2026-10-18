// instr_mem.v - instruction memory

module instr_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 512) (
    input  [ADDR_WIDTH-1:0] instr_addr,
    output [DATA_WIDTH-1:0] instr
);

    // array of 64 32-bit words of instructions
    reg [DATA_WIDTH-1:0] Instr_ram [0:(MEM_SIZE-1)];

    initial begin
        // $readmemh("rv32i_book.hex", Instr_ram);
        $readmemh("rv32i_test_1b.hex", Instr_ram);
        // $readmemh("rv32i_test_1c.hex", Instr_ram);
    end

    // word-aligned memory access
    // combinational read logic
    assign instr = Instr_ram[instr_addr[31:2]];

endmodule
