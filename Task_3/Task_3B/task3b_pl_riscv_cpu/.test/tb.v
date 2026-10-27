`timescale 1 ns/1 ns

// tb.v - Task 3B: Path Planner with Decryption (Path_Planner_Dec.c) on the pipelined RISC-V CPU
//
// program.hex is read from the project's code/ folder (../../code/ from simulation/modelsim/,
// where Quartus runs ModelSim). Build it with generatehex.sh in code/c_programs/.
// To read it from another folder, pass +code=<folder>/ (for example +code=./ from code/).
//
// The test input (the inputs and the expected paths) is in the task test_input below.
//
// Memory map (same as Path_Planner_Dec.c):
//   0x02000000 ENCRYPTED_HI   0x02000004 ENCRYPTED_LO
//   0x02000008 IS_ENCRYPTED   0x0200000C NEXT_NODE   0x0200000D CURRENT_NODE
//   0x02000010 .. 0x02000014  MESSAGE_0 .. MESSAGE_4
//   0x02000018 NODE_POINT     0x0200001C CPU_DONE
//
// Decrypted code (8 bytes, byte 0 first): byte 0 done flag, bytes 1..5 message,
// byte 6 next pick-up node, byte 7 drop node. The testbench has no cipher code. It knows the
// decrypted code of the encrypted codes in the table in task known_code below. For those, it
// checks the message and the inputs for the next run. For any other encrypted code, it prints
// "Unidentified code", shows what the CPU wrote, and checks only the paths.
//
// Run 1: the CPU plans the path from the current node to the next node (is_encrypted = 0),
// or to the drop node (is_encrypted = 1). For a code with the done flag at 0, the program
// also writes the inputs of its next run: IS_ENCRYPTED = 0, CURRENT_NODE = the drop node,
// NEXT_NODE = the next pick-up node. The testbench checks them, then resets the CPU (data
// memory is kept) for run 2, which has to plan the path from the drop node to the pick-up.
//
// Run 2 is done three times, after a reset 32, 33 and 34 cycles after CPU_DONE. After
// CPU_DONE the program waits in a loop of one jump instruction. The jump and the two
// instructions it flushes pass through the pipeline in a 3-cycle pattern, so at any cycle the
// Decode/Execute register holds either the jump or an empty slot. A pipeline register that
// reset does not clear only shows its bug when the reset lands on the jump: three resets on
// three cycles in a row always hit it once.
//
// Pass +dump to keep the dump.vcd waveform (it is large for this program).

module tb;

// registers to send data
reg clk;
reg reset;
reg Ext_MemWrite;
reg [31:0] Ext_WriteData, Ext_DataAdr;

// Wire Ouputs from Instantiated Modules
wire [31:0] WriteData, DataAdr, ReadData;
wire MemWrite;
wire [31:0] PCW, Result, DataAdrW, WriteDataW;

// Initialize Top Module
pl_riscv_cpu uut (clk, reset, Ext_MemWrite, Ext_WriteData, Ext_DataAdr, MemWrite, WriteData, DataAdr, ReadData, PCW, Result, DataAdrW, WriteDataW);

// cycle limits of each run, within the 12 ms simulation time: run 1 decrypts (about 472k
// cycles on the pipelined CPU), run 2 only plans a path
localparam MAX_CYCLES_RUN1 = 900000;
localparam MAX_CYCLES_RUN2 = 150000;

// run 2 is repeated after RESTARTS resets, RESTART_WAIT + 0, 1, 2 .. cycles after CPU_DONE
localparam RESTARTS = 3;
localparam RESTART_WAIT = 32;
integer restart = 0;

integer error_count = 0, cycles = 0, run = 1;
integer fw = 0, fd = 0;
integer i = 0, num_values = 0;       // run 1: node points seen, expected
integer j = 0, num_next = 0;         // run 2: node points seen, expected
reg [5:0] register_array [0:63];     // expected path of run 1
reg [5:0] next_array [0:63];         // expected path of run 2 (done flag 0)
reg running = 0;                     // the CPU is out of reset and being checked

reg [8*256-1:0] code_dir, file_name;   // folder of program.hex

integer is_encrypted = 0, current_node = 0, next_node = 0;
reg [63:0] enc_block = 0;
reg known = 0;                       // enc_block is in the table of known encrypted codes
reg [63:0] known_plain = 0;          // its decrypted code, from the table
reg [7:0] exp_done = 0, exp_pickup = 0, exp_drop = 0;
reg [39:0] exp_message = 0;          // MESSAGE_0 (code byte 1) in [39:32] .. MESSAGE_4 in [7:0]
reg [39:0] cpu_message;
reg [7:0] cpu_is_encrypted, cpu_next_node, cpu_current_node;
reg [7:0] run2_from = 0, run2_to = 0; // the path run 2 has to plan

event start_run2;

// ---------------- Test input: edit it to test another move ----------------
// Encrypted code            : one of the codes in task known_code below, or your own from
//                             bash encrypt.sh -f <done flag> -m <message> -p <pick-up node> -d <drop node>
//                             (enc_block is the "Encrypted block" it prints). For your own code,
//                             the message and the inputs for the next run are not checked.
// Expected path             : bash c_simulator.sh -f Path_Planner_Dec.c -c <current node> -n <encrypted code> -e 1
//                             (or -n <node> -e 0 for a plain move)
// Expected path of run 2    : the "Next current_node" and "Next next_node" lines it prints,
//                             with -c <current_node> -n <next_node> -e 0

// add one node to the expected path of run 1
task expect_node(input integer node);
    begin
        if (num_values < 64) register_array[num_values] = node;
        num_values = num_values + 1;
    end
endtask

// add one node to the expected path of run 2 (only for a code with the done flag at 0)
task expect_next_node(input integer node);
    begin
        if (num_next < 64) next_array[num_next] = node;
        num_next = num_next + 1;
    end
endtask

task test_input;
    begin
        // test input begin
        is_encrypted = 1;                       // 1: enc_block is used, 0: next_node is used
        current_node = 7;                       // where the bot is (35 = start box)
        next_node    = 0;                       // is_encrypted = 0: the node to go to
        enc_block    = 64'hE3399C2AAF0E5CA0;    // is_encrypted = 1: encrypted code, 16 hex digits
        // expected path from the C simulator, first node first
        expect_node(7);
        expect_node(5);
        expect_node(8);
        expect_node(20);
        expect_node(27);
        expect_node(29);
        expect_node(26);
        // done flag 0: expected path of run 2, from the drop node to the next pick-up node
        expect_next_node(26);
        expect_next_node(29);
        expect_next_node(27);
        expect_next_node(20);
        expect_next_node(8);
        expect_next_node(11);
        expect_next_node(9);
        expect_next_node(12);
        // test input end
    end
endtask

// ---------------- Known encrypted codes ----------------
// The decrypted code of each encrypted code below, as encrypt.sh makes it with the options in
// the comment. For any other encrypted code, found is 0.
task known_code(input [63:0] code, output found, output [63:0] plain);
    begin
        found = 1;
        case (code)
            64'hE3399C2AAF0E5CA0: plain = 64'h0048454C4C4F0C1A;   // -f 0 -m HELLO -p 12 -d 26
            64'h21020660468109D7: plain = 64'h00474F0000002421;   // -f 0 -m GO -p 36 -d 33
            64'hD30E1799F911813A: plain = 64'h0000000000000316;   // -f 0 -p 3 -d 22 (no message)
            64'h988CEBC355E41A9D: plain = 64'h0057415659000324;   // -f 0 -m WAVY -p 3 -d 36
            64'hD01C53F5BFD076BA: plain = 64'h0142594500000011;   // -f 1 -m BYE -d 17
            64'h5916B183D4912EA8: plain = 64'h01454E440000091D;   // -f 1 -m END -p 9 -d 29
            default: begin
                found = 0;
                plain = 0;
            end
        endcase
    end
endtask

// the heading of one run 2
task show_run2_header;
    begin
        $display("---------------- Run 2 (reset %0d of %0d, %0d cycles after CPU_DONE): N%0d -> N%0d ----------------\n",
                 restart + 1, RESTARTS, RESTART_WAIT + restart, run2_from, run2_to);
    end
endtask

// the message bytes as text, without the 0x00 bytes (no character)
task write_text(input [39:0] bytes);
    integer n;
    begin
        for (n = 4; n >= 0; n = n - 1)
            if (bytes[8*n +: 8] != 0) $write("%c", bytes[8*n +: 8]);
    end
endtask

// ------------------------------------------------------------------

// waveform dump (opened in pl_riscv_cpu.v) is off unless +dump is given
initial begin
    if (!$test$plusargs("dump")) begin
        #1 $dumpoff;
    end
end

// generate clock
always begin
    clk <= 1; # 5; clk <= 0; # 5;
end

// write one word into data memory while the CPU is held in reset
task ext_write(input [31:0] addr, input [31:0] data);
    begin
        Ext_MemWrite = 1; Ext_WriteData = data; Ext_DataAdr = addr; #10;
        Ext_MemWrite = 0; Ext_WriteData = 0;    Ext_DataAdr = 0;    #10;
    end
endtask

// read the message and the three inputs the program may write back, from data memory
task read_outputs;
    begin
        cpu_message = {uut.datamem.data_ram[4][7:0], uut.datamem.data_ram[4][15:8],
                       uut.datamem.data_ram[4][23:16], uut.datamem.data_ram[4][31:24],
                       uut.datamem.data_ram[5][7:0]};
        cpu_is_encrypted = uut.datamem.data_ram[2][7:0];
        cpu_next_node    = uut.datamem.data_ram[3][7:0];
        cpu_current_node = uut.datamem.data_ram[3][15:8];
    end
endtask

// write the verdict and end the simulation
task finish_test;
    begin
        running = 0;
        fw = $fopen("results.txt","w");
        if (error_count === 0 && i != 0) begin
            $fdisplay(fw, "%02h", "No Errors");
            $display("No errors encountered, congratulations!");
        end
        else begin
            $fdisplay(fw, "%02h", "Errors");
            $display("Error(s) encountered, please check your design!");
        end
        $fclose(fw);
        $stop;
    end
endtask

// start run 2 if expect_next_node lines were given, otherwise finish
task start_next_run;
    begin
        if (num_next == 0) begin
            $display("(no expect_next_node lines in the test input, so run 2 is not done)\n");
            finish_test;
        end
        else begin
            show_run2_header;
            -> start_run2;
        end
    end
endtask

// run 1 has set CPU_DONE: an encrypted code from the table
task check_known_code;
    begin
        $display("---------------- Message ----------------\n");
        $write("Expected MESSAGE = %h (\"", exp_message); write_text(exp_message);
        $write("\"), Actual MESSAGE = %h (\"", cpu_message); write_text(cpu_message); $display("\")");
        if (cpu_message !== exp_message) begin
            error_count = error_count + 1'b1;
            $display("Error Count  %d -> Mismatch in MESSAGE_0 .. MESSAGE_4, Check your design.\n", error_count);
        end
        else $display("No Error in the Message.\n");

        $display("---------------- Inputs for the next run ----------------\n");
        if (exp_done == 0) begin
            $display("Expected IS_ENCRYPTED = 0, CURRENT_NODE = %0d, NEXT_NODE = %0d", exp_drop, exp_pickup);
            $display("Actual   IS_ENCRYPTED = %0d, CURRENT_NODE = %0d, NEXT_NODE = %0d",
                     cpu_is_encrypted, cpu_current_node, cpu_next_node);
            if (cpu_is_encrypted !== 0 || cpu_current_node !== exp_drop || cpu_next_node !== exp_pickup) begin
                error_count = error_count + 1'b1;
                $display("Error Count  %d -> Mismatch in the inputs for the next run, Check your design.\n", error_count);
                finish_test;
            end
            else begin
                $display("No Error in the inputs for the next run.\n");
                run2_from = exp_drop;
                run2_to   = exp_pickup;
                start_next_run;
            end
        end
        else begin
            $display("Done flag = 1: the inputs have to stay as they are");
            $display("Expected IS_ENCRYPTED = 1, CURRENT_NODE = %0d, NEXT_NODE = %0d", current_node, next_node);
            $display("Actual   IS_ENCRYPTED = %0d, CURRENT_NODE = %0d, NEXT_NODE = %0d",
                     cpu_is_encrypted, cpu_current_node, cpu_next_node);
            if (cpu_is_encrypted !== 1 || cpu_current_node !== current_node || cpu_next_node !== next_node) begin
                error_count = error_count + 1'b1;
                $display("Error Count  %d -> The inputs were changed, but the done flag is 1, Check your design.\n",
                         error_count);
            end
            else $display("No Error, the inputs were left as they are.\n");
            finish_test;
        end
    end
endtask

// run 1 has set CPU_DONE: an encrypted code that is not in the table. Its decrypted code is
// not known here, so the message and the inputs for the next run are shown, not checked
task show_unidentified_code;
    begin
        $display("---------------- Message ----------------\n");
        $write("Actual MESSAGE = %h (\"", cpu_message); write_text(cpu_message); $display("\")");
        $display("Unidentified code: the message is not checked.\n");

        $display("---------------- Inputs for the next run ----------------\n");
        $display("Actual   IS_ENCRYPTED = %0d, CURRENT_NODE = %0d, NEXT_NODE = %0d",
                 cpu_is_encrypted, cpu_current_node, cpu_next_node);
        $display("Unidentified code: these inputs are not checked.\n");
        if (cpu_is_encrypted === 0) begin
            // the program wrote the inputs of a next run, so the CPU has to plan it too
            run2_from = cpu_current_node;
            run2_to   = cpu_next_node;
            start_next_run;
        end
        else begin
            if (num_next != 0) begin
                // the test input expects a run 2, but the program on the CPU did not set one up
                error_count = error_count + 1'b1;
                $display("Error Count  %d -> expect_next_node lines are given, but IS_ENCRYPTED was not set to 0 for the next run, Check your design.\n",
                         error_count);
            end
            finish_test;
        end
    end
endtask

// run 1 has set CPU_DONE
task end_run1;
    begin
        if (i < num_values) begin
            error_count = error_count + 1'b1;
            $display("Error Count  %d -> Missing Node Points, Check your design.\n", error_count);
        end
        if (!is_encrypted) finish_test;
        else begin
            read_outputs;
            if (known) check_known_code;
            else show_unidentified_code;
        end
    end
endtask

initial begin
    reset = 1;
    Ext_MemWrite = 0; Ext_WriteData = 0; Ext_DataAdr = 0;
    if (!$value$plusargs("code=%s", code_dir)) code_dir = "../../code/";

    $display("### eYRC Task 3B testbench ###\n");

    // wait until instr_mem.v has loaded its own program.hex, then load the one in code/
    #1;
    file_name = {code_dir, "program.hex"};
    fd = $fopen(file_name, "r");
    if (fd == 0) begin
        $display("%0s not found. Build it with generatehex.sh in code/c_programs/.", file_name);
        $stop;
    end
    $fclose(fd);
    $readmemh(file_name, uut.instrmem.instr_ram);
    $display("Program : %0s", file_name);

    test_input;
    $display("Test input: task test_input in tb.v\n");

    if (is_encrypted) begin
        known_code(enc_block, known, known_plain);
        $display("Encrypted code (input) = %h, current node (input) = %0d", enc_block, current_node);
        if (known) begin
            exp_done    = known_plain[63:56];
            exp_message = known_plain[55:16];
            exp_pickup  = known_plain[15:8];
            exp_drop    = known_plain[7:0];
            $write("Decrypted code (expected) = %h: done flag = %0d, message = \"", known_plain, exp_done);
            write_text(exp_message);
            $display("\", next pick-up node = %0d, drop node = %0d", exp_pickup, exp_drop);
        end
        else begin
            $display("Unidentified code: %h is not in the testbench's table of known encrypted codes", enc_block);
            $display("(task known_code). The paths are checked; the message and the inputs for the next run are not.");
        end
    end
    else begin
        $display("Next node (input) = %0d, not encrypted, current node (input) = %0d", next_node, current_node);
    end
    $display("");
    $display("---------------- Path Planning ----------------\n");

    #9;
    ext_write(32'h02000000, enc_block[63:32]);                      // ENCRYPTED_HI (bytes 0..3)
    ext_write(32'h02000004, enc_block[31:0]);                       // ENCRYPTED_LO (bytes 4..7)
    ext_write(32'h02000008, is_encrypted);                          // IS_ENCRYPTED
    ext_write(32'h0200000c, {current_node[7:0], next_node[7:0]});   // NEXT_NODE, CURRENT_NODE
    ext_write(32'h02000010, 0);                                     // MESSAGE_0 .. MESSAGE_3
    ext_write(32'h02000014, 0);                                     // MESSAGE_4
    ext_write(32'h02000018, 0);                                     // NODE_POINT
    ext_write(32'h0200001c, 0);                                     // CPU_DONE

    reset = 0;
    // External Memory Access Disabled
    Ext_MemWrite = 0; Ext_WriteData = 0; Ext_DataAdr = 0;
    running = 1;
end

// run 2: once the program has reached its final loop, reset the CPU without touching data
// memory, so it starts again with the inputs it wrote
initial begin
    forever begin
        @(start_run2);
        running = 0;
        repeat (RESTART_WAIT + restart) @(posedge clk);
        #1 reset = 1;
        repeat (8) @(posedge clk);
        #1 reset = 0;
        run = 2; cycles = 0;
        running = 1;
    end
end

always @(negedge clk) begin
    if (running) begin
        cycles = cycles + 1;
        if (cycles > (run == 1 ? MAX_CYCLES_RUN1 : MAX_CYCLES_RUN2)) begin
            error_count = error_count + 1'b1;
            $display("Error Count  %d -> CPU_DONE was not set after %0d cycles in run %0d, Check your design.\n",
                     error_count, run == 1 ? MAX_CYCLES_RUN1 : MAX_CYCLES_RUN2, run);
            if (run == 2)
                $display("After a reset the CPU has to start again from address 0: reset has to clear every pipeline register.\n");
            finish_test;
        end
    end

    if (MemWrite && running) begin
        if (DataAdr === 32'h02000018) begin
            if (run == 1) begin
                $display("Expected NODE POINT = %d, Actual NODE POINT = %d", register_array[i], WriteData);
                if (i >= num_values || register_array[i] != WriteData || WriteData[0] === 1'bx) begin
                    error_count = error_count + 1'b1;
                    $display("Error Count  %d -> Mismatch in Node Points, Check your design.\n", error_count);
                end
                else $display("No Error in this Node Point.\n");
                i = i + 1'b1;
            end
            else begin
                $display("Expected NODE POINT = %d, Actual NODE POINT = %d", next_array[j], WriteData);
                if (j >= num_next || next_array[j] != WriteData || WriteData[0] === 1'bx) begin
                    error_count = error_count + 1'b1;
                    $display("Error Count  %d -> Mismatch in Node Points of run 2, Check your design.\n", error_count);
                end
                else $display("No Error in this Node Point.\n");
                j = j + 1'b1;
            end
        end

        if (DataAdr === 32'h0200001c & WriteData === 32'h1) begin
            if (run == 1) end_run1;
            else begin
                if (j < num_next) begin
                    error_count = error_count + 1'b1;
                    $display("Error Count  %d -> Missing Node Points in run 2, Check your design.\n", error_count);
                end
                if (restart < RESTARTS - 1 && error_count == 0) begin
                    // again, after a reset at the next cycle of the final loop
                    restart = restart + 1;
                    j = 0;
                    show_run2_header;
                    -> start_run2;
                end
                else finish_test;
            end
        end
    end
end

endmodule
