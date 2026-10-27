#!/bin/bash
# If this file has Windows (CRLF) line endings, bash can't run it: convert it to LF
# and start again. Keep this first, and keep the "#" at the end of the line.
if grep -q $'\r$' "$0" 2>/dev/null; then sed -i 's/\r$//' "$0" && exec bash "$0" "$@"; exit 1; fi #

help() {
    # display help
   echo "Simulate the path_planning algorithm with decryption"
   echo
   echo "Usage: bash c_simulator.sh -h, -f <file_path> -c <current_node> -n <next_node> -e <is_encrypted>"
   echo "options:"
   echo "h     Print this Help."
   echo "f     Path of the C program file."
   echo "c     Current node, 1 to 36: where the bot is (35 = start box, for the first location)."
   echo "n     Next node: a node number (is_encrypted = 0),"
   echo "      or the encrypted code, 16 hex digits (is_encrypted = 1)."
   echo "      Make a block with: bash encrypt.sh -f <done_flag> -m <message> -p <pickup_node> -d <drop_node>"
   echo "e     is_encrypted: 0 or 1."
   echo
   echo "To check your program on fixed cases: bash test.sh"
   echo
}

if [ "$#" -eq 8 ]; then
    while getopts "hf:c:n:e:" opt; do
        case "$opt" in
            f) file_path=$OPTARG ;;
            c) current_node=$OPTARG ;;
            n) next_node=$OPTARG ;;
            e) is_encrypted=$OPTARG ;;
            h) help ;;
            :) echo "argument missing for $ARG" ;;
            \?) echo "Something is wrong" ;;
        esac
    done
else
    help
    exit 1
fi

echo; echo "================================"
echo; echo "          C Simulator           ";
echo; echo "--------------------------------"; echo

echo "Executing file: $file_path"

echo; echo "================================"; echo

if [ ! -f "$file_path" ]; then
    echo "File $file_path does not exist."
    exit 1
fi

gcc "$file_path" -o output_file
if [ $? -ne 0 ]; then
    echo; echo "Compilation failed, kindly check for errors."
    exit 1
fi

./output_file "$current_node" "$next_node" "$is_encrypted"
rm -f output_file
