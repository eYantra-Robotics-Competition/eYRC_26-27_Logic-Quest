#!/bin/bash
# If this file has Windows (CRLF) line endings, bash can't run it: convert it to LF
# and start again. Keep this first, and keep the "#" at the end of the line.
if grep -q $'\r$' "$0" 2>/dev/null; then sed -i 's/\r$//' "$0" && exec bash "$0" "$@"; exit 1; fi #

help() {
    # display help
   echo "Local testbench: runs Path_Planner_Dec.c on fixed cases and checks its output"
   echo
   echo "Usage: bash test.sh [-h] [-f <file_path>]"
   echo "options:"
   echo "h     Print this Help."
   echo "f     Path of the C program file (default: Path_Planner_Dec.c)."
   echo
   echo "The output is checked line by line, in the structure given at the top of"
   echo "Path_Planner_Dec.c (\"Output (PC)\"). Lines that start with \"dbg:\" (your"
   echo "debug prints) are skipped."
   echo
}

file_path="Path_Planner_Dec.c"

while getopts "hf:" opt; do
    case "$opt" in
        f) file_path=$OPTARG ;;
        h) help; exit 0 ;;
        *) help; exit 1 ;;
    esac
done

echo; echo "================================"
echo; echo "          Local test            ";
echo; echo "--------------------------------"; echo

echo "Testing file: $file_path"
echo "Lines that start with \"dbg:\" (debug prints) are skipped."

echo; echo "================================"; echo

if [ ! -f "$file_path" ]; then
    echo "File $file_path does not exist."
    exit 1
fi

gcc "$file_path" -o test_output_file
if [ $? -ne 0 ]; then
    echo; echo "Compilation failed, kindly check for errors."
    exit 1
fi
trap 'rm -f test_output_file test_output_file.exe' EXIT

passed=0
total=0

# run_case <label> <current_node> <next_node> <is_encrypted> <expected line> ...
run_case() {
    local label=$1 current=$2 next=$3 encrypted=$4
    shift 4
    local expected=("$@")
    local actual=()
    local output status problem="" i

    total=$((total + 1))
    output=$(timeout 10 ./test_output_file "$current" "$next" "$encrypted" 2>&1)
    status=$?
    # the lines to check: everything except the debug lines
    [ -n "$output" ] && mapfile -t actual < <(printf '%s\n' "$output" | grep -v '^dbg:')

    if [ $status -eq 124 ]; then
        problem="the program did not finish within 10 seconds"
    elif [ $status -ne 0 ]; then
        problem="the program stopped with exit code $status"
    else
        for (( i = 0; i < ${#expected[@]} || i < ${#actual[@]}; i++ )); do
            if (( i >= ${#actual[@]} )); then
                problem="line $((i + 1)): expected \"${expected[i]}\", got nothing (line missing)"
                break
            elif (( i >= ${#expected[@]} )); then
                problem="line $((i + 1)): extra line \"${actual[i]}\""
                break
            elif [ "${expected[i]}" != "${actual[i]}" ]; then
                problem="line $((i + 1)): expected \"${expected[i]}\", got \"${actual[i]}\""
                break
            fi
        done
    fi

    if [ -z "$problem" ]; then
        printf "Case %d: %-45s PASS\n" "$total" "$label"
        passed=$((passed + 1))
    else
        printf "Case %d: %-45s FAIL\n" "$total" "$label"
        echo "        $problem"
        echo "        run it: bash c_simulator.sh -f $file_path -c $current -n $next -e $encrypted"
    fi
}

# is_encrypted = 0: the first move, from the start box
run_case "N35 -> N7, is_encrypted = 0" 35 7 0 \
    35 30 13 14 15 7

# is_encrypted = 0: to N36, at the far end of the wavy line
run_case "N3 -> N36, is_encrypted = 0" 3 36 0 \
    3 6 1 36

# is_encrypted = 0: already at the next node
run_case "N14 -> N14, is_encrypted = 0" 14 14 0 \
    14

# is_encrypted = 1: done flag 0, 5-character message
run_case "N7, block E3399C2AAF0E5CA0" 7 E3399C2AAF0E5CA0 1 \
    "Message : HELLO" 7 5 8 20 27 29 26 "Next current_node : 26" "Next next_node : 12"

# is_encrypted = 0: the next run of the case above
run_case "N26 -> N12, is_encrypted = 0" 26 12 0 \
    26 29 27 20 8 11 9 12

# is_encrypted = 1: done flag 0, short message
run_case "N12, block 21020660468109D7" 12 21020660468109D7 1 \
    "Message : GO" 12 9 11 8 5 7 15 14 13 30 33 "Next current_node : 33" "Next next_node : 36"

# is_encrypted = 1: done flag 0, no message, the bot is already at the drop node
run_case "N22, block D30E1799F911813A" 22 D30E1799F911813A 1 \
    "Message : " 22 "Next current_node : 22" "Next next_node : 3"

# is_encrypted = 1: done flag 1, the last block
run_case "N22, block D01C53F5BFD076BA" 22 D01C53F5BFD076BA 1 \
    "Message : BYE" 22 25 23 16 17 "Done"

echo
echo "$passed/$total cases passed"
[ $passed -eq $total ]
