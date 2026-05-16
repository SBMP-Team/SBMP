#include "lookup.h"
#include <stdio.h>

#define MEMORY_OFFSET 0x200

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

bool read_instruction(FILE *f, uint8_t *opcode, uint16_t *operand) {
    int op = fgetc(f);
    if (op == EOF) {
        return false;
    }

    int low = fgetc(f);
    int high = fgetc(f);

    if (low == EOF || high == EOF) {
        return false;
    }

    *opcode = (uint8_t)op;
    *operand = (uint16_t)(low | (high << 8));

    return true;
}

void write_instruction(FILE *f, uint8_t opcode, uint16_t operand) {
    uint16_t opcode16 = opcode;

    fwrite(&opcode16, sizeof(uint16_t), 1, f);
    fwrite(&operand, sizeof(uint16_t), 1, f);
}

int main(int argc, char* argv[]) {
    printf("SBMP Linker\n");
    FILE *infile = fopen(argv[1], "rb");
    FILE *outfile = fopen(argv[2], "wb");

    if (infile == NULL){
        printf("Unable to open in file from %s\n", argv[1]);
    }
    if (outfile == NULL) {
        printf("Unable to open out file from %s\n", argv[2]);
    }
    //write zeroes for the first 512 lines, for program memory.
    uint16_t zero = 0;

    for (int i = 0; i < MEMORY_OFFSET; i++) {
        fwrite(&zero, sizeof(uint16_t), 1, outfile);
    }

    uint8_t opcode = 0;
    uint16_t operand = 0;

    //read optcode/instruction pairs from the in file and write each to its own line.
    while (read_instruction(infile, &opcode, &operand)) {
        write_instruction(outfile, opcode, operand);
    }


    return 0;
}