#!/bin/bash
# If this file has Windows (CRLF) line endings, bash can't run it: convert it to LF
# and start again. Keep this first, and keep the "#" at the end of the line.
if grep -q $'\r$' "$0" 2>/dev/null; then sed -i 's/\r$//' "$0" && exec bash "$0" "$@"; exit 1; fi #

# run this from code/c_programs/: program.hex and program.lss are written to code/
[ ! -z "${1}" ] && infile="${1}" || infile="Path_Planner_Dec.c"

ARCH=rv32i
ROM=4096 # instruction memory: 1024 words (instr_mem.v MEM_SIZE = 1024)
RAM=512    # data memory: 128 words (data_mem.v MEM_SIZE = 128)
STACK=184  # 0x02000148 .. 0x020001FF

CFLAGS="  -march=$ARCH -mabi=ilp32 --specs=picolibc.specs -Os -g3 -flto -DPICOLIBC_INTEGER_PRINTF_SCANF -Wall"
LDFLAGS=" -march=$ARCH -mabi=ilp32 --specs=picolibc.specs -Os -g3 -flto -DPICOLIBC_INTEGER_PRINTF_SCANF "
LDFLAGS+=" -Wl,--gc-sections,--defsym=__flash=0x00000000,--defsym=__flash_size=$ROM --crt0=minimal" #" -nostartfiles"
LDFLAGS+=" -Wl,--defsym=__ram=0x02000000,--defsym=__ram_size=$RAM,--defsym=__stack_size=$STACK -Tpicolibc.ld"

cd ../

riscv64-unknown-elf-gcc $CFLAGS -c "c_programs/$infile" -o .temp.file.o && \
riscv64-unknown-elf-gcc $LDFLAGS -o .temp.file.elf .temp.file.o && \
riscv64-unknown-elf-objdump --visualize-jumps -t -S --source-comment='     ### ' .temp.file.elf -M no-aliases,numeric > program.lss && \
riscv64-unknown-elf-objcopy -O binary .temp.file.elf .temp.file.bin && \
truncate -s $ROM .temp.file.bin && \
riscv64-unknown-elf-objcopy --verilog-data-width=4 --reverse-bytes=4 -I binary -O verilog .temp.file.bin program.hex && \
riscv64-unknown-elf-size -B --common .temp.file.elf && \

echo "program.hex and program.lss have been successfully generated from $infile"  || \
echo "And therefore, $infile could not be converted into binary format. :("

rm -f .temp.file.*
