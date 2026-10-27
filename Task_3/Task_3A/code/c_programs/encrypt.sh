#!/bin/bash
# If this file has Windows (CRLF) line endings, bash can't run it: convert it to LF
# and start again. Keep this first, and keep the "#" at the end of the line.
if grep -q $'\r$' "$0" 2>/dev/null; then sed -i 's/\r$//' "$0" && exec bash "$0" "$@"; exit 1; fi #

help() {
    # display help
   echo "Make the encrypted input block for Path_Planner_Dec.c"
   echo
   echo "Usage: bash encrypt.sh -h, -f <done_flag> -m <message> -p <pickup_node> -d <drop_node>"
   echo "options:"
   echo "h     Print this Help."
   echo "f     Done flag: 0, or 1 for the last block (no pick-up after this drop)."
   echo "m     Message, up to 5 characters, e.g. HELLO (optional, default: no message)."
   echo "p     Next pick-up node, 1 to 36 (optional when the done flag is 1)."
   echo "d     Drop node for this block, 1 to 36."
   echo
   echo "Example: bash encrypt.sh -f 0 -m HELLO -p 12 -d 26"
   echo
}

done_flag=""
message=""
pickup_node=0
drop_node=""

while getopts "hf:m:p:d:" opt; do
    case "$opt" in
        f) done_flag=$OPTARG ;;
        m) message=$OPTARG ;;
        p) pickup_node=$OPTARG ;;
        d) drop_node=$OPTARG ;;
        h) help; exit 0 ;;
        *) help; exit 1 ;;
    esac
done

if [ -z "$done_flag" ] || [ -z "$drop_node" ]; then
    help
    exit 1
fi

cd "$(dirname "$0")"

# The input maker below is compiled from this script, run once, then deleted
gcc -x c -o encrypt_file - <<'EOF'
/*
* Logic Quest (LQ): Task 3A input maker (PC only)
*
* Builds the 8-byte decrypted code, and encrypts it
* with PRESENT-80 (key A1 B2 C3 D4 E5 F6 07 18 29 3A), the same cipher and key
* that Path_Planner_Dec.c decrypts. Use the printed encrypted block as the
* input of Path_Planner_Dec.c.
*
* Block (8 bytes, byte 0 first):
*   byte 0     : done flag (1 = last block: no pick-up after this drop)
*   byte 1..5  : message, 5 ASCII characters (0x00 = no character)
*   byte 6     : next pick-up node 1..36 (0 when the done flag is 1)
*   byte 7     : drop node 1..36 for this block
*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static const uint8_t SBOX[16] = { 0xC, 0x5, 0x6, 0xB, 0x9, 0x0, 0xA, 0xD,
                                  0x3, 0xE, 0xF, 0x8, 0x4, 0x7, 0x1, 0x2 };

/* PRESENT-80 encryption of one 64-bit block */
uint64_t present_encrypt(uint64_t state, uint64_t key_hi64, uint16_t key_lo16)
{
    /* 80-bit key register: k_hi = bits 79..16, k_lo = bits 15..0 */
    uint64_t k_hi = key_hi64;
    uint16_t k_lo = key_lo16;

    for (int round = 1; round <= 31; round++) {
        /* 1. add round key: the leftmost 64 bits of the key register */
        state ^= k_hi;

        /* 2. S-box layer: every nibble through the S-box */
        uint64_t s = 0;
        for (int n = 0; n < 16; n++)
            s |= (uint64_t)SBOX[(state >> (4 * n)) & 0xF] << (4 * n);

        /* 3. permutation layer: bit i moves to 16*i mod 63, bit 63 stays */
        uint64_t p = 0;
        for (int i = 0; i < 64; i++)
            if ((s >> i) & 1)
                p |= 1ULL << (i == 63 ? 63 : (16 * i) % 63);
        state = p;

        /* key schedule: rotate left by 61, S-box on bits 79..76, XOR round into bits 19..15 */
        uint64_t old_hi = k_hi;
        uint16_t old_lo = k_lo;
        /* rotating an 80-bit register left by 61 = rotating right by 19 */
        k_hi = (old_hi >> 19) | ((uint64_t)old_lo << 45) | (old_hi << 61);
        k_lo = (uint16_t)(old_hi >> 3);
        k_hi = (k_hi & 0x0FFFFFFFFFFFFFFFULL) | ((uint64_t)SBOX[k_hi >> 60] << 60);
        /* bits 19..15 of the register: bits 3..0 of k_hi and bit 15 of k_lo */
        k_hi ^= (uint64_t)(round >> 1);
        k_lo ^= (uint16_t)((round & 1) << 15);
    }
    return state ^ k_hi;   /* final round key K32 */
}

int main(int argc, char const *argv[])
{
    if (argc < 5) {
        printf("usage: ./encrypt_file <done_flag 0|1> <pickup_node> <drop_node 1..36> <message>\n");
        return 1;
    }
    int done        = atoi(argv[1]);
    int pickup      = atoi(argv[2]);
    int drop        = atoi(argv[3]);
    const char *msg = argv[4];
    size_t length   = strlen(msg);

    if (done != 0 && done != 1) {
        printf("the done flag must be 0 or 1\n");
        return 1;
    }
    if (drop < 1 || drop > 36) {
        printf("the drop node must be a node number from 1 to 36\n");
        return 1;
    }
    if (done == 0 && (pickup < 1 || pickup > 36)) {
        printf("the next pick-up node must be a node number from 1 to 36 (the done flag is 0)\n");
        return 1;
    }
    if (done == 1 && (pickup < 0 || pickup > 36)) {
        printf("the next pick-up node must be 0, or a node number from 1 to 36\n");
        return 1;
    }
    if (length > 5) {
        printf("the message can have at most 5 characters\n");
        return 1;
    }
    for (size_t i = 0; i < length; i++) {
        if (msg[i] < 0x20 || msg[i] > 0x7E) {
            printf("the message can only have printable ASCII characters\n");
            return 1;
        }
    }

    /* message bytes 1..5, 0x00 after the last character */
    uint64_t plain = (uint64_t)done << 56;
    for (size_t i = 0; i < length; i++)
        plain |= (uint64_t)(uint8_t)msg[i] << (48 - 8 * i);
    plain |= (uint64_t)pickup << 8;
    plain |= (uint64_t)drop;

    uint64_t cipher = present_encrypt(plain, 0xA1B2C3D4E5F60718ULL, 0x293A);

    printf("Done flag       : %d\n", done);
    printf("Message         : %s\n", msg);
    printf("Next pick-up    : %d\n", pickup);
    printf("Drop node       : %d\n", drop);
    printf("Plain block     : %016llX\n", (unsigned long long)plain);
    printf("Encrypted block : %016llX\n", (unsigned long long)cipher);
    return 0;
}
EOF
if [ $? -ne 0 ]; then
    echo; echo "Compilation of the input maker failed."
    exit 1
fi

./encrypt_file "$done_flag" "$pickup_node" "$drop_node" "$message"
status=$?
rm -f encrypt_file encrypt_file.exe
exit $status
