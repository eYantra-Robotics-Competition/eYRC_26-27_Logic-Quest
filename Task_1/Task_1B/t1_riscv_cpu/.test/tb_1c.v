`timescale 1 ns/1 ns

module tb_1c;

// registers to send data
reg clk;
reg reset;
reg Ext_MemWrite;
reg [31:0] Ext_WriteData, Ext_DataAdr;

// Wire Ouputs from Instantiated Modules
wire [31:0] WriteData, DataAdr, ReadData;
wire MemWrite;
wire [31:0] PC, Result;

// Initialize Top Module
t1_riscv_cpu uut (clk, reset, Ext_MemWrite, Ext_WriteData, Ext_DataAdr, MemWrite, WriteData, DataAdr, ReadData, PC, Result);

integer fault_instrs = 0, i = 0, fw = 0, flag = 0;

// Test the RISC-V processor:

localparam ADDI_x0  =   32'h8;
localparam ADDI     =   32'h10;
localparam SLLI     =   32'h14;
localparam SLTI     =   32'h18;
localparam SLTIU    =   32'h1C;
localparam XORI     =   32'h20;
localparam SRLI     =   32'h24;
localparam SRAI     =   32'h28;
localparam ORI      =   32'h2C;
localparam ANDI     =   32'h30;

localparam ADD      =   32'h34;
localparam SUB      =   32'h38;
localparam SLL      =   32'h3C;
localparam SLT      =   32'h40;
localparam SLTU     =   32'h44;
localparam XOR      =   32'h48;
localparam SRL      =   32'h4C;
localparam SRA      =   32'h50;
localparam OR       =   32'h54;
localparam AND      =   32'h58;

localparam LUI      =   32'h5C;
localparam AUIPC    =   32'h60;

localparam SB       =   32'h64;
localparam SH       =   32'h68;
localparam SW       =   32'h6C;

localparam LB       =   32'h70;
localparam LH       =   32'h74;
localparam LW       =   32'h78;
localparam LBU      =   32'h7C;
localparam LHU      =   32'h80;

localparam BLT_IN   =   32'h90;
localparam BLT_OUT  =   32'h9C;

localparam BGE_IN   =   32'hAC;
localparam BGE_OUT  =   32'hB8;

localparam BLTU_IN  =   32'hC8;
localparam BLTU_OUT =   32'hD4;

localparam BGEU_IN  =   32'hE4;
localparam BGEU_OUT =   32'hF0;

localparam BNE_IN   =   32'h100;
localparam BNE_OUT  =   32'h10C;

localparam BEQ_IN   =   32'h11C;
localparam BEQ_OUT  =   32'h128;

localparam JALR     =   32'h134;
localparam JAL      =   32'h138;

// generate clock to sequence tests
always begin
    clk <= 1; # 5; clk <= 0; # 5;
end

// check results of simple RISC-V CPU (from asm_programs/rv32i_test.s) r32i_test.hex
// performing standard instructions
initial begin
    reset = 1;
    Ext_MemWrite = 0; Ext_DataAdr = 32'b0; Ext_WriteData = 32'b0; #10;
    reset = 0;
end

// test the book asm program
// always @(negedge clk) begin
//     # 10;
//     if(MemWrite && !reset) begin
//         if(DataAdr === 100 & WriteData === 25) begin
//             $display("Simulation succeeded");
//             $stop;
//         end
//         else if (DataAdr !== 96) begin
//             $display("Simulation failed");
//             $stop;
//         end
//     end
// end

always @(negedge clk) begin
    case(PC)
        ADDI_x0 : begin
            i = i + 1'b1;
            if(Result === -3)  $display("1. addi implementation is correct for x0 ");
            else begin
                $display("1. addi implementation for x0 is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        ADDI    : begin
            i = i + 1'b1;
            if(Result === 9) $display("2. addi implementation is correct ");
            else begin
                $display("2. addi implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SLLI    : begin
            i = i + 1'b1;
            if(Result === 64) $display("3. slli implementation is correct ");
            else begin
                $display("3. slli implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SLTI    : begin
            i = i + 1'b1;
            if(Result === 0) $display("4. slti implementation is correct ");
            else begin
                $display("4. slti implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SLTIU    : begin
            i = i + 1'b1;
            if(Result === 1) $display("5. sltiu implementation is correct ");
            else begin
                $display("5. sltiu implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        XORI    : begin
            i = i + 1'b1;
            if(Result === 2) $display("6. xori implementation is correct ");
            else begin
                $display("6. xori implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SRLI    : begin
            i = i + 1'b1;
            if(Result === 536870911) $display("7. srli implementation is correct ");
            else begin
                $display("7. srli implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SRAI    : begin
            i = i + 1'b1;
            if(Result === -1) $display("8. srai implementation is correct ");
            else begin
                $display("8. srai implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        ORI    : begin
            i = i + 1'b1;
            if(Result === -1) $display("9. ori implementation is correct ");
            else begin
                $display("9. ori implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        ANDI    : begin
            i = i + 1'b1;
            if(Result === 1) $display("10. andi implementation is correct");
            else begin
                $display("10. andi implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        ADD    : begin
            i = i + 1'b1;
            if(Result === 17) $display("11. add implementation is correct ");
            else begin
                $display("11. add implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SUB    : begin
            i = i + 1'b1;
            if(Result === 15) $display("12. sub implementation is correct ");
            else begin
                $display("12. sub implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end


        SLL    : begin
            i = i + 1'b1;
            if(Result === 32) $display("13. sll implementation is correct ");
            else begin
                $display("13. sll implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SLT    : begin
            i = i + 1'b1;
            if(Result === 0) $display("14. slt implementation is correct ");
            else begin
                $display("14. slt implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SLTU    : begin
            i = i + 1'b1;
            if(Result === 1) $display("15. sltu implementation is correct ");
            else begin
                $display("15. sltu implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        XOR    : begin
            i = i + 1'b1;
            if(Result === 17) $display("16. xor implementation is correct ");
            else begin
                $display("16. xor implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SRL    : begin
            i = i + 1'b1;
            if(Result === 8) $display("17. srl implementation is correct ");
            else begin
                $display("17. srl implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        SRA    : begin
            i = i + 1'b1;
            if(Result === 8) $display("18. sra implementation is correct ");
            else begin
                $display("18. sra implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        OR    : begin
            i = i + 1'b1;
            if(Result === 17) $display("19. or implementation is correct ");
            else begin
                $display("19. or implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        AND    : begin
            i = i + 1'b1;
            if(Result === 0) $display("20. and implementation is correct ");
            else begin
                $display("20. and implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        LUI    : begin
            i = i + 1'b1;
            if(Result === 32'h02000000) $display("21. lui implementation is correct ");
            else begin
                $display("21. lui implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        AUIPC    : begin
            i = i + 1'b1;
            if(Result === 32'h02000060) $display("22. auipc implementation is correct ");
            else begin
                $display("22. auipc implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end


        SB      : begin
            i = i + 1'b1;
            if(MemWrite && !reset) begin
                if(DataAdr === 32 & WriteData === 1) $display ("23. sb implementation is correct");
                else begin
                    $display("23. sb implementation is incorrect");
                    fault_instrs = fault_instrs + 1'b1;
                end
            end
        end


        SH      : begin
            i = i + 1'b1;
            if(MemWrite && !reset) begin
                if(DataAdr === 36 & WriteData === -3) $display ("24. sh implementation is correct");
                else begin
                    $display("24. sh implementation is incorrect");
                    fault_instrs = fault_instrs + 1'b1;
                end
            end
        end


        SW      : begin
            i = i + 1'b1;
            if(MemWrite && !reset) begin
                if(DataAdr === 40 & WriteData === 16) $display ("25. sw implementation is correct");
                else begin
                    $display("25. sw implementation is incorrect");
                    fault_instrs = fault_instrs + 1'b1;
                end
            end
        end

        LB      : begin
            i = i + 1'b1;
            if(DataAdr === 32 & Result === 1 ) $display ("26. lb implementation is correct");
            else begin
                $display("26. lb implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        LH      : begin
            i = i + 1'b1;
            if(DataAdr === 36 & Result === -3 ) $display ("27. lh implementation is correct");
            else begin
                $display("27. lh implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        LW      : begin
            i = i + 1'b1;
            if(DataAdr === 40 & Result === 16) $display ("28. lw implementation is correct");
            else begin
                $display("28. lw implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        LBU      : begin
            i = i + 1'b1;
            if(DataAdr === 32 & Result === 1) $display ("29. lbu implementation is correct");
            else begin
                $display("29. lbu implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        LHU     : begin
            i = i + 1'b1;
            if(DataAdr === 36 & Result === 32'h0000FFFD) $display ("30. lhu implementation is correct");
            else begin
                $display("30. lhu implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        BLT_IN : begin
            if(Result <= 32'hA) $display("31. blt is executing");
            else begin
                $display("blt struck in loop");
                flag = 1;
                $stop;
            end
        end

        BLT_OUT : begin
            i = i + 1'b1;
            if(Result === 5) $display("31. blt implementation is correct ");
            else begin
                $display("31. blt implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        BGE_IN : begin
            if(Result <= 32'hB) $display("32. bge is executing");
            else begin
                $display("bge struck in loop");
                flag = 1;
                $stop;
            end
        end

        BGE_OUT : begin
            i = i + 1'b1;
            if(Result === -6) $display("32. bge implementation is correct");
            else begin
                $display("32. bge implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        BLTU_IN : begin
            if(Result <= 4) $display("33. bltu is executing");
            else begin
                $display("bltu struck in loop");
                flag = 1;
                $stop;
            end
        end

        BLTU_OUT : begin
            i = i + 1'b1;
            if(Result === 5) $display("33. bltu implementation is correct ");
            else begin
                $display("33. bltu implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        BGEU_IN : begin
            if(Result <= 5) $display("34. bgeu is executing");
            else begin
                $display("bgeu struck in loop");
                flag = 1;
                $stop;
            end
        end

        BGEU_OUT : begin
            i = i + 1'b1;
            if(Result === 0) $display("34. bgeu implementation is correct ");
            else begin
                $display("34. bgeu implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        BNE_IN : begin
            if(Result <= 5) $display("35. bne is executing");
            else begin
                $display("bne struck in loop");
                flag = 1;
                $stop;
            end
        end

        BNE_OUT : begin
            i = i + 1'b1;
            if(Result === 5) $display("35. bne implementation is correct ");
            else begin
                $display("35. bne implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        BEQ_IN : begin
            if(Result <=2) $display("36. beq is executing");
            else begin
                $display("beq struck in loop");
                flag = 1;
                $stop;
            end
        end

        BEQ_OUT : begin
            i = i + 1'b1;
            if(Result === 4) $display("36. beq implementation is correct ");
            else begin
                $display("36. beq implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        JALR     : begin
            i = i + 1'b1;
            if (Result === 32'h130) $display("37. jalr implementation is correct ");
            else begin
                $display("37. jalr implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

        JAL     : begin
            i = i + 1'b1;
            if (Result === 32'h13C ) $display("38. jal implementation is correct ");
            else begin
                $display("38. jal implementation is incorrect");
                fault_instrs = fault_instrs + 1'b1;
            end
        end

    endcase
end

always @(negedge clk) begin
    if (i >= 38 || flag == 1) begin
        $display("Faulty Instructions => %d", fault_instrs);
        if (fault_instrs !== 0) begin
            fw = $fopen("results.txt","w");
            $fdisplay(fw, "%02h","Errors");
            $display("Error(s) encountered, please check your design!");
            $fclose(fw);
        end
        else begin
            fw = $fopen("results.txt","w");
            $fdisplay(fw, "%02h","No Errors");
            $display("No errors encountered, congratulations!");
            $fclose(fw);
        end
    $stop;
    end
end

endmodule
