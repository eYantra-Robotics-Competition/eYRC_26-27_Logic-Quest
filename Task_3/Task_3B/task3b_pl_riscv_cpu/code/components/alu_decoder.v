
// alu_decoder.v - logic for ALU decoder

module alu_decoder (
    input            opb5,
    input [2:0]      funct3,
    input            funct7b5,
    input [1:0]      ALUOp,
    output reg [2:0] ALUControl
);

always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 3'b000;             // addition
        2'b01: ALUControl = 3'b001;             // subtraction
        default:
            case (funct3) // R-type or I-type ALU
                3'b000: begin
                    // True for R-type subtract
                    if   (funct7b5 & opb5) ALUControl = 3'b001; //sub
                    else ALUControl = 3'b000; // add, addi
                end
                3'b010:  ALUControl = 3'b101; // slt, slti
                3'b110:  ALUControl = 3'b011; // or, ori
                3'b111:  ALUControl = 3'b010; // and, andi
                default: ALUControl = 3'bxxx; // ???
            endcase
    endcase
end

endmodule

