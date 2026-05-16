#include "lookup.h"
#include <string.h>



typedef struct {
    const char* Mnemonic;
    uint8_t     Opcode;
} Instruction;

typedef struct {
    const char  Mnemonic[1];
    uint8_t     ProgramMemoryOffset;
} Register;

static const Register Registers[] = {
    {{'A'}, 0x00 },
    {{'B'}, 0x01 },
    {{'C'}, 0x02 },
    {{'X'}, 0x03 },
    {{'Y'}, 0x04 },
    {{'Y'}, 0x05 },
};

static const Instruction Instructions[] = {
    //last two bits signify type of operand, 00 = hex, 01 = register, 10 and 11 are unused
    // No Operation
    { "NOP", 0b00000000 },
    // Reset
    { "RST", 0b00000100 },
    // Load
    { "LDA", 0b00001000 },
    { "LDB", 0b00001100 },
    { "LDC", 0b00010000 },
    { "LDX", 0b00010100 },
    { "LDY", 0b00011000 },
    // Store
    { "STA", 0b00011100 },
    { "STB", 0b00100000 },
    { "STC", 0b00100100 },
    { "STX", 0b00101000 },
    { "STY", 0b00101100 },
    { "STZ", 0b00110000 },
    // Addition
    { "ADA", 0b00110100 },
    { "ADB", 0b00111000 },
    { "ADC", 0b00111100 },
    { "ADX", 0b01000000 },
    { "ADY", 0b01000100 },
    // Subtraction
    { "SBA", 0b01001000 },
    { "SBB", 0b01001100 },
    { "SBC", 0b01010000 },
    { "SBX", 0b01010100 },
    { "SBY", 0b01011000 },
    // Integer Division
    { "DVA", 0b01011100 },
    { "DVB", 0b01100000 },
    { "DVC", 0b01100100 },
    { "DVX", 0b01101000 },
    { "DVY", 0b01101100 },
    // Modulus
    { "MDA", 0b01110000 },
    { "MDB", 0b01110100 },
    { "MDC", 0b01111000 },
    { "MDX", 0b01111100 },
    { "MDY", 0b10000000 },
    // Multiplication
    { "MXA", 0b10000100 },
    { "MXB", 0b10001000 },
    { "MXC", 0b10001100 },
    { "MXX", 0b10010000 },
    { "MXY", 0b10010100 },
    // Iteration
    { "CLI", 0b10011000 },
    { "ITR", 0b10011100 },
    // Branching
    { "BIZ", 0b10100000 },
    { "BIO", 0b10100100 },
    { "JMP", 0b10101000 },
    // Audio
    { "ADN", 0b10101100 },
    { "ADW", 0b10110000 },
    // Extras
    { "LAC", 0b10110100 },
};

static const int InstructionCount = sizeof(Instructions) / sizeof(Instructions[0]);
static const int RegisterCount = sizeof(Registers) / sizeof(Registers[0]);

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
uint16_t LookUpMemoryOffset(const char Mnemonic[1]) {
    for (int i = 0; i < RegisterCount; i++)
        if (strcmp(Registers[i].Mnemonic, Mnemonic) == 0)
            return Registers[i].ProgramMemoryOffset;
    return Registers[0].ProgramMemoryOffset;
}