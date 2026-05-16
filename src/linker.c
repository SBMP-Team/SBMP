#include "lookup.h"
#include <stdio.h>

#define MEMORY_OFFSET 0x0200
#define PPU_OFFSET 0x8000

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>

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
    if (strcmp(argv[1], "-h") == 0 || strcmp(argv[1], "--help") == 0) {
        printf("USAGE: \n -h/--help Prints this help menu and exits.\n -i/--input-file [filepath] Specifies the input .o file\n -p/--ppu-file [filepath] Specifies the input .ppu file\n -o/--output-file [filepath] Specifies the output .sbmp file\nFLAGS:\n --ram-offset [0x0-0xFFFF] This sets the 0x0 register to specify where usable RAM starts\n --rom-offset [0x0-0xFFFF] this sets the 0x1 register to specify where program ROM starts, the usable ram will be between this and the ram offset.\n --ppu-offset [0x0-0xFFFF] Specifies the offset of PPU Memory, this will set the 0x2 register to this value.\n");
        return 0;
    }
    int arg = 0;
    FILE *infile;
    FILE *outfile;

    while (argv[arg]!=NULL) {
        if (argv[arg][0] == '-') {
            switch (argv[arg][1]) {
                case '-': {
                    if (strcmp(argv[arg], "--ram-offset") == 0) {
                        arg ++;

                    }
                }
                case 'i': {
                    arg++;
                    infile = fopen(argv[arg], "r");
                    if (infile == NULL) {
                        printf("Unable to open input file from %s\n", argv[arg]);
                    }
                }
                case 'o': {
                    arg++;
                    outfile = fopen(argv[arg], "w");
                    if (outfile == NULL) {
                        printf("Unable to open output file from %s\n", argv[arg]);
                    }
                }
                case 'p': {
                    arg++;
                    printf("PPU File loading not implemented");
                }
            }
        }
    }




    if (infile == NULL){
        printf("Input file invalid");
    }
    if (outfile == NULL) {
        printf("Output file invalid");
    }
    //write zeroes for the first 512 lines, for program memory.
    uint16_t zero = 0;

    for (int i = 0; i < MEMORY_OFFSET; i++) {
        fwrite(&zero, sizeof(uint16_t), 1, outfile);
    }

    uint8_t opcode = 0;
    uint16_t operand = 0;
    size_t words = MEMORY_OFFSET;

    //read optcode/instruction pairs from the in file and write each to its own line.
    while (read_instruction(infile, &opcode, &operand)) {
        write_instruction(outfile, opcode, operand);
        words +=2;
        if (words >= PPU_OFFSET) {
            perror("More instructions than max, would leak into ppu space. specify --ignore-ppu-leak to ignore this if not using ppu space. specify --ppu-offset to define a new ppu offset if you need more program space.");
            goto error;
        }
    }
    printf("Wrote %lu words to output file, starting ppu section.", words);


    fclose(infile);
    fclose(outfile);

    return 0;
    error:
    fclose(infile);
    fclose(outfile);
    return 1;
}