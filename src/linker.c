#include "lookup.h"
#include <stdio.h>

#define MEMORY_OFFSET 0x0200
#define PPU_OFFSET 0x8000

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
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
        printf("USAGE: \n -h/--help Prints this help menu and exits.\n -i/--input-file [filepath] Specifies the input .o file\n -p/--ppu-file [filepath] Specifies the input .ppu file\n -o/--output-file [filepath] Specifies the output .sbmp file\nFLAGS:\n --rom-offset [0x0-0xFFFF] this sets the 0x1 register to specify where program ROM starts, the usable ram will be between this and the ram offset.\n --ppu-offset [0x0-0xFFFF] Specifies the offset of PPU Memory, this will set the 0x2 register to this value.\n");
        return 0;
    }

    int arg = 0;
    FILE *infile = NULL;
    FILE *outfile = NULL;
    FILE *ppufile = NULL;

    uint16_t romOffset = MEMORY_OFFSET;
    uint16_t ppuOffset = PPU_OFFSET;

    while (argv[arg]!=NULL) {
        if (argv[arg][0] == '-') {
            switch (argv[arg][1]) {
                case '-': {
                    if (strcmp(argv[arg], "--rom-offset") == 0) {
                        arg ++;
                        romOffset = strtol(argv[arg], NULL, 0);
                        break;
                    }
                    if (strcmp(argv[arg], "--ppu-offset") == 0) {
                        arg ++;
                        ppuOffset = strtol(argv[arg], NULL,0);
                        break;
                    }
                    break;
                }
                case 'i': {
                    arg++;
                    infile = fopen(argv[arg], "rb");
                    if (infile == NULL) {
                        printf("Unable to open input file from %s\n", argv[arg]);
                    }
                    break;
                }
                case 'o': {
                    arg++;
                    outfile = fopen(argv[arg], "wb");
                    if (outfile == NULL) {
                        printf("Unable to open output file from %s\n", argv[arg]);
                    }
                    break;
                }
                case 'p': {
                    arg++;
                    ppufile = fopen(argv[arg], "rb");
                    if (outfile == NULL) {
                        printf("Unable to open output file from %s\n", argv[arg]);
                    }
                    break;
                }
            }
        }
        arg ++;
    }




    if (infile == NULL){
        printf("Input file invalid");
    }
    if (outfile == NULL) {
        printf("Output file invalid");
    }
    //write zeroes for the first 512 lines, for program memory.
    uint16_t zero = 0;
    uint16_t two = 0x2;
    fwrite(&two,sizeof(uint16_t),1,outfile);
    fwrite(&romOffset, sizeof(uint16_t),1,outfile);
    fwrite(&ppuOffset, sizeof(uint16_t),1,outfile);
    for (int i = two; i < romOffset-1; i++) {
        fwrite(&zero, sizeof(uint16_t), 1, outfile);
    }

    uint8_t opcode = 0;
    uint16_t operand = 0;
    size_t words = 0x1 + romOffset;

    //read optcode/instruction pairs from the in file and write each to its own line.
    while (read_instruction(infile, &opcode, &operand)) {
        write_instruction(outfile, opcode, operand);
        words +=2;
        if (words >= ppuOffset) {
            perror("More instructions than max, would leak into ppu space. specify --ppu-offset to define a new ppu offset if you need more program space.");
            goto error;
        }
    }
    for (size_t i = words; i < ppuOffset; i++) {
        fwrite(&zero, sizeof(uint16_t), 1, outfile);

    }
    printf("Wrote %lu words to output file from 0x2 to %hu, starting ppu section.", words, romOffset);

    if (ppufile == NULL) {
        for (size_t i = ppuOffset; i < 0x8000+ppuOffset; i++) {
            fwrite(&zero, sizeof(uint16_t), 1, outfile);
        } 
    } else {
        uint16_t *buffer = malloc(32768 * sizeof(uint16_t));
        size_t count = fread(buffer, sizeof(uint16_t), 32768, ppufile);
        fwrite(buffer, sizeof(uint16_t), count, outfile);
        free(buffer);
    }



    fclose(infile);
    fclose(outfile);

    return 0;
    error:
    fclose(infile);
    fclose(outfile);
    return 1;
}