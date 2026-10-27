# Task 3B - Path Planner with Decryption on your pipelined CPU

This folder is the Task 3B Quartus project. It is the Task 2B pipelined CPU project
(`Task_2/pl_riscv_cpu`), with only the parts Task 3B needs added. You bring in your own CPU
from Task 2B and your own `Path_Planner_Dec.c` from Task 3A, make the few changes listed
below, build the program for the CPU and simulate it.

## What is new in this project

| File | What changed from the Task 2B project |
|---|---|
| `.test/tb.v` | New testbench. It writes the inputs into data memory, runs your program, checks the message, every node of the path and the inputs your program writes for its next run. Then it resets the CPU and checks that next run |
| `code/instr_mem.v` | 1024 words (4 KB) of instruction memory, and it loads `program.hex` |
| `pl_riscv_cpu.qsf` | The simulation runs for 12 ms, and the project lists `pl_reg_de.v`, `pl_reg_em.v`, `pl_reg_mw.v` and `hazard_unit.v` |

Every other file is the Task 2B boilerplate file, unchanged. Step 1 replaces them with yours.

## 1. Copy in your Task 2B CPU

Copy these files from your finished Task 2B `pl_riscv_cpu` project into this folder, replacing
the files that are here:

| From your Task 2B project | Into this project |
|---|---|
| Every file in `code/components/`, including your `pl_reg_de.v`, `pl_reg_em.v`, `pl_reg_mw.v`, `hazard_unit.v` and `datapath.v` | `code/components/` |
| `code/riscv_cpu.v` | `code/` |
| `code/data_mem.v` | `code/` |
| `code/pl_riscv_cpu.v`, only if you changed it | `code/` |

Don't copy these from Task 2B:

- `code/instr_mem.v`: the Task 2B one is too small for this program and loads the wrong file.
- `.test/tb.v`, `pl_riscv_cpu.qsf` and `pl_riscv_cpu.qpf`: use the ones in this folder.

If you added a component file with another name in Task 2B, add it to this project too
(**Project > Add/Remove Files in Project**).

## 2. Copy in your Task 3A program

Copy your whole Task 3A `code/c_programs/` folder into `code/` here, so that this project has
`code/c_programs/` with your finished `Path_Planner_Dec.c`, `c_simulator.sh`, `encrypt.sh`,
`generatehex.sh` and `test.sh`.

## 3. Changes expected in your files

These are the only changes to make to your Task 2B CPU.

### `code/data_mem.v`: 128 words of data memory

Your program uses 512 bytes of data memory, `0x02000000` to `0x020001FF`. Change two lines:

```verilog
module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 128) (   // was MEM_SIZE = 64

wire [ADDR_WIDTH-1:0] word_addr = wr_addr[DATA_WIDTH-1:2] % MEM_SIZE;              // was % 64
```

Keep the rest of your file. The program uses `sb`, `sh`, `sw`, `lb`, `lbu`, `lhu` and `lw`, so
your data memory needs the byte and half-word loads and stores. The Task 2B boilerplate
`data_mem.v` doesn't have `sh`, `lh` or `lhu`.

### `code/components/datapath.v`: reset clears every pipeline register

When an encrypted code's done flag is 0, your program writes the inputs of its next run into data memory,
and the CPU is reset to run again. The testbench does this. Data memory is kept.

While `reset` is 1, every pipeline register (Fetch/Decode, Decode/Execute, Execute/Memory and
Memory/Writeback) has to be cleared. After a reset, the CPU must start again from address 0.
A register that only holds its value during reset is not enough: the instruction left in it
runs again after the reset. How you make this change is up to you.

In Task 2B the CPU only started once, from power-on, so this never showed up there.

### `code/components/main_decoder.v`: branches set `ResultSrc` to `2'b00`

Check that branch instructions set `ResultSrc` to `2'b00`, not `2'bxx`. The Task 2B boilerplate
already does this; keep it if you changed the branch row. The hazard unit reads `ResultSrcE[0]`
to find loads, so an `x` there can stall a taken branch, and the branch then loses its target.

### `code/instr_mem.v`: nothing to change

It loads `program.hex` from `code/`. Keep the `$readmemh("program.hex", instr_ram);` line.

## 4. Build the program and simulate

In your WSL Ubuntu terminal on Windows, or a terminal on Ubuntu, go to `code/c_programs` and run:

```sh
bash generatehex.sh Path_Planner_Dec.c
```

It writes `program.hex` and `program.lss` into `code/`. The `text` size it prints must stay
under 4096 bytes. Run it again every time you change `Path_Planner_Dec.c`: the simulation runs
whatever is in `code/program.hex`.

