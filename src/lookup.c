#include "lookup.h"
#include <string.h>

typedef struct {
    const char* Mnemonic;
    uint8_t     Opcode;
} Instruction;

static const Instruction Instructions[] = {
    // No Operation
    { "NOP", 0b000000 },
    // Reset
    { "RST", 0b000001 },
    // Load
    { "LDA", 0b000010 },
    { "LDB", 0b000011 },
    { "LDC", 0b000100 },
    { "LDX", 0b000101 },
    { "LDY", 0b000110 },
    // Store
    { "STA", 0b000111 },
    { "STB", 0b001000 },
    { "STC", 0b001001 },
    { "STX", 0b001010 },
    { "STY", 0b001011 },
    { "STZ", 0b001100 },
    // Addition
    { "ADA", 0b001101 },
    { "ADB", 0b001110 },
    { "ADC", 0b001111 },
    { "ADX", 0b010000 },
    { "ADY", 0b010001 },
    // Subtraction
    { "SBA", 0b010010 },
    { "SBB", 0b010011 },
    { "SBC", 0b010100 },
    { "SBX", 0b010101 },
    { "SBY", 0b010110 },
    // Integer Division
    { "DVA", 0b010111 },
    { "DVB", 0b011000 },
    { "DVC", 0b011001 },
    { "DVX", 0b011010 },
    { "DVY", 0b011011 },
    // Modulus
    { "MDA", 0b011100 },
    { "MDB", 0b011101 },
    { "MDC", 0b011110 },
    { "MDX", 0b011111 },
    { "MDY", 0b100000 },
    // Multiplication
    { "MXA", 0b100001 },
    { "MXB", 0b100010 },
    { "MXC", 0b100011 },
    { "MXX", 0b100100 },
    { "MXY", 0b100101 },
    // Iteration
    { "CLI", 0b100110 },
    { "ITR", 0b100111 },
    // Branching
    { "BIZ", 0b101000 },
    { "BIO", 0b101001 },
    { "JMP", 0b101010 },
    // Audio
    { "ADN", 0b101011 },
    { "ADW", 0b101100 },
    // Extras
    { "LAC", 0b101101 },
};

static const int InstructionCount = sizeof(Instructions) / sizeof(Instructions[0]);

uint8_t LookupOpcode(const char* Mnemonic) {
    for (int i = 0; i < InstructionCount; i++)
        if (strcmp(Instructions[i].Mnemonic, Mnemonic) == 0)
            return Instructions[i].Opcode;
    return Instructions[0].Opcode;
}

const char* LookupMnemonic(uint8_t Opcode) {
    for (int i = 0; i < InstructionCount; i++)
        if (Instructions[i].Opcode == Opcode)
            return Instructions[i].Mnemonic;
    return "NOP";
}