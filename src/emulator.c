#include "lookup.h"
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#define FLAGS(cpu) ((cpu)->memory[0x000A])

#define A(cpu) ((cpu)->memory[0x0003])
#define B(cpu) ((cpu)->memory[0x0005])
#define C(cpu) ((cpu)->memory[0x0006])

#define I(cpu) ((cpu)->memory[0x0009])
#define IL(cpu) ((cpu)->memory[0x00010])

typedef struct {
    uint16_t memory[0xFFFF];
} CPU;

static inline uint8_t* X(CPU* cpu) {
    return (uint8_t*)&cpu->memory[0x0004];
}

static inline uint8_t* Y(CPU* cpu) {
    return (uint8_t*)&cpu->memory[0x0005];
}

int main(int argc, char *argv[]) {
    CPU cpu = {0};
    FILE *infile = fopen(argv[1], "rb");
    if (!infile) {
        printf("Error opening input file\n");
        return 1;
    }


    return 0;
}