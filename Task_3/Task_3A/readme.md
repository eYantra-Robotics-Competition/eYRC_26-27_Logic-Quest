# Task 3A - Path Planner with Decryption

This folder has the files for Task 3A. What your program must do, its inputs and outputs, and
how to submit it are in the Task 3A instructions in the Logic Quest theme book, on the
[e-Yantra portal](https://portal.e-yantra.org).

## What's in `code/c_programs`

| File | What it is |
|---|---|
| `Path_Planner_Dec.c` | The program you complete. Only edit inside the `Add your code here` blocks |
| `c_simulator.sh` | Compiles your program with `gcc` and runs one move on your computer |
| `encrypt.sh` | Makes encrypted codes to test with |
| `test.sh` | Runs your program on 8 fixed moves and checks every line it prints |
| `generatehex.sh` | Builds your program for the RISC-V CPU and writes `program.hex` and `program.lss` into `code/` |

## Running the scripts

Run them from `code/c_programs`, in your WSL Ubuntu terminal on Windows or a terminal on Ubuntu:

```sh
bash c_simulator.sh -f Path_Planner_Dec.c -c 35 -n 7 -e 0   # one move: from N35 to N7
bash encrypt.sh -f 0 -m HELLO -p 12 -d 26                   # make an encrypted code
bash test.sh                                                # the 8 fixed moves
bash generatehex.sh                                         # program.hex for the CPU
```

Add `-h` to a script to see all its options.

Always start a script with `bash`, as above, not with `./`. If a script has Windows (CRLF) line
endings, for example after a zip download, starting it with `bash` fixes them.