**In Quartus / ModelSim:**

1. Open `pl_riscv_cpu.qpf` and run **Processing > Start > Start Analysis & Synthesis**.
   (A full compilation stops in the Fitter: the top module brings the CPU's debug buses out as
   pins, more than the device has. That is expected, this project is for simulation.)
2. **Tools > Run Simulation Tool > RTL Simulation**. The testbench `tb` runs for 12 ms.
3. The transcript must end with `No errors encountered, congratulations!`.

## The test input

The test input is the task `test_input` near the top of `.test/tb.v`:

```verilog
        is_encrypted = 1;                       // 1: enc_block is used, 0: next_node is used
        current_node = 7;                       // where the bot is (35 = start box)
        next_node    = 0;                       // is_encrypted = 0: the node to go to
        enc_block    = 64'hE3399C2AAF0E5CA0;    // is_encrypted = 1: encrypted code, 16 hex digits
        // expected path from the C simulator, first node first
        expect_node(7);
        ...
        // done flag 0: expected path of run 2, from the drop node to the next pick-up node
        expect_next_node(26);
        ...
```

Take the expected paths from `c_simulator.sh` (see the comments above the task in `tb.v`).
For a plain move, or an encrypted code with the done flag at 1, leave out `expect_next_node`.
With a plain node number, leave `enc_block` at 0.

The testbench knows the decrypted code of the six encrypted codes below. For these, it also
checks the message and the inputs your program writes for the next run.

| `enc_block` | Made with `bash encrypt.sh ...` | Decrypted code |
|---|---|---|
| `E3399C2AAF0E5CA0` | `-f 0 -m HELLO -p 12 -d 26` | `0048454C4C4F0C1A` |
| `21020660468109D7` | `-f 0 -m GO -p 36 -d 33` | `00474F0000002421` |
| `D30E1799F911813A` | `-f 0 -p 3 -d 22` (no message) | `0000000000000316` |
| `988CEBC355E41A9D` | `-f 0 -m WAVY -p 3 -d 36` | `0057415659000324` |
| `D01C53F5BFD076BA` | `-f 1 -m BYE -d 17` | `0142594500000011` |
| `5916B183D4912EA8` | `-f 1 -m END -p 9 -d 29` | `01454E440000091D` |

You can also use your own encrypted code from `encrypt.sh`. The transcript then says
`Unidentified code`: it shows the message and the inputs for the next run that your CPU wrote,
but doesn't check them. It still checks every node of the paths, and, if your program set
`IS_ENCRYPTED` to 0, the next run after each reset.

## Memory map (data memory)

| Address | Name | |
|---|---|---|
| `0x02000000` | `ENCRYPTED_HI` | input, encrypted block bytes 0..3 |
| `0x02000004` | `ENCRYPTED_LO` | input, encrypted block bytes 4..7 |
| `0x02000008` | `IS_ENCRYPTED` | input, 0 or 1. Your program writes 0 for the next run (done flag 0) |
| `0x0200000C` | `NEXT_NODE` | input. Your program writes the pick-up node for the next run (done flag 0) |
| `0x0200000D` | `CURRENT_NODE` | input. Your program writes the drop node for the next run (done flag 0) |
| `0x02000010` .. `0x02000014` | `MESSAGE_0` .. `MESSAGE_4` | output, the message |
| `0x02000018` | `NODE_POINT` | output, every node of the path, in order |
| `0x0200001C` | `CPU_DONE` | output, 1 when finished |
| `0x02000020` and up | | your program's working memory, stack at the top |

## If the simulation fails

| Transcript says | Look at |
|---|---|
| `Mismatch in Node Points` | Compare with `c_simulator.sh`. If the PC output is right, it's your CPU |
| `Mismatch in MESSAGE_0 .. MESSAGE_4` or `Mismatch in the inputs for the next run` | Your program's outputs (Task 3A), or a store instruction on your CPU (`sb`) |
| `CPU_DONE was not set after ... cycles in run 1` | `data_mem.v` size (step 3), the half-word loads and stores, or a hazard bug |
| `CPU_DONE was not set after ... cycles in run 2` and `After a reset the CPU has to start again from address 0` | The reset change in `datapath.v` (step 3). The testbench resets three times, on three cycles in a row, so a register that reset doesn't clear is always caught |
| `expect_next_node lines are given, but IS_ENCRYPTED was not set to 0` | With an unidentified code: the program on your PC wrote the inputs for a next run, but the CPU didn't. Check your CPU's byte stores (`sb`) |
| `program.hex not found` | Run `generatehex.sh` in `code/c_programs` |
